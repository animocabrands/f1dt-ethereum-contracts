// SPDX-License-Identifier: MIT

pragma solidity 0.6.8;

import "@animoca/ethereum-contracts-erc20_base/contracts/token/ERC20/ERC20WithOperators.sol";

abstract contract ERC20WithFixedSupply is ERC20WithOperators {

    constructor (uint256 totalSupply) public ERC20WithOperators() {
        require(totalSupply != 0, "ERC20: invalid total supply");
        _totalSupply = totalSupply;
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, but not increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal override {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        // Total supply will not be changed
        //_totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }
}
