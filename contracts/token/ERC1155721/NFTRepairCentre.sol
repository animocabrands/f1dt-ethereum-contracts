// SPDX-License-Identifier: MIT

pragma solidity ^0.6.8;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@animoca/ethereum-contracts-assets_inventory/contracts/token/ERC1155/ERC1155TokenReceiver.sol";

/**
 * @title NFTRepairCentre
 * This contract is used to manage F1 Delta Time defunct tokens. Defunct tokens are NFTs which were created with an incorrect id.
 * As the core metadata attributes are encoded in the token id, tokens with an incorrect id may not be usable some in ecosystem contracts.
 *
 * This contract has two missions:
 * - Publish a public list of defunct tokens (through `repairList`) that ecosystem contracts relying on core metadata attributes can consult as a blacklist,
 * - Let the owners of the defunct tokens swap them for replacement tokens. Defunct tokens are sent to the `tokensGraveyard` when replaced.
 *
 * The owners of defunct tokens who want to use them in these ecosystem contracts will have to repair them first,
 * but will be compensated for their trouble with `revvCompensation` REVVs for each repaired token.
 */
contract NFTRepairCentre is Ownable, ERC1155TokenReceiver {
    using SafeMath for uint256;

    event TokensToRepairAdded(uint256[] brokenIds, uint256[] fixedIds);
    event RepairedSingle(uint256 defunctToken, uint256 replacementToken);
    event RepairedBatch(uint256[] defunctTokens, uint256[] replacementTokens);

    IDeltaTimeInventory inventoryContract;
    address tokensGraveyard;
    IREVV revvContract;
    uint256 revvCompensation;

    mapping(uint256 => uint256) repairList;

    /**
     * Constructor.
     * @dev Reverts if one of the argument addresses is zero.
     * @param inventoryContract_ the address of the DeltaTimeInventoryContract.
     * @param tokensGraveyard_ the address of the tokens graveyard.
     * @param revvContract_ the address of the REVV contract.
     * @param revvCompensation_ the amount of REVV to compensate for each token replacement.
     */
    constructor(
        address inventoryContract_,
        address tokensGraveyard_,
        address revvContract_,
        uint256 revvCompensation_
    ) public {
        require(
            inventoryContract_ != address(0) && tokensGraveyard_ != address(0) && revvContract_ != address(0),
            "RepairCentre: zero address"
        );
        inventoryContract = IDeltaTimeInventory(inventoryContract_);
        tokensGraveyard = tokensGraveyard_;
        revvContract = IREVV(revvContract_);
        revvCompensation = revvCompensation_;
    }

    /*                                             Public Admin Functions                                             */

    /**
     * @notice Adds tokens to the repair list and transfers the necessary amount of REVV for the compensations to the contract.
     * @dev Reverts if not called by the owner.
     * @dev Reverts if `defunctTokens` and `replacementTokens` have inconsistent lengths.
     * @dev Reverts if the REVV transfer fails.
     * @dev Emits a TokensToRepairAdded event.
     * @param defunctTokens the list of defunct tokens.
     * @param replacementTokens the list of replacement tokens.
     */
    function addTokensToRepair(uint256[] calldata defunctTokens, uint256[] calldata replacementTokens)
        external
        onlyOwner
    {
        uint256 length = defunctTokens.length;
        require(length != 0 && length == replacementTokens.length, "RepairCentre: wrong lengths");
        for (uint256 i = 0; i < length; ++i) {
            repairList[defunctTokens[i]] = replacementTokens[i];
        }
        revvContract.transferFrom(msg.sender, address(this), revvCompensation.mul(length));
        emit TokensToRepairAdded(defunctTokens, replacementTokens);
    }

    /*                                             ERC1155TokenReceiver                                             */

    /**
     * @notice ERC1155 single transfer receiver which repairs a single token and removes it from the repair list.
     * @dev Reverts if the transfer was not operated through `inventoryContract`.
     * @dev Reverts if `id` is not in the repair list.
     * @dev Reverts if the defunct token transfer to the graveyard fails.
     * @dev Reverts if the replacement token minting to the owner fails.
     * @dev Reverts if the REVV compensation transfer fails.
     * @dev Emits an ERC1155 TransferSingle event for the defunct token transfer to the graveyard.
     * @dev Emits an ERC1155 TransferSingle event for the replacement token minting to the owner.
     * @dev Emits an ERC20 Transfer event for the REVV compensation transfer.
     * @dev Emits a RepairedSingle event.
     * @param /operator the address which initiated the transfer (i.e. msg.sender).
     * @param from the address which previously owned the token.
     * @param defunctToken the id of the token to repair.
     * @param /value the amount of tokens being transferred.
     * @param /data additional data with no specified format.
     * @return bytes4 `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     */
    function onERC1155Received(
        address, /*operator*/
        address from,
        uint256 defunctToken,
        uint256, /*value*/
        bytes calldata /*data*/
    ) external virtual override returns (bytes4) {
        require(msg.sender == address(inventoryContract), "RepairCentre: wrong inventory");

        uint256 replacementToken = repairList[defunctToken];
        require(replacementToken != 0, "RepairCentre: token not defunct");
        delete repairList[defunctToken];

        inventoryContract.safeTransferFrom(from, tokensGraveyard, defunctToken, 1, bytes(""));

        try inventoryContract.mintNonFungible(from, replacementToken, bytes32(""), true)  {} catch {
            inventoryContract.mintNonFungible(from, replacementToken, bytes32(""), false);
        }
        revvContract.transfer(from, revvCompensation);

        emit RepairedSingle(defunctToken, replacementToken);

        return _ERC1155_RECEIVED;
    }

    /**
     * @notice ERC1155 batch transfer receiver which repairs a batch of tokens and removes them from the repair list.
     * @dev Reverts if `ids` is an empty array.
     * @dev Reverts if the transfer was not operated through `inventoryContract`.
     * @dev Reverts if `ids` contains an id not in the repair list.
     * @dev Reverts if the defunct tokens transfer to the graveyard fails.
     * @dev Reverts if the replacement tokens minting to the owner fails.
     * @dev Reverts if the REVV compensation transfer fails.
     * @dev Emits an ERC1155 TransferBatch event for the defunct tokens transfer to the graveyard.
     * @dev Emits an ERC1155 TransferBatch event for the replacement tokens minting to the owner.
     * @dev Emits an ERC20 Transfer event for the REVV compensation transfer.
     * @dev Emits a RepairedBatch event.
     * @param /operator the address which initiated the batch transfer (i.e. msg.sender).
     * @param from the address which previously owned the token.
     * @param defunctTokens an array containing the ids of the defunct tokens to repair.
     * @param values an array containing amounts of each token being transferred (order and length must match _ids array).
     * @param /data additional data with no specified format.
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     */
    function onERC1155BatchReceived(
        address, /*operator*/
        address from,
        uint256[] calldata defunctTokens,
        uint256[] calldata values,
        bytes calldata /*data*/
    ) external virtual override returns (bytes4) {
        require(msg.sender == address(inventoryContract), "RepairCentre: wrong inventory");

        uint256 length = defunctTokens.length;
        require(length != 0, "RepairCentre: empty array");

        address[] memory recipients = new address[](length);
        uint256[] memory replacementTokens = new uint256[](length);
        bytes32[] memory uris = new bytes32[](length);
        for (uint256 i = 0; i < length; ++i) {
            uint256 defunctToken = defunctTokens[i];
            uint256 replacementToken = repairList[defunctToken];
            require(replacementToken != 0, "RepairCentre: token not defunct");
            delete repairList[defunctToken];
            recipients[i] = from;
            replacementTokens[i] = replacementToken;
        }

        inventoryContract.safeBatchTransferFrom(from, tokensGraveyard, defunctTokens, values, bytes(""));

        try inventoryContract.batchMint(recipients, replacementTokens, uris, values, true)  {} catch {
            inventoryContract.batchMint(recipients, replacementTokens, uris, values, false);
        }

        revvContract.transfer(from, revvCompensation.mul(length));

        emit RepairedBatch(defunctTokens, replacementTokens);

        return _ERC1155_BATCH_RECEIVED;
    }

    /*                                             Other Public Functions                                             */

    /**
     * @notice Verifies whether a list of tokens contains a defunct token.
     * This function can be used by contracts having logic based on NFTs core attributes, in which case the repair list is a blacklist.
     * @param tokens an array containing the token ids to verify.
     * @return true if the array contains a defunct token, false otherwise.
     */
    function hasDefunctToken(uint256[] calldata tokens) external view returns(bool) {
        for (uint256 i = 0; i < tokens.length; ++i) {
            if (repairList[tokens[i]] != 0) {
                return true;
            }
        } 
        return false;
    }
}

