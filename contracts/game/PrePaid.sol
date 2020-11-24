// SPDX-License-Identifier: MIT

pragma solidity 0.6.8;

import "@openzeppelin/contracts/GSN/Context.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@animoca/ethereum-contracts-core_library/contracts/payment/PayoutWallet.sol";
import "@animoca/ethereum-contracts-core_library/contracts/access/WhitelistedOperators.sol";

/// Minimal transfers-only ERC20 interface
interface IERC20Transfers {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

/**
 * @title PrePayContract.
 * Contract which manages the deposits made by wallets for pre sale
 * Participants are allowed to make deopsits and withdraw before sale starts
 */
contract PrePaid is Context, Pausable, WhitelistedOperators {
    using SafeMath for uint256;
    /**
     * Event emitted on deposit
     * @param wallet The address of the user.
     * @param amount New amount in user's escorw after deposit
     */
    event OnDeposit(address wallet, uint256 amount);

    /**
     * Event emitted on withdraw
     * @param wallet The address of the user.
     * @param amount Amount deducted from user's escorw
     */
    event OnWithdraw(address wallet, uint256 amount);

    /**
     * Event emitted on withdraw revenue
     * @param wallet The address of the user.
     * @param amount Amount deducted from user's escorw
     */
    event OnWithdrawRevenue(address wallet, uint256 amount);

    /**
     * Event emitted on sale start
     */
    event OnSaleStart();

    /**
     * Event emitted on sale end
     */
    event OnSaleEnd();

    IERC20Transfers public immutable gamingToken;
    bool public saleStarted = false;
    bool public saleEnded = false;
    uint256 public globalPool = 0;
    mapping(address => uint256) public balanceOf; // wallet => escrowed amount

    /**
     * @dev Reverts if `gamingToken_` is the zero address.
     * @dev Reverts if any element of `amounts` is zero.
     * @param gamingToken_ An ERC20-compliant contract address.
     */
    constructor(
        IERC20Transfers gamingToken_
    ) public {
        require(gamingToken_ != IERC20Transfers(0), "PrePay: zero address");
        gamingToken = gamingToken_;
        _pause(); // pause on start
    }

    /**
     * Add amount to user's deposit and globalPool
     * @dev Reverts if sale has started
     * @dev Emits a OnDeposit event.
     * @dev An amount of ERC20 `gamingToken` is transferred from the sender to this contract.
     * @param amount The amount to deposit.
     */
    function deposit(uint256 amount) whenNotPaused public {
        address sender = _msgSender();
        require(saleStarted == false, "PrePay: sale started");
        uint256 newAmount = balanceOf[sender].add(amount);
        balanceOf[sender] = newAmount;
        require(
            gamingToken.transferFrom(sender, address(this), amount),
            "PrePay: transfer in failed"
        );
        globalPool = globalPool.add(amount);
        emit OnDeposit(sender, newAmount);
    }

    /**
     * Withdraw amount to user's deposit
     * @dev Reverts if sale has started
     * @dev Emits a OnWithdraw event.
     * @dev An amount of ERC20 `gamingToken` is transferred from the contract to sender.
     * @param amount The amount to withdraw.
     */
    function withdraw(uint256 amount) whenNotPaused public {
        address sender = _msgSender();
        require(saleStarted == false, "PrePay: sale started");
        require(balanceOf[sender] >= amount, "PrePay: insufficient funds");
        uint256 newAmount = balanceOf[sender].sub(amount);
        balanceOf[sender] = newAmount;
        require(
            gamingToken.transferFrom(address(this), sender, amount),
            "PrePay: transfer out failed"
        );
        emit OnWithdraw(sender, newAmount);
    }

    /**
     * Deducts revv escrowed by wallet and deposits to operator
     * @dev Reverts if the wallet has no amount escrowed
     * @dev Reverts if amount is greater than revv escrowed
     * @dev Reverts if sale has not ended
     * @dev Emits a ParticipationUpdated event.
     * @dev An amount of ERC20 `gamingToken` is transferred from this contract to the sender.
     */
    function withdrawRevenue(address wallet, uint256 amount) public onlyOwner{
        address sender = _msgSender();
        require(saleEnded == true, "PrePay: sale not ended");

        uint256 balance = balanceOf[wallet];
        require(balance != 0, "PrePay: no balance");
        require(balance <= amount, "PrePay: insufficient funds");
        
        require(
            gamingToken.transfer(sender, amount),
            "PrePay: transfer out failed"
        );
        balanceOf[wallet] = balance.sub(amount);
        emit OnWithdrawRevenue(sender, amount);
    }

    /**
     * Gets the amount escrowed for wallet
     * @param wallet The participant to check the status of.
     * @return amount escrowed for wallet
     */
    function getBalance(address wallet)
        external
        view
        returns (uint256 memory amount)
    {
        return balanceOf[wallet];
    }

    /**
     * Gets the current discount based on globalDeposit
     * @return discount percentage
     */
    function getDiscount()
        external
        view
        returns (uint256 memory amount)
    {
        if(globalDeposit >= 40000000)
            return 50;
        else if(globalDeposit >= 30000000)
            return 25;
        else if(globalDeposit >= 20000000)
            return 10;
        else return 0;

    }
    
    function startSale() external onlyOwner {
        require*(saleStarted == false, "PrePay: already started");
        saleStarted = true;
        emit OnSaleStarted();
    }

    function endSale() external onlyOwner {
        require(saleStarted == true, "PrePay: sale not started");
        require(saleEnded == false, "PrePay: already ended");
        saleEnded = true;
        emit OnSaleEnd();
    }


     /**
     * Pauses the deposit operations.
     * @dev Reverts if the sender is not the contract owner.
     * @dev Reverts if the contract is paused already.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * Unpauses the deposit operations.
     * @dev Reverts if the sender is not the contract owner.
     * @dev Reverts if the contract is not paused.
     */
    function unpause() external onlyOwner {
        _unpause();
    }
}


