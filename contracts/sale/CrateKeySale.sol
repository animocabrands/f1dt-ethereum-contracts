// SPDX-License-Identifier: MIT

pragma solidity 0.6.8;

import "@animoca/ethereum-contracts-sale_base/contracts/sale/FixedPricesSale.sol";
import "../token/ERC20/F1DTCrateKey.sol";
import "../game/PrePaid.sol";

/**
 * @title CrateKeySale
 * A FixedPricesSale contract implementation that handles the purchase of ERC20 F1DTCrateKey tokens.
 *
 * PurchaseData.pricingData:
 *  - [0] uint256: discount percentage
 */
contract CrateKeySale is FixedPricesSale {

    /* sku => crate key */
    mapping (bytes32 => F1DTCrateKey) public crateKeys;

    PrePaid public prepaid;

    /**
     * Constructor.
     * @dev Emits the `MagicValues` event.
     * @dev Emits the `Paused` event.
     * @param skusCapacity The cap for the number of managed SKUs.
     * @param prepaid_ The address of the PrePaid contract from which purchase payments will be taken from.
     */
    constructor (
        uint256 skusCapacity,
        PrePaid prepaid_
    )
        public
        FixedPricesSale(
            address(0),
            skusCapacity,
            1
        )
    {
        require(
            prepaid_ != PrePaid(0),
            "CrateKeySale: zero address");

        prepaid = prepaid_;
    }

    /**
     * Creates an SKU.
     * @dev Deprecated. Please use `createSku(bytes32, uint256, uint256, address, string, string)` for creating
     *  inventory SKUs.
     * @dev Reverts if called.
     * @param *sku* the SKU identifier.
     * @param *totalSupply* the initial total supply.
     * @param *maxQuantityPerPurchase* The maximum allowed quantity for a single purchase.
     * @param *notificationsReceiver* The purchase notifications receiver contract address. If set to the zero address,
     *  the notification is not enabled.
     */
    function createSku(
        bytes32 /*sku*/,
        uint256 /*totalSupply*/,
        uint256 /*maxQuantityPerPurchase*/,
        address /*notificationsReceiver*/
    ) public override onlyOwner {
        revert("Deprecated. Please use `createSku(bytes32, uint256, uint256, address, string, string)`");
    }

    /**
     * Creates an SKU.
     * @dev Creates and deploys an ERC20 F1DTCrateKey token contract.
     * @dev Created ERC20 F1DTCrateKey token contracts will have their ownership transferred to the current owner of
     *  this sale contract.
     * @dev The created ERC20 F1DTCrateKey token contract sets this contract as a whitelisted operator.
     * @dev Reverts if called by any other than the contract owner.
     * @dev Reverts if `totalSupply` is zero.
     * @dev Reverts if `sku` already exists.
     * @dev Reverts if `notificationsReceiver` is not the zero address and is not a contract address.
     * @dev Reverts if the update results in too many SKUs.
     * @dev Emits the `SkuCreation` event.
     * @param sku the SKU identifier.
     * @param totalSupply the initial total supply.
     * @param maxQuantityPerPurchase The maximum allowed quantity for a single purchase.
     * @param notificationsReceiver The purchase notifications receiver contract address. If set to the zero address,
     *  the notification is not enabled.
     * @param crateKeySymbol The symbol of the ERC20 F1DTCrateKey token contract.
     * @param crateKeyName The name of the ERC20 F1DTCrateKey token contract.
     */
    function createSku(
        bytes32 sku,
        uint256 totalSupply,
        uint256 maxQuantityPerPurchase,
        address notificationsReceiver,
        string calldata crateKeySymbol,
        string calldata crateKeyName
    ) external onlyOwner {
        super.createSku(
            sku,
            totalSupply,
            maxQuantityPerPurchase,
            notificationsReceiver);

        F1DTCrateKey crateKey = new F1DTCrateKey(
            crateKeySymbol,
            crateKeyName,
            address(this),
            totalSupply);
        crateKey.transferOwnership(owner());

        crateKeys[sku] = crateKey;
    }

    /**
     * Sets the token prices for the specified product SKU.
     * @dev Deprecated. Please use `updateSkuPricing(bytes32, uint256)` for setting the price of an inventory SKU.
     * @dev Reverts if called.
     * @param *sku* The identifier of the SKU.
     * @param *tokens* The list of payment tokens to update.
     * @param *prices* The list of prices to apply for each payment token.
     */
    function updateSkuPricing(
        bytes32 /*sku*/,
        address[] memory /*tokens*/,
        uint256[] memory /*prices*/
    ) public override onlyOwner {
        revert("Deprecated. Please use `updateSkuPricing(bytes32, uint256)`");
    }

    /**
     * Sets the token price for the specified product SKU.
     * @dev Updates the SKU pricing for the escrow token of the PrePaid contract.
     * @dev Reverts if called by any other than the contract owner.
     * @dev Reverts if `sku` does not exist.
     * @dev Emits the `SkuPricingUpdate` event.
     * @param sku The identifier of the SKU.
     * @param price The price to apply to the SKU's payment token.
     */
    function updateSkuPricing(
        bytes32 sku,
        uint256 price
    ) public onlyOwner {
        address[] memory tokens = new address[](1);
        tokens[0] = address(prepaid.revv());

        uint256[] memory prices = new uint256[](1);
        prices[0] = price;

        super.updateSkuPricing(sku, tokens, prices);
    }

    /**
     * Lifecycle step which computes the purchase price.
     * @dev Responsibilities:
     *  - Computes the pricing formula, including any discount logic and price conversion;
     *  - Set the value of `purchase.totalPrice`;
     *  - Add any relevant extra data related to pricing in `purchase.pricingData` and document how to interpret it.
     * @dev Applies discount pricing to the total price from the PrePaid contract.
     * @dev Reverts if `purchase.sku` does not exist.
     * @dev Reverts if `purchase.token` is not supported by the SKU.
     * @dev Reverts in case of price overflow.
     * @dev purchase.pricingData[0] contains the discount percent applied to the total price.
     * @param purchase The purchase conditions.
     */
    function _pricing(
        PurchaseData memory purchase
    ) internal override view {
        super._pricing(purchase);

        uint256 discountPercent = prepaid.getDiscount();

        if (discountPercent != 0) {
            uint256 discountAmount = purchase.totalPrice.mul(discountPercent).div(100);
            purchase.totalPrice = purchase.totalPrice.sub(discountAmount);
        }

        purchase.pricingData = new bytes32[](1);
        purchase.pricingData[0] = bytes32(discountPercent);
    }

    /**
     * Lifecycle step which manages the transfer of funds from the purchaser.
     * @dev Responsibilities:
     *  - Ensure the payment reaches destination in the expected output token;
     *  - Handle any token swap logic;
     *  - Add any relevant extra data related to payment in `purchase.paymentData` and document how to interpret it.
     * @dev Consumes purchase funds from the PrePaid contract for the purchaser.
     * @dev Reverts in case of payment failure.
     * @param purchase The purchase conditions.
     */
    function _payment(
        PurchaseData memory purchase
    ) internal override {
        prepaid.consume(
            purchase.purchaser,
            purchase.totalPrice);
    }

    /**
     * Lifecycle step which delivers the purchased SKUs to the recipient.
     * @dev Responsibilities:
     *  - Ensure the product is delivered to the recipient, if that is the contract's responsibility.
     *  - Handle any internal logic related to the delivery, including the remaining supply update;
     *  - Add any relevant extra data related to delivery in `purchase.deliveryData` and document how to interpret it.
     * @dev Transfers tokens from the ERC20 F1DTCrateKey token contract associated with the SKU being purchased, of the
     *  specified purchase quantity.
     * @param purchase The purchase conditions.
     */
    function _delivery(
        PurchaseData memory purchase
    ) internal override {
        super._delivery(purchase);

        F1DTCrateKey crateKey = crateKeys[purchase.sku];

        crateKey.transfer(
            purchase.recipient,
            purchase.quantity);
    }

}
