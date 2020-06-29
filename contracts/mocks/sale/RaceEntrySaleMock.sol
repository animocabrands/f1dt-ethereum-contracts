// SPDX-License-Identifier: MIT

pragma solidity = 0.6.8;

import "../../sale/RaceEntrySale.sol";

/**
 * @title RaceEntrySaleMock
 */
contract RaceEntrySaleMock is RaceEntrySale {

    event PurchasedMock(
        address indexed purchaser,
        address operator,
        bytes32 indexed sku,
        uint256 quantity,
        IERC20 paymentToken,
        uint256 totalPrice,
        uint256 unitPrice,
        bytes32 indexed gameSessionId
    );

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
        RaceEntrySale(
            payoutWallet_,
            payoutToken_
        )
        public
    {}

    /**
     * Triggers a notification(s) that the purchase has been complete.
     * @dev Emits the Purchased event when the function is called successfully.
     * @param purchase Purchase conditions.
     * @param priceInfo Implementation-specific calculated purchase price
     *  information.
     * @param *paymentInfo* Implementation-specific accepted purchase payment
     *  information.
     * @param *deliveryInfo* Implementation-specific purchase delivery
     *  information.
     * @param *finalizeInfo* Implementation-specific purchase finalization
     *  information.
     */
    function _notifyPurchased(
        Purchase memory purchase,
        bytes32[] memory priceInfo,
        bytes32[] memory /* paymentInfo */,
        bytes32[] memory /* deliveryInfo */,
        bytes32[] memory /* finalizeInfo */
    ) internal override {
        emit PurchasedMock(
            purchase.purchaser,
            purchase.msgSender,
            purchase.sku,
            purchase.quantity,
            purchase.paymentToken,
            uint256(priceInfo[0]),
            uint256(priceInfo[1]),
            purchase.extData[0]);
    }

}
