// SPDX-License-Identifier: MIT

pragma solidity 0.6.8;

import "@animoca/ethereum-contracts-erc20_base/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title F1DTCrateKey
 * A token contract for Crate Keys
 * @dev F1DT.CCK for Common crate. Total supply: 6700
 * @dev F1DT.ECK for Epic crate. Total supply: 4050
 * @dev F1DT.LCK for Legendary crate. Total supply: 1320
 * @dev F1DT.RCK for Rare crate. Total supply: 5350
 */
contract F1DTCrateKey is ERC20, Ownable {

    // solhint-disable-next-line const-name-snakecase
    string public override symbol;
    // solhint-disable-next-line const-name-snakecase
    string public override name;
    // solhint-disable-next-line const-name-snakecase
    uint8 public constant override decimals = 18;

    address public holder;

    /**
     * Constructor.
     * @dev Reverts if `symbol_` is not valid
     * @dev Reverts if `name_` is not valid
     * @dev Reverts if `holder_` is an invalid address
     * @dev Reverts if `totalSupply_` is equal to zero
     * @param symbol_ Symbol of the token.
     * @param name_ Name of the token.
     * @param holder_ Holder account of the initial supply.
     * @param totalSupply_ Total amount of tokens in existence.
     */
    constructor (
        string memory symbol_, 
        string memory name_,    
        address holder_, 
        uint256 totalSupply_) public {

        require(bytes(symbol_).length > 0, "F1DTCrateKey: invalid symbol");
        require(bytes(name_).length > 0, "F1DTCrateKey: invalid name");
        require(holder_ != address(0), "F1DTCrateKey: invalid holder");
        require(totalSupply_ != 0, "F1DTCrateKey: invalid total supply");

        symbol = symbol_;
        name = name_;
        holder = holder_;
        _totalSupply = totalSupply_;
        _balances[holder_] = totalSupply_;

        //CHECK MINT ...
        _mint(holder, _totalSupply);
    }

    function _mint(address account, uint256 amount) internal override {
        require(account != address(0), "F1DTCrateKey: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        //CHECK TOTAL SUPPLY
        //_totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    //TODO BURN CONDITION...

    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) external onlyOwner {
        //TODO Check parent function and also: _beforeTokenTransfer
        _burn(_msgSender(), amount);
    }
}
