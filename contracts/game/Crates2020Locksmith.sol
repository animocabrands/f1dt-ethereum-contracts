// SPDX-License-Identifier: MIT

pragma solidity ^0.6.8;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/cryptography/ECDSA.sol";
import "@animoca/ethereum-contracts-erc20_base/contracts/token/ERC20/IERC20.sol";
import "./Crates2020.sol";

contract Crates2020Locksmith is Crates2020 {
    using ECDSA for bytes32;

    // account => crateTier => nonce
    mapping(address => mapping(uint256 => uint256)) public nonces;

    address public signerKey;

    constructor(
        IF1DTInventory INVENTORY_,
        IF1DTBurnableCrateKey COMMON_CRATE_,
        IF1DTBurnableCrateKey RARE_CRATE_,
        IF1DTBurnableCrateKey EPIC_CRATE_,
        IF1DTBurnableCrateKey LEGENDARY_CRATE_
    ) public Crates2020(INVENTORY_, COMMON_CRATE_, RARE_CRATE_, EPIC_CRATE_, LEGENDARY_CRATE_) {}

    /**
     * Burns a key in order to mint a crate of 2020 season content.
     * @dev reverts if `crateTier` is not one of 
     */
    function insertKey(uint256 crateTier, bytes calldata sig) external {
        address sender = _msgSender();
        require(crateTier <= Crates2020RNGLib._CRATE_TIER_COMMON, "Locksmith: wrong crate tier");
        bytes32 hash_ = keccak256(abi.encode(sender, crateTier, nonces[sender][crateTier]));
        require(hash_.recover(sig) == signerKey, "Locksmith: invalid signature");
        uint256 seed = uint256(keccak256(sig));
        _openCrate(crateTier, seed);
    }
}
