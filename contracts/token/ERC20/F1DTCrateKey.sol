// SPDX-License-Identifier: MIT

pragma solidity 0.6.8;

import "@animoca/ethereum-contracts-erc20_base/contracts/token/ERC20/ERC20WithOperators.sol";

contract F1DTCrateKey is ERC20WithOperators {

    // solhint-disable-next-line const-name-snakecase
    string public override symbol;
    // solhint-disable-next-line const-name-snakecase
    string public override name;
    // solhint-disable-next-line const-name-snakecase
    uint8 public constant override decimals = 18;

    address public holder;

    /**
     * Constructor.
     * @param symbol_ Symbol of the token.
     * @param name_ Name of the token.
     * @param holder_ Holder account of the initial supply.
     * @param totalSupply_ Total amount of tokens in existence.
     */
    constructor (
        string memory symbol_, 
        string memory name_,    
        address holder_, 
        uint256 totalSupply_) public ERC20WithOperators() {

        require(bytes(symbol_).length > 0, "F1DTCrateKey: invalid symbol");
        require(bytes(name_).length > 0, "F1DTCrateKey: invalid name");
        require(holder_ != address(0), "F1DTCrateKey: invalid holder");
        require(totalSupply_ != 0, "F1DTCrateKey: invalid total supply");

        symbol = symbol_;
        name = name_;
        holder = holder_;
        _totalSupply = totalSupply_;
        _balances[holder_] = totalSupply_;
    }
}
