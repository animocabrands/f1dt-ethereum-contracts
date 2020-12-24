// SPDX-License-Identifier: MIT

pragma solidity ^0.6.8;

import "../../game/Crates2020.sol";

contract Crates2020Mock is Crates2020 {

    constructor(
        IF1DTInventory INVENTORY_,
        IF1DTBurnableCrateKey COMMON_CRATE_,
        IF1DTBurnableCrateKey RARE_CRATE_,
        IF1DTBurnableCrateKey EPIC_CRATE_,
        IF1DTBurnableCrateKey LEGENDARY_CRATE_,
        uint256 counter_
    ) public Crates2020(INVENTORY_, COMMON_CRATE_, RARE_CRATE_, EPIC_CRATE_, LEGENDARY_CRATE_, counter_) {}


    function openCrates(uint256 crateTier, uint256 quantity, uint256 seed) public {
        _openCrates(crateTier, quantity, seed);
    }
}

