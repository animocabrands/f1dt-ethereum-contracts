// SPDX-License-Identifier: MIT

pragma solidity 0.6.8;

import "./ERC20WithFixedSupply.sol";

/**
 * @title F1 Delta Time Epic Crate Key
 */
contract F1DT_ECK is ERC20WithFixedSupply {
    // solhint-disable-next-line const-name-snakecase
    string public constant override symbol = "F1DT.ECK";
    // solhint-disable-next-line const-name-snakecase
    string public constant override name = "F1&#174; Delta Time Epic Crate Key";
    // solhint-disable-next-line const-name-snakecase
    uint8 public constant override decimals = 18;

    constructor(address[] memory holders, uint256[] memory amounts, uint256 totalSupply) public ERC20WithFixedSupply(totalSupply) {
        require(holders.length == amounts.length, "F1DT_ECK: wrong arguments");
        for (uint256 i = 0; i < holders.length; ++i) {
            _mint(holders[i], amounts[i]);
        }
    }
}
