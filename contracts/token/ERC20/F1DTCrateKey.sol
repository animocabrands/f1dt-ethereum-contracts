// SPDX-License-Identifier: MIT

pragma solidity 0.6.8;

import "@animoca/ethereum-contracts-erc20_base/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title F1DTCrateKey
 * A token contract for Crate Keys
 * @dev F1DT.CCK for Common crate. Initial supply: 5000. Max Supply: 6700.
 * @dev F1DT.RCK for Rare crate. Initial supply: 1000. Max Supply: 1320.
 * @dev F1DT.ECK for Epic crate. Initial supply: 4000. Max Supply: 5350.
 * @dev F1DT.LCK for Legendary crate. Initial supply: 3000. Max Supply: 4050.
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
     * @param holder_ Holder account of the token initial supply.
     * @param initialSupply_ Initial supply amount
     */
    constructor (
        string memory symbol_, 
        string memory name_,    
        address holder_, 
        uint256 initialSupply_) public {

        require(bytes(symbol_).length > 0, "F1DTCrateKey: invalid symbol");
        require(bytes(name_).length > 0, "F1DTCrateKey: invalid name");
        require(holder_ != address(0), "F1DTCrateKey: invalid holder");
        require(initialSupply_ != 0, "F1DTCrateKey: invalid initial supply");

        symbol = symbol_;
        name = name_;
        holder = holder_;

        _mint(holder, initialSupply_);
    }

    /**
     * Mint `amount` tokens.
     * In addition to the initial supply, more keys could be added 
     * based on the amount of REVV deposited by players.
     * @dev Reverts if called by any other than the contract owner.
     * @dev Reverts is `amount` is invalid
     * @param amount_ Amount of token to mint
     */
    function mint(uint256 amount_) external onlyOwner {
        require(amount_ != 0, "F1DTCrateKey: invalid amount");

        _mint(_msgSender(), amount_);
    }

    /**
     * Destroys `amount` tokens.
     * @dev Reverts if called by any other than the contract owner.
     * @dev Reverts is `amount` is invalid
     * @param amount_ Amount of token to burn
     */
    function burn(uint256 amount_) external onlyOwner {
        require(amount_ != 0, "F1DTCrateKey: invalid amount");

        _burn(_msgSender(), amount_);
    }
}
