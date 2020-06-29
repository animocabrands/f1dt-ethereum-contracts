// SPDX-License-Identifier: MIT

pragma solidity = 0.6.8;

import "@animoca/ethereum-contracts-sale_base/contracts/sale/SimpleSale.sol";

/**
 * @title RaceEntrySale
 */
contract RaceEntrySale is SimpleSale {

    event Purchased(
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
        SimpleSale(
            payoutWallet_,
            payoutToken_
        )
        public
    {}

    /**
     * Performs a purchase based on the given purchase conditions.
     * @dev Emits the Purchased event when the function is called successfully.
     * @param purchaser The initiating account making the purchase.
     * @param sku The SKU of the item being purchased.
     * @param quantity The quantity of SKU items being purchased.
     * @param paymentToken The ERC20 token to use as the payment currency of the
     *  purchase.
     * @param gameSessionId The game session identifier used to associate this
     *  user's purchase with a specific race.
     */
    function purchaseFor(
        address payable purchaser,
        bytes32 sku,
        uint256 quantity,
        IERC20 paymentToken,
        bytes32 gameSessionId
    ) external payable {
        bytes32[] memory extData = new bytes32[](1);
        extData[0] = gameSessionId;

        _purchase(
            purchaser,
            sku,
            quantity,
            paymentToken,
            _msgSender(),
            msg.value,
            _msgData(),
            extData);
    }

    /**
     * Validates a purchase.
     * @param purchase Purchase conditions.
     */
    function _validatePurchase(
        Purchase memory purchase
    ) internal override virtual view {
        super._validatePurchase(purchase);

        require(
            purchase.quantity == 1,
            "RaceEntrySale: Quantity must be 1");
    }

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
    ) internal override virtual {
        emit Purchased(
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
