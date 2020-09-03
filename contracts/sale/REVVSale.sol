// SPDX-License-Identifier: MIT

pragma solidity =0.6.8;

import "@animoca/ethereum-contracts-assets_inventory/contracts/token/ERC721/IERC721.sol";
import "@animoca/ethereum-contracts-erc20_base/contracts/token/ERC20/IERC20.sol";
import "@animoca/ethereum-contracts-sale_base/contracts/sale/FixedPricesSale.sol";

/**
 * @title REVVSale
 * A sale contract for the initial REVV distribution to F1 NFT owners.
 */
contract REVVSale is FixedPricesSale {
    IERC20 internal immutable _revv;
    IERC721 internal immutable _deltaTimeInventory;

    /**
     * Constructor.
     * @param payoutWallet_ The wallet address used to receive purchase payments.
     */
    constructor(
        address revv,
        address deltaTimeInventory,
        address payable payoutWallet_,
        address inventoryContract
    ) public FixedPricesSale(payoutWallet_, 64, 32) {
        require(revv != address(0), "REVVSale: zero address REVV ");
        require(inventoryContract != address(0), "REVVSale: zero address inventory ");
        _revv = IERC20(revv);
        _deltaTimeInventory = IERC721(deltaTimeInventory);
    }

    /**
     * Creates a REVV sku and funds the necessary amount to this contract.
     * @dev Reverts if called by any other than the contract owner.
     * @dev Reverts if `totalSupply` is zero.
     * @dev Reverts if `sku` already exists.
     * @dev Reverts if `notificationsReceiver` is not the zero address and is not a contract address.
     * @dev Reverts if the update results in too many SKUs.
     * @dev Reverts if the REVV funding fails.
     * @dev Emits the `SkuCreation` event.
     * @param sku the SKU identifier.
     * @param totalSupply the initial total supply.
     * @param maxQuantityPerPurchase The maximum allowed quantity for a single purchase.
     * @param notificationsReceiver The purchase notifications receiver contract address.
     *  If set to the zero address, the notification is not enabled.
     */
    function createSku(
        bytes32 sku,
        uint256 totalSupply,
        uint256 maxQuantityPerPurchase,
        address notificationsReceiver
    ) public virtual override {
        super.createSku(sku, totalSupply, maxQuantityPerPurchase, notificationsReceiver);
        require(_revv.transferFrom(_msgSender(), address(this), totalSupply), "REVVSale: REVV transfer failed");
    }

    /**
     * Lifecycle step which validates the purchase pre-conditions.
     * @dev Responsibilities:
     *  - Ensure that the purchase pre-conditions are met and revert if not.
     * @param purchase The purchase conditions.
     */
    function _validation(PurchaseData memory purchase) internal override view {
        super._validation(purchase);
        require(_deltaTimeInventory.balanceOf(_msgSender()) != 0, "REVVSale: must be a NFT owner");
    }

    function _delivery(PurchaseData memory purchase) internal override {
        require(
            _revv.transferFrom(address(this), purchase.recipient, purchase.quantity),
            "REVVSale:  REVV transfer failed"
        );
    }
}
