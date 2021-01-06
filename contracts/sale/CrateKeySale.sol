// SPDX-License-Identifier: MIT

pragma solidity 0.6.8;

import "@animoca/ethereum-contracts-sale_base/contracts/sale/FixedPricesSale.sol";
import "../token/ERC20/F1DTCrateKey.sol";
import "./PrePaid.sol";

/**
 * @title CrateKeySale
 * A FixedPricesSale contract implementation that handles the purchase of ERC20 F1DTCrateKey tokens.
 */
contract CrateKeySale is FixedPricesSale {

    /* sku => crate key */
    mapping (bytes32 => IF1DTCrateKey) public crateKeys;

    PrePaid public prepaid;

    /**
     * Constructor.
     * @dev Reverts if the `prepaid_` is the zero address.
     * @dev Emits the `MagicValues` event.
     * @dev Emits the `Paused` event.
     * @dev Emits the `PayoutWalletSet` event.
     * @param prepaid_ The address of the PrePaid contract from which purchase payments will be taken from.
     */
    constructor (
        PrePaid prepaid_
    )
        public
        FixedPricesSale(
            _msgSender(),   // payout wallet (unused)
            4,  // SKUs capacity (each type of crate key only)
            1   // tokens per-SKU capacity (PrePaid escrow token only)
        )
    {
        require(
            prepaid_ != PrePaid(0),
            "CrateKeySale: zero address");

        prepaid = prepaid_;
    }

    /**
     * Actvates, or 'starts', the contract.
     * @dev Starts the PrePaid contract sale period if is hasn't already been started.
     * @dev Reverts if the PrePaid contract is paused.
     * @dev Reverts if this sale contract is not whitelisted with the PrePaid contract.
     * @dev Reverts if called by any other than the contract owner.
     * @dev Reverts if the contract has already been started.
     * @dev Reverts if the PrePaid contract is not in the sale period after calling.
     * @dev Emits the `Started` event.
     * @dev Emits the `Unpaused` event.
     */
    function start() public override onlyOwner {
        require(
            !prepaid.paused(),
            "CrateKeySale: PrePaid contract paused");

        require(
            prepaid.isOperator(address(this)),
            "CrateKeySale: sale contract is not operator");

        super.start();

        if (prepaid.state() == prepaid.BEFORE_SALE_STATE()) {
            prepaid.setSaleStart();
        }

        require(
            prepaid.state() == prepaid.SALE_START_STATE(),
            "CrateKeySale: invalid PrePaid state");
    }

    /**
     * Creates an SKU.
     * @dev Deprecated. Please use `createCrateKeySku(bytes32, uint256, uint256, IF1DTCrateKey)` for creating
     *  inventory SKUs.
     * @dev Reverts if called.
     * @param *sku* the SKU identifier.
     * @param *totalSupply* the initial total supply.
     * @param *maxQuantityPerPurchase* The maximum allowed quantity for a single purchase.
     * @param *notificationsReceiver* The purchase notifications receiver contract address.
     *  If set to the zero address, the notification is not enabled.
     */
    function createSku(
        bytes32 /*sku*/,
        uint256 /*totalSupply*/,
        uint256 /*maxQuantityPerPurchase*/,
        address /*notificationsReceiver*/
    ) public override onlyOwner {
        revert("Deprecated. Please use `createCrateKeySku(bytes32, uint256, uint256, IF1DTCrateKey)`");
    }

    /**
     * Creates an SKU and associates the specified ERC20 F1DTCrateKey token contract with it.
     * @dev Reverts if called by any other than the contract owner.
     * @dev Reverts if `totalSupply` is zero.
     * @dev Reverts if `sku` already exists.
     * @dev Reverts if the update results in too many SKUs.
     * @dev Reverts if the `totalSupply` is SUPPLY_UNLIMITED.
     * @dev Reverts if the `crateKey` is the zero address.
     * @dev Reverts if the associated ERC20 F1DTCrateKey token contract holder has a token balance less than
     *  `totalSupply`.
     * @dev Reverts if the sale contract has an allowance from the ERC20 F1DTCrateKey token contract holder
     *  not-equal-to `totalSupply`.
     * @dev Emits the `SkuCreation` event.
     * @param sku The SKU identifier.
     * @param totalSupply The initial total supply.
     * @param maxQuantityPerPurchase The maximum allowed quantity for a single purchase.
     * @param crateKey The ERC20 F1DTCrateKey token contract to bind with the SKU.
     */
    function createCrateKeySku(
        bytes32 sku,
        uint256 totalSupply,
        uint256 maxQuantityPerPurchase,
        IF1DTCrateKey crateKey
    ) external onlyOwner {
        require(
            totalSupply != SUPPLY_UNLIMITED,
            "CrateKeySale: invalid total supply");
        
        require(
            crateKey != IF1DTCrateKey(0),
            "CrateKeySale: zero address");

        super.createSku(
            sku,
            totalSupply,
            maxQuantityPerPurchase,
            address(0));    // notifications receiver

        address crateKeyHolder = crateKey.holder();

        // holder balance should be equal to or more than the SKU sale total supply since it could also include the
        // supply reserved for operations purposes
        require(
            crateKey.balanceOf(crateKeyHolder) >= totalSupply,
            "CrateKeySale: insufficient balance");

        // allowance should match the SKU sale total supply to restrict what portion of the holder supply balance is
        // reserved for the crate key sale
        require(
            crateKey.allowance(crateKeyHolder, address(this)) >= totalSupply,
            "CrateKeySale: invalid allowance");
        
        crateKeys[sku] = crateKey;
    }

    /**
     * Lifecycle step which manages the transfer of funds from the purchaser.
     * @dev Responsibilities:
     *  - Ensure the payment reaches destination in the expected output token;
     *  - Handle any token swap logic;
     *  - Add any relevant extra data related to payment in `purchase.paymentData` and document how to interpret it.
     * @dev Consumes purchase funds from the PrePaid contract for the purchaser.
     * @dev Reverts if the purchaser has no prepaid amount deposited.
     * @dev Reverts if the purchaser has an insufficient prepaid deposit amount to cover the entire purchase.
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
     * @dev Reverts if the holder has an insufficient ERC20 F1DTCrateKey token balance for the transfer.
     * @dev Reverts if the sale contract has an insufficient ERC20 F1DTCrateKey allowance for the transfer.
     * @param purchase The purchase conditions.
     */
    function _delivery(
        PurchaseData memory purchase
    ) internal override {
        super._delivery(purchase);

        IF1DTCrateKey crateKey = crateKeys[purchase.sku];

        crateKey.transferFrom(
            crateKey.holder(),
            purchase.recipient,
            purchase.quantity);
    }

}

/**
 * @dev Interface of the ERC20 F1DTCrateKey token contract.
 */
interface IF1DTCrateKey {

    /**
     * Returns the amount of tokens owned by `account`.
     * @param account The account whose token balance will be retrieved.
     * @return The amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * Returns the remaining number of tokens that `spender` will be allowed to spend on behalf of `owner` through
     *  {transferFrom}.
     * @dev This value is zero by default.
     * @dev This value changes when {approve} or {transferFrom} are called.
     * @param owner The account who has granted a spending allowance to the spender.
     * @param spender The account who has been granted a spending allowance by the owner.
     * @return The remaining number of tokens that `spender` will be allowed to spend on behalf of `owner` through
     *  {transferFrom}.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * Moves `amount` tokens from `sender` to `recipient` using the allowance mechanism. 
     * @dev `amount` is deducted from the caller's allowance.
     * @dev Emits a {Transfer} event.
     * @param sender The account where the tokens will be transferred from.
     * @param recipient The account where the tokens will be transferred to.
     * @param amount The amount of tokens being transferred.
     * @return Boolean indicating whether the operation succeeded.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * Returns the account holding the initial token supply.
     * @return The account holding the initial token supply.
     */
    function holder() external view returns (address);
}

