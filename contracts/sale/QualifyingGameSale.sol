// SPDX-License-Identifier: MIT

pragma solidity =0.6.8;

import "@animoca/ethereum-contracts-sale_base/contracts/sale/DirectSale.sol";

/**
 * @title QualifyingGameSale
 * A direct sale contract for the F1 DeltaTime qualifying game.
 */
contract QualifyingGameSale is DirectSale {

    /**
     * Constructor.
     * @param payoutWallet_ The wallet address used to receive purchase payments
     *  with.
     * @param payoutToken_ The ERC20 token currency accepted by the payout
     *  wallet for purchase payments.
     */
    constructor(
        address payable payoutWallet_,
        IERC20 payoutToken_
    )
        DirectSale(
            payoutWallet_,
            payoutToken_
        )
        public
    {}

    /**
     * Validates a purchase.
     * @param purchase Purchase conditions.
     */
    function _validatePurchase(
        Purchase memory purchase
    ) internal override view {
        super._validatePurchase(purchase);

        require(
            purchase.quantity == 1,
            "QualifyingGameSale: Quantity must be 1");
    }

    /**
     * Retrieves implementation-specific derived purchase data passed as the
     *  Purchased event purchaseData argument.
     * @param priceInfo Implementation-specific calculated purchase price
     *  information.
     * @param *paymentInfo* Implementation-specific accepted purchase payment
     *  information.
     * @param *deliveryInfo* Implementation-specific purchase delivery
     *  information.
     * @param *finalizeInfo* Implementation-specific purchase finalization
     *  information.
     * @return purchaseData Implementation-specific derived purchase data
     *  passed as the Purchased event purchaseData argument (0:total price).
     */
    function _getPurchasedEventPurchaseData(
        bytes32[] memory priceInfo,
        bytes32[] memory, /* paymentInfo */
        bytes32[] memory, /* deliveryInfo */
        bytes32[] memory /* finalizeInfo */
    )
        internal override view
        returns (bytes32[] memory purchaseData)
    {
        purchaseData = new bytes32[](1);
        purchaseData[0] = priceInfo[0];
    }

}
