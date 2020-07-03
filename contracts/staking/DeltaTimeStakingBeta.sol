// SPDX-License-Identifier: MIT

pragma solidity 0.6.8;

import "@animoca/ethereum-contracts-nft_staking/contracts/staking/NftStaking.sol";

contract DeltaTimeStakingBeta is NftStaking {
    mapping(uint256 => uint64) public weightsByRarity;

    constructor(
        uint32 cycleLengthInSeconds_,
        uint16 periodLengthInCycles_,
        IWhitelistedNftContract inventoryContract,
        IERC20 revvContract,
        uint256[] memory rarities,
        uint64[] memory weights
    ) public NftStaking(cycleLengthInSeconds_, periodLengthInCycles_, inventoryContract, revvContract) {
        require(rarities.length == weights.length, "REVV: wrong arguments");
        for (uint256 i = 0; i < rarities.length; ++i) {
            weightsByRarity[rarities[i]] = weights[i];
        }
    }

    function _validateAndGetNftWeight(uint256 nftId) internal virtual override view returns (uint64) {
        uint256 tokenType = (nftId & (0xFF << 240)) >> 240;
        require(tokenType == 1, "NftStaking: wrong token type");
        uint256 tokenRarity = (nftId & (0xFF << 176)) >> 176;
        return weightsByRarity[tokenRarity];
    }
}
