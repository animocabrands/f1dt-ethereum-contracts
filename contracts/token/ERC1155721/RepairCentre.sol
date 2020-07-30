// SPDX-License-Identifier: MIT

pragma solidity ^0.6.8;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@animoca/ethereum-contracts-assets_inventory/contracts/token/ERC1155/ERC1155TokenReceiver.sol";

contract NFTRepairCentre is Ownable, ERC1155TokenReceiver {

    using SafeMath for uint256;

    event TokenRepaired (
        uint256 defunctToken,
        uint256 replacementToken
    );

    event TokensRepaired (
        uint256[] defunctTokens,
        uint256[] replacementTokens
    );

    event TokensToRepairAdded (
        uint256[] brokenIds,
        uint256[] fixedIds
    );

    struct TokenToRepair {
        uint256 defunctToken;
        uint256 replacementToken;
    }

    IDeltaTimeInventory inventoryContract;
    address tokensGraveyard;
    IREVV revvContract;
    uint256 revvCompensation;

    mapping(uint256 => uint256) repairList;

    constructor(address inventoryContract_, address tokensGraveyard_, address revvContract_, uint256 revvCompensation_) public {
        require(inventoryContract_ != address(0) && tokensGraveyard_ != address(0) && revvContract_ != address(0), "NFTRepairCentre: zero address");
        inventoryContract = IDeltaTimeInventory(inventoryContract_);
        tokensGraveyard = tokensGraveyard_;
        revvContract = IREVV(revvContract_);
        revvCompensation = revvCompensation_;
    }

    function addTokensToRepair(uint256[] calldata brokenIds, uint256[] calldata fixedIds) external onlyOwner {
        uint256 length = brokenIds.length;
        require(length != 0 && length == fixedIds.length, "NFTRepairCentre: wrong arguments");
        for (uint i = 0; i < length; ++i) {
            repairList[brokenIds[i]] = fixedIds[i];
        }
        revvContract.transferFrom(msg.sender, address(this), revvCompensation.mul(length));
        emit TokensToRepairAdded(brokenIds, fixedIds);
    }

    /*                                             ERC1155TokenReceiver                                             */

    function onERC1155Received(
        address, /*operator*/
        address from,
        uint256 id,
        uint256, /*value*/
        bytes calldata /*data*/
    ) external virtual override returns (bytes4) {
        _repairToken(id, from);
        return _ERC1155_RECEIVED;
    }

    function onERC1155BatchReceived(
        address, /*operator*/
        address from,
        uint256[] calldata ids,
        uint256[] calldata, /*values*/
        bytes calldata /*data*/
    ) external virtual override returns (bytes4) {
        _repairTokens(ids, from);
        return _ERC1155_BATCH_RECEIVED;
    }

    function _repairToken(uint256 defunctToken, address from) internal {
        uint256 replacementToken = repairList[defunctToken];
        require(replacementToken != 0, "NFTRepairCentre: wrong token");
        inventoryContract.safeTransferFrom(from, tokensGraveyard, defunctToken, 1, bytes(""));
        try inventoryContract.mintNonFungible(from, replacementToken, bytes32(""), true) {
        } catch {
            inventoryContract.mintNonFungible(from, replacementToken, bytes32(""), false);
        }
        revvContract.transfer(from, revvCompensation);
        emit TokenRepaired(defunctToken, replacementToken);
    }

    function _repairTokens(uint256[] memory defunctTokens, address from) internal {
        uint256 length = defunctTokens.length;
        require(length != 0, "NFTRepairCentre: wrong argument");
        address[] memory recipients = new address[](length);
        uint256[] memory replacementTokens = new uint256[](length);
        bytes32[] memory uris = new bytes32[](length);
        uint256[] memory values = new uint256[](length);
        for (uint256 i = 0; i < length; ++i) {
            uint256 replacementToken = repairList[defunctTokens[i]];
            require(replacementToken != 0, "NFTRepairCentre: wrong token");
            recipients[i] = from;
            replacementTokens[i] = replacementToken;
            values[i] = 1;
        }

        inventoryContract.safeBatchTransferFrom(from, tokensGraveyard, defunctTokens, values, bytes(""));
        try inventoryContract.batchMint(recipients, replacementTokens, uris, values, true) {
        } catch {
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
    function batchMint(address[] calldata to, uint256[] calldata ids, bytes32[] calldata uris, uint256[] calldata values, bool safe) external;

    /**
     * @dev Public function to mint one non fungible token id
     * Reverts if the given token ID is not non fungible token id
     * @param to address recipient that will own the minted tokens
     * @param tokenId uint256 ID of the token to be minted
     * @param byteUri bytes32 Concatenated metadata URI of nft to be minted
     */
    function mintNonFungible(address to, uint256 tokenId, bytes32 byteUri, bool safe) external;
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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}