interface IDeltaTimeInventory {
    /**
     * @notice Transfers `value` amount of an `id` from  `from` to `to`  (with safety call).
     * @dev Caller must be approved to manage the tokens being transferred out of the `from` account (see "Approval" section of the standard).
     * MUST revert if `to` is the zero address.
     * MUST revert if balance of holder for token `id` is lower than the `value` sent.
     * MUST revert on any other error.
     * MUST emit the `TransferSingle` event to reflect the balance change (see "Safe Transfer Rules" section of the standard).
     * After the above conditions are met, this function MUST check if `to` is a smart contract (e.g. code size > 0). If so, it MUST call `onERC1155Received` on `to` and act appropriately (see "Safe Transfer Rules" section of the standard).
     * @param from    Source address
     * @param to      Target address
     * @param id      ID of the token type
     * @param value   Transfer amount
     * @param data    Additional data with no specified format, MUST be sent unaltered in call to `onERC1155Received` on `to`
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external;

    /**
     * @notice Transfers `values` amount(s) of `ids` from the `from` address to the `to` address specified (with safety call).
     * @dev Caller must be approved to manage the tokens being transferred out of the `from` account (see "Approval" section of the standard).
     * MUST revert if `to` is the zero address.
     * MUST revert if length of `ids` is not the same as length of `values`.
     * MUST revert if any of the balance(s) of the holder(s) for token(s) in `ids` is lower than the respective amount(s) in `values` sent to the recipient.
     * MUST revert on any other error.
     * MUST emit `TransferSingle` or `TransferBatch` event(s) such that all the balance changes are reflected (see "Safe Transfer Rules" section of the standard).
     * Balance changes and events MUST follow the ordering of the arrays (_ids[0]/_values[0] before _ids[1]/_values[1], etc).
     * After the above conditions for the transfer(s) in the batch are met, this function MUST check if `to` is a smart contract (e.g. code size > 0). If so, it MUST call the relevant `ERC1155TokenReceiver` hook(s) on `to` and act appropriately (see "Safe Transfer Rules" section of the standard).
     * @param from    Source address
     * @param to      Target address
     * @param ids     IDs of each token type (order and length must match _values array)
     * @param values  Transfer amounts per token type (order and length must match _ids array)
     * @param data    Additional data with no specified format, MUST be sent unaltered in call to the `ERC1155TokenReceiver` hook(s) on `to`
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external;

    /**
     * @dev Public function to mint a batch of new tokens
     * Reverts if some the given token IDs already exist
     * @param to address[] List of addresses that will own the minted tokens
     * @param ids uint256[] List of ids of the tokens to be minted
     * @param uris bytes32[] Concatenated metadata URIs of nfts to be minted
     * @param values uint256[] List of quantities of ft to be minted
     */
    function batchMint(
        address[] calldata to,
        uint256[] calldata ids,
        bytes32[] calldata uris,
        uint256[] calldata values,
        bool safe
    ) external;

    /**
     * @dev Public function to mint one non fungible token id
     * Reverts if the given token ID is not non fungible token id
     * @param to address recipient that will own the minted tokens
     * @param tokenId uint256 ID of the token to be minted
     * @param byteUri bytes32 Concatenated metadata URI of nft to be minted
     */
    function mintNonFungible(
        address to,
        uint256 tokenId,
        bytes32 byteUri,
        bool safe
    ) external;
}

interface IREVV {
    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}
