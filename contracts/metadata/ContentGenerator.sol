// SPDX-License-Identifier: MIT

pragma experimental ABIEncoderV2;
pragma solidity 0.6.8;

import "./Crates2020MetadataLib.sol";

contract ContentGenerator {
    using Crates2020MetadataLib for uint256;

    uint256 counter;

    constructor(uint256 counter_) public {
        counter = counter_;
    }

    function generateSeed() public view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), msg.sender)));
    }

    function generateCrate(uint256 crateTier) external view returns (uint256[] memory tokens) {
        require(crateTier < 4, "Crates2020: wrong crate tier");
        if (crateTier == Crates2020MetadataLib._CRATE_TIER_RARE) {
            tokens = generateSeed().generateCrate_twoGuaranteedDrops(crateTier, counter);
        } else {
            tokens = generateSeed().generateCrate_oneGuaranteedDrop(crateTier, counter);
        }
    }
}
