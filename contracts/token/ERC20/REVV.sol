// SPDX-License-Identifier: MIT

pragma solidity 0.6.8;

import "@animoca/ethereum-contracts-erc20_base/contracts/token/ERC20/ERC20WithOperators.sol";

contract REVV is ERC20WithOperators {

    string public override constant name = "REVV";
    string public override constant symbol = "REVV";
    uint8 public override constant decimals = 18;

    address private constant _WALLET_FORMULA1 = 0x2d8ECD9Ee7A5fDF2FD78634Ce413601b0357DB19;
    address private constant _WALLET_MOTOGP = 0x8537aF398F15321f0e000e4f30978D0Eb821530a;
    address private constant _WALLET_RESERVE_A = 0x6cDa3Bb72b9F4Ad691b05Cab5Aa904A0FbB9e7d5;
    address private constant _WALLET_RESERVE_B = 0x59c6A2F6dc758Dc5C5567733cBB49dA7FDde3cBB;
    address private constant _WALLET_RESERVE_C = 0x8ec76b0099cBDc48bD19c57a263a0B527aE74890;

    uint256 public constant ALLOCATION_FORMULA1 = 1000000000 ether;
    uint256 public constant ALLOCATION_MOTOGP = 1000000000 ether;
    uint256 public constant ALLOCATION_RESERVE_A = 1000000000 ether;
    uint256 public constant ALLOCATION_RESERVE_B = 1000000000 ether;
    uint256 public constant ALLOCATION_RESERVE_C = 1000000000 ether;

    constructor () public ERC20WithOperators() {
        _mint(_WALLET_FORMULA1, ALLOCATION_FORMULA1);
        _mint(_WALLET_MOTOGP, ALLOCATION_MOTOGP);
        _mint(_WALLET_RESERVE_A, ALLOCATION_RESERVE_A);
        _mint(_WALLET_RESERVE_B, ALLOCATION_RESERVE_B);
        _mint(_WALLET_RESERVE_C, ALLOCATION_RESERVE_C);
    }
}
