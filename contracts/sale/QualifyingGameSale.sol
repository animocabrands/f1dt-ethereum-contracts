// SPDX-License-Identifier: MIT

pragma solidity =0.6.8;

import "@animoca/ethereum-contracts-sale_base/contracts/sale/FixedPricesSale.sol";

/**
 * @title QualifyingGameSale
 * A direct sale contract for the F1 DeltaTime qualifying game.
 */
contract QualifyingGameSale is FixedPricesSale {
    /**
     * Constructor.
     * @param payoutWallet_ The wallet address used to receive purchase payments.
     */
    constructor(address payable payoutWallet_) public FixedPricesSale(payoutWallet_, 64, 32) {}

    /**
     * Lifecycle step which validates the purchase pre-conditions.
     * @dev Responsibilities:
     *  - Ensure that the purchase pre-conditions are met and revert if not.
     * @param purchase The purchase conditions.
     */
    function _validation(PurchaseData memory purchase) internal override view {
        super._validation(purchase);
        require(purchase.quantity == 1, "QualifyingGameSale: Quantity must be 1");
    }
}
