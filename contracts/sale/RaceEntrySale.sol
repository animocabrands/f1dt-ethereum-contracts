// SPDX-License-Identifier: MIT

pragma solidity = 0.6.8;

import "@animoca/ethereum-contracts-sale_base/contracts/sale/SimpleSale.sol";

/**
 * @title RaceEntrySale
 */
contract RaceEntrySale is SimpleSale {

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
        SimpleSale(
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
            "RaceEntrySale: Quantity must be 1");
    }

    /**
     * Retrieves implementation-specific extra data passed as the Purchased
     *  event extData argument.
     * @param purchase Purchase conditions.
     * @param priceInfo Implementation-specific calculated purchase price
     *  information.
     * @param *paymentInfo* Implementation-specific accepted purchase payment
     *  information.
     * @param *deliveryInfo* Implementation-specific purchase delivery
     *  information.
     * @param *finalizeInfo* Implementation-specific purchase finalization
     *  information.
     * @return extData Implementation-specific extra data passed as the Purchased event
     *  extData argument (0:unit price, 1:game session ID).
     */
    function _getPurchasedEventExtData(
        Purchase memory purchase,
        bytes32[] memory priceInfo,
        bytes32[] memory /* paymentInfo */,
        bytes32[] memory /* deliveryInfo */,
        bytes32[] memory /* finalizeInfo */
    ) internal override view returns (bytes32[] memory extData) {
        extData = new bytes32[](2);
        extData[0] = priceInfo[1];
        extData[1] = purchase.extData[0];
    }

}
