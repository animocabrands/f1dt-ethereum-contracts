// SPDX-License-Identifier: MIT

pragma solidity ^0.6.8;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@animoca/ethereum-contracts-assets_inventory/contracts/token/ERC1155/ERC1155TokenReceiver.sol";

contract NFTRepairCentre is Ownable, ERC1155TokenReceiver {
    using SafeMath for uint256;

    event TokensToRepairAdded(uint256[] brokenIds, uint256[] fixedIds);
    event TokenRepaired(uint256 defunctToken, uint256 replacementToken);
    event TokensRepaired(uint256[] defunctTokens, uint256[] replacementTokens);

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
            "NFTRepairCentre: zero address"
        );
        inventoryContract = IDeltaTimeInventory(inventoryContract_);
        tokensGraveyard = tokensGraveyard_;
        revvContract = IREVV(revvContract_);
        revvCompensation = revvCompensation_;
    }

    /**
     * Adds tokens to the repair list. The necessary amount of REVV for the compensations is transferred to the contract.
     * @dev Reverts if not called by the owner.
     * @dev Reverts if `defunctTokens` and `replacementTokens` have inconsistent lengths.
     * @dev Reverts ifthe REVV transfer fails.
     * @dev Emits the TokensToRepairAdded event.
     * @param defunctTokens the list of defunct tokens.
     * @param replacementTokens the list of replacement tokens.
     */
    function addTokensToRepair(uint256[] calldata defunctTokens, uint256[] calldata replacementTokens)
        external
        onlyOwner
    {
        uint256 length = defunctTokens.length;
        require(length != 0 && length == replacementTokens.length, "NFTRepairCentre: wrong arguments");
        for (uint256 i = 0; i < length; ++i) {
            repairList[defunctTokens[i]] = replacementTokens[i];
        }
        revvContract.transferFrom(msg.sender, address(this), revvCompensation.mul(length));
        emit TokensToRepairAdded(defunctTokens, replacementTokens);
    }

    /*                                             ERC1155TokenReceiver                                             */

    /**
     * @notice Handle the receipt of a single ERC1155 token type.
     * @dev An ERC1155-compliant smart contract MUST call this function on the token recipient contract, at the end of a `safeTransferFrom` after the balance has been updated.
     * This function MUST return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` (i.e. 0xf23a6e61) if it accepts the transfer.
     * This function MUST revert if it rejects the transfer.
     * Return of any other value than the prescribed keccak256 generated value MUST result in the transaction being reverted by the caller.
     * @param /operator  The address which initiated the transfer (i.e. msg.sender)
     * @param from      The address which previously owned the token
     * @param id        The ID of the token being transferred
     * @param value     The amount of tokens being transferred
     * @param /data      Additional data with no specified format
     * @return bytes4   `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     */
    function onERC1155Received(
        address, /*operator*/
        address from,
        uint256 id,
        uint256 value,
        bytes calldata /*data*/
    ) external virtual override returns (bytes4) {
        _repairToken(from, id, value);
        return _ERC1155_RECEIVED;
    }

    /**
     * @notice Handle the receipt of multiple ERC1155 token types.
     * @dev An ERC1155-compliant smart contract MUST call this function on the token recipient contract, at the end of a `safeBatchTransferFrom` after the balances have been updated.
     * This function MUST return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` (i.e. 0xbc197c81) if it accepts the transfer(s).
     * This function MUST revert if it rejects the transfer(s).
     * Return of any other value than the prescribed keccak256 generated value MUST result in the transaction being reverted by the caller.
     * @param /operator  The address which initiated the batch transfer (i.e. msg.sender)
     * @param from      The address which previously owned the token
     * @param ids       An array containing ids of each token being transferred (order and length must match _values array)
     * @param values    An array containing amounts of each token being transferred (order and length must match _ids array)
     * @param /data      Additional data with no specified format
     * @return          `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     */
    function onERC1155BatchReceived(
        address, /*operator*/
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata /*data*/
    ) external virtual override returns (bytes4) {
        _repairTokens(from, ids, values);
        return _ERC1155_BATCH_RECEIVED;
    }

    function _repairToken(
        address from,
        uint256 defunctToken,
        uint256 value
    ) internal {
        require(value == 1, "NFTRepairCentre: wrong value");
        uint256 replacementToken = repairList[defunctToken];
        require(replacementToken != 0, "NFTRepairCentre: wrong token");
        inventoryContract.safeTransferFrom(from, tokensGraveyard, defunctToken, 1, bytes(""));
        try inventoryContract.mintNonFungible(from, replacementToken, bytes32(""), true)  {} catch {
            inventoryContract.mintNonFungible(from, replacementToken, bytes32(""), false);
        }
        revvContract.transfer(from, revvCompensation);
        emit TokenRepaired(defunctToken, replacementToken);
    }

    function _repairTokens(
        address from,
        uint256[] memory defunctTokens,
        uint256[] memory values
    ) internal {
        uint256 length = defunctTokens.length;
        require(length != 0, "NFTRepairCentre: wrong argument");
        address[] memory recipients = new address[](length);
        uint256[] memory replacementTokens = new uint256[](length);
        bytes32[] memory uris = new bytes32[](length);
        for (uint256 i = 0; i < length; ++i) {
            require(values[i] == 1, "NFTRepairCentre: wrong value");
            uint256 replacementToken = repairList[defunctTokens[i]];
            require(replacementToken != 0, "NFTRepairCentre: wrong token");
            recipients[i] = from;
            replacementTokens[i] = replacementToken;
        }

        inventoryContract.safeBatchTransferFrom(from, tokensGraveyard, defunctTokens, values, bytes(""));
        try inventoryContract.batchMint(recipients, replacementTokens, uris, values, true)  {} catch {
            inventoryContract.batchMint(recipients, replacementTokens, uris, values, false);
        }
        revvContract.transfer(from, revvCompensation.mul(length));
        emit TokensRepaired(defunctTokens, replacementTokens);
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
