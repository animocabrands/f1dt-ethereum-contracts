// SPDX-License-Identifier: MIT

pragma experimental ABIEncoderV2;
pragma solidity 0.6.8;

import "../../metadata/Crates2020RNGLib.sol";

contract Crates2020RNGLibMock {
    using Crates2020RNGLib for uint256;

    uint256 counter;

    constructor(uint256 counter_) public {
        counter = counter_;
    }

    function generateSeed() public view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), msg.sender)));
    }

    function generateCrate(uint256 crateTier) external returns (uint256[] memory tokens) {
        uint256 counter_ = counter;
        tokens = generateSeed().generateCrate(crateTier, 0);
        counter = counter_ + tokens.length;
    }
}
