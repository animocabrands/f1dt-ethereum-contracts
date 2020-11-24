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
 * @title PrePaidContract.
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
    uint256 public globalDeposit = 0;
    uint256 public globalEarnings = 0;
    mapping(address => uint256) public balanceOf; // wallet => escrowed amount

    /**
     * @dev Reverts if `gamingToken_` is the zero address.
     * @dev Reverts if any element of `amounts` is zero.
     * @param gamingToken_ An ERC20-compliant contract address.
     */
    constructor(
        IERC20Transfers gamingToken_
    ) public {
        require(gamingToken_ != IERC20Transfers(0), "PrePaid: zero address");
        gamingToken = gamingToken_;
        _pause(); // pause on start
    }

    /**
     * Add amount to user's deposit and globalDeposit
     * @dev Reverts if sale has started
     * @dev Emits a OnDeposit event.
     * @dev An amount of ERC20 `gamingToken` is transferred from the sender to this contract.
     * @param amount The amount to deposit.
     */
    function deposit(uint256 amount) whenNotPaused public {
        address sender = _msgSender();
        require(saleStarted == false, "PrePaid: sale started");
        require(amount != 0, "PrePaid: zero deposit");
        uint256 newAmount = balanceOf[sender].add(amount);
        balanceOf[sender] = newAmount;
        require(
            gamingToken.transferFrom(sender, address(this), amount),
            "PrePaid: transfer in failed"
        );
        globalDeposit = globalDeposit.add(amount);
        emit OnDeposit(sender, newAmount);
    }

    /**
     * Withdraw amount to user's deposit
     * @dev Reverts if sale has started
     * @dev Emits a OnWithdraw event.
     * @dev An amount of ERC20 `gamingToken` is transferred from the contract to sender.
     * @param amount The amount to withdraw.
     */
    function withdrawAll() whenNotPaused public {
        address sender = _msgSender();
        require(saleEnded == true, "PrePaid: sale not ended");
        uint256 balance = balanceOf[sender];
        require(balance != 0, "PrePaid: no balance");
        require(
            gamingToken.transfer(sender, balance),
            "PrePaid: transfer out failed"
        );
        balanceOf[sender] = 0;
        emit OnWithdraw(sender, balance);
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
        require(saleStarted == false, "PrePaid: sale started");
        require(balanceOf[sender] >= amount, "PrePaid: insufficient funds");
        uint256 newAmount = balanceOf[sender].sub(amount);
        balanceOf[sender] = newAmount;
        require(
            gamingToken.transfer(sender, amount),
            "PrePaid: transfer out failed"
        );
        emit OnWithdraw(sender, newAmount);
    }

     /**
     * consume prepay
     * @dev Reverts if sale has started
     * @dev Emits a OnWithdraw event.
     * @dev An amount of ERC20 `gamingToken` is transferred from the contract to sender.
     * @param amount The amount to withdraw.
     */
    function consume(address wallet, uint256 amount) whenNotPaused public {
        address sender = _msgSender();
        require(isOperator(sender), "PrePaid: only operator");
        require(saleStarted == false, "PrePaid: sale started");
        require(balanceOf[wallet] >= amount, "PrePaid: insufficient funds");
        uint256 newAmount = balanceOf[wallet].sub(amount);
        balanceOf[wallet] = newAmount;
        require(
            gamingToken.transfer(sender, amount),
            "PrePaid: transfer out failed"
        );
        globalEarnings = globalEarnings.add(amount);
    }

    /**
     * Deducts revv escrowed by wallet and deposits to operator
     * @dev Reverts if the wallet has no amount escrowed
     * @dev Reverts if amount is greater than revv escrowed
     * @dev Reverts if sale has not ended
     * @dev An amount of ERC20 `gamingToken` is transferred from this contract to the sender.
     */
    function collectRevenue() public onlyOwner{
        address sender = _msgSender();
        require(saleEnded == true, "PrePaid: sale not ended");
        require(globalEarnings > 0, "PrePaid: no earnings");
        
        require(
            gamingToken.transfer(sender, globalEarnings),
            "PrePaid: transfer out failed"
        );
        
        globalEarnings = 0;
    }

    /**
     * Gets the amount escrowed for wallet
     * @param wallet The address of the wallet
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
        returns (uint256 memory discount)
    {
        if(globalDeposit >= 40000000000000000000000000)
            return 50;
        else if(globalDeposit >= 30000000000000000000000000)
            return 25;
        else if(globalDeposit >= 20000000000000000000000000)
            return 10;
        else
            return 0;

    }
    
    function startSale() whenNotPaused external onlyOwner {
        require(saleStarted == false, "PrePaid: already started");
        saleStarted = true;
        emit OnSaleStarted();
    }

    function endSale() whenNotPaused external onlyOwner {
        require(saleStarted == true, "PrePaid: sale not started");
        require(saleEnded == false, "PrePaid: already ended");
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


