// SPDX-License-Identifier: MIT

pragma solidity 0.6.8;

import "@openzeppelin/contracts/GSN/Context.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@animoca/ethereum-contracts-core_library/contracts/access/WhitelistedOperators.sol";

/// Minimal transfers-only ERC20 interface
interface IERC20Transfers {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

/**
 * @title PrePaid contract.
 * Contract which manages the deposits made by wallets for pre-sale. Participants are
 * allowed to make deposits before the sale starts, and withdrawals after the sale ends.
 */
contract PrePaid is Context, Pausable, WhitelistedOperators {
    using SafeMath for uint256;

    /**
     * Event emitted when the user deposits into their escrow balance.
     * @param wallet The wallet address of the user.
     * @param amount The amount added to the user's escrow balance.
     */
    event Deposited(
        address wallet,
        uint256 amount
    );

    /**
     * Event emitted when the user withdraws from their escrow balance.
     * @param wallet The wallet address of the user.
     * @param amount The amount deducted from user's escrow balance.
     */
    event Withdrawn(
        address wallet,
        uint256 amount
    );

    /**
     * Event emitted when the sale started state is set.
     * @param state The sale started state that was set.
     */
    event SaleStarted(
        bool state
    );

    /**
     * Event emitted when the sale ended state is set.
     * @param state The sale ended state that was set.
     */
    event SaleEnded(
        bool state
    );

    /**
     * Modifier to make a function callable only when the sale has not started.
     */
    modifier whenNotStarted() {
        require(saleStarted == false, "PrePaid: sale started");
        _;
    }

    /**
     * Modifier to make a function callable only when the sale has started.
     */
    modifier whenStarted() {
        require(saleStarted == true, "PrePaid: sale not started");
        _;
    }

    /**
     * Modifier to make a function callable only when the sale has not ended.
     */
    modifier whenNotEnded() {
        require(saleEnded == false, "PrePaid: sale ended");
        _;
    }

    /**
     * Modifier to make a function callable only when the sale has ended.
     */
    modifier whenEnded() {
        require(saleEnded == true, "PrePaid: sale not ended");
        _;
    }

    /**
     * Modifier to make a function callable only by a whitelisted operator.
     */
    modifier onlyWhitelistedOperator() {
        require(isOperator(_msgSender()), "PrePaid: invalid operator");
        _;
    }

    IERC20Transfers public immutable revv;
    bool public saleStarted = false;
    bool public saleEnded = false;
    uint256 public globalDeposit = 0;
    uint256 public globalEarnings = 0;
    mapping(address => uint256) public balanceOf; // wallet => escrowed amount

    /**
     * @dev Reverts if `revv_` is the zero address.
     * @param revv_ An ERC20-compliant contract address.
     */
    constructor(
        IERC20Transfers revv_
    ) public {
        require(revv_ != IERC20Transfers(0), "PrePaid: zero address");
        revv = revv_;
        _pause(); // pause on start
    }

    /**
     * Deposits `amount` into the sender's escrow balance and updates the global deposit
     * balance.
     * @dev Sender should ensure that this contract has a transfer allowance of
     *  at least `amount` of REVV from their account before calling this function.
     * @dev Reverts if the contract is paused.
     * @dev Reverts if the sale has started.
     * @dev Reverts if the sale has ended.
     * @dev Reverts if the deposit amount is zero.
     * @dev Reverts if the updated global deposit balance overflows.
     * @dev Reverts if the deposit transfer from the sender fails.
     * @dev Emits the Deposited event.
     * @dev An amount of ERC20 `revv` is transferred from the sender to this contract.
     * @param amount The amount to deposit.
     */
    function deposit(
        uint256 amount
    ) external whenNotPaused whenNotStarted whenNotEnded {
        require(amount != 0, "PrePaid: zero deposit");
        globalDeposit = globalDeposit.add(amount);
        address sender = _msgSender();
        uint256 newBalance = balanceOf[sender] + amount;
        balanceOf[sender] = newBalance;
        require(
            revv.transferFrom(sender, address(this), amount),
            "PrePaid: transfer in failed"
        );
        emit Deposited(sender, amount);
    }

    /**
     * Withdraws the remainder of the sender's escrow balance to their wallet.
     * @dev Reverts if the sale has not ended.
     * @dev Reverts if the sender has no balance to withdraw from.
     * @dev Reverts if the transfer to the sender fails.
     * @dev Emits the Withdrawn event.
     * @dev An amount of ERC20 `revv` is transferred from the contract to sender.
     */
    function withdraw() external whenEnded {
        address sender = _msgSender();
        uint256 balance = balanceOf[sender];
        require(balance != 0, "PrePaid: no balance");
        require(
            revv.transfer(sender, balance),
            "PrePaid: transfer out failed"
        );
        balanceOf[sender] = 0;
        emit Withdrawn(sender, balance);
    }

     /**
     * Consumes a pre-paid `amount` from the specified wallet's escrow balance and
     * updates the global earnings balance.
     * @dev Reverts if the contract is paused.
     * @dev Reverts if sale has not started.
     * @dev Reverts if the sale has ended.
     * @dev Reverts if called by any other than a whitelisted operator.
     * @dev Reverts if the consumption amount is zero.
     * @dev Reverts if the given wallet has an insufficient balance to deduct the
     *  specified `amount` from.
     * @dev Reverts if the updated global earnings balance overflows.
     * @dev An amount of ERC20 `revv` is transferred from the contract to the sender.
     * @param wallet The wallet from which to consume `amount` from its escrow balance.
     * @param amount The amount to consume.
     */
    function consume(
        address wallet,
        uint256 amount
    ) external whenNotPaused whenStarted whenNotEnded onlyWhitelistedOperator {
        require(amount != 0, "PrePaid: zero consumption");
        uint256 balance = balanceOf[wallet];
        require(balance >= amount, "PrePaid: insufficient funds");
        balanceOf[wallet] = balance - amount;
        globalEarnings = globalEarnings.add(amount);
    }

    /**
     * Deducts revv escrowed by wallet and deposits to operator
     * @dev Reverts if the sale has not ended.
     * @dev Reverts if called by any other than the contract owner.
     * @dev Reverts if the global earnings balance is zero.
     * @dev Reverts if the transfer to the sender fails.
     * @dev An amount of ERC20 `revv` is transferred from this contract to the sender.
     */
    function collectRevenue() external whenEnded onlyOwner {
        require(globalEarnings != 0, "PrePaid: no earnings");
        require(
            revv.transfer(_msgSender(), globalEarnings),
            "PrePaid: transfer out failed"
        );
        globalEarnings = 0;
    }

    /**
     * Gets the discount percentage based on the global deposit balance.
     * @return The discount percentage.
     */
    function getDiscount() external view returns (
        uint256
    ) {
        uint256 value = globalDeposit;

        if (value < 2e25) {
            return 0;
        } else if (value < 3e25) {
            return 10;
        } else if (value < 4e25) {
            return 25;
        } else {
            return 50;
        }
    }
    
    /**
     * Sets the sale started state.
     * @dev Reverts if called by any other than the contract owner.
     * @dev Emits the SaleStarted event.
     * @param start The sale started state to set. Specifying `true` starts the sale
     *  period, `false` resets the sale started state.
     */
    function setStartSale(bool start) external onlyOwner {
        saleStarted = start;
        emit SaleStarted(start);
    }

    /**
     * Sets the sale ended state.
     * @dev Reverts if called by any other than the contract owner.
     * @dev Emits the SaleEnded event.
     * @param end The sale ended state to set. Specifying `true` ends the sale period,
     *  `false` resets the sale ended state.
     */
    function setEndSale(bool end) external onlyOwner {
        saleEnded = end;
        emit SaleEnded(end);
    }

     /**
     * Pauses the contract.
     * @dev Reverts if called by any other than the contract owner.
     * @dev Reverts if the contract is paused.
     * @dev Emits the Paused event.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * Unpauses the contract.
     * @dev Reverts if called by any other than the contract owner.
     * @dev Reverts if the contract is not paused.
     * @dev Emits the Unpaused event.
     */
    function unpause() external onlyOwner {
        _unpause();
    }
}
