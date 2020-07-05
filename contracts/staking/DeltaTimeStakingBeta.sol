// SPDX-License-Identifier: MIT

pragma solidity 0.6.8;

import "@animoca/ethereum-contracts-nft_staking/contracts/staking/NftStaking.sol";

/**
 * @title Delta Time Staking Beta
 * This contract allows owners of Delta Time 2019 Car NFTs to stake them in exchange for REVV rewards.
 */
contract DeltaTimeStakingBeta is NftStaking {

    mapping(uint256 => uint64) public weightsByRarity;

    /**
     * Constructor.
     * @param cycleLengthInSeconds_ The length of a cycle, in seconds.
     * @param periodLengthInCycles_ The length of a period, in cycles.
     * @param inventoryContract IWhitelistedNftContract the DeltaTimeInventory contract.
     * @param revvContract IERC20 the REVV contract.
     * @param rarities uint256[] the supported DeltaTimeInventory NFT rarities.
     * @param weights uint64[] the staking weights associated to the NFT rarities.
     */
    constructor(
        uint32 cycleLengthInSeconds_,
        uint16 periodLengthInCycles_,
        IWhitelistedNftContract inventoryContract,
        IERC20 revvContract,
        uint256[] memory rarities,
        uint64[] memory weights
    ) public NftStaking(cycleLengthInSeconds_, periodLengthInCycles_, inventoryContract, revvContract) {
        require(rarities.length == weights.length, "NftStaking: wrong arguments");
        for (uint256 i = 0; i < rarities.length; ++i) {
            weightsByRarity[rarities[i]] = weights[i];
        }
    }

    /**
     * Verifes that the token is eligible and returns its associated weight.
     * Throws if the token is not a 2019 Car NFT.
     * @param nftId uint256 token identifier of the NFT.
     * @return uint64 the weight of the NFT.
     */
    function _validateAndGetNftWeight(uint256 nftId) internal virtual override view returns (uint64) {
        // Ids bits layout specification:
        // https://github.com/animocabrands/f1dt-core_metadata/blob/v0.1.1/src/constants.js
        uint256 fungible = (nftId & (1 << 255)) >> 255;
        uint256 tokenType = (nftId & (0xFF << 240)) >> 240;
        uint256 tokenSeason = (nftId & (0xFF << 224)) >> 224;
        uint256 tokenRarity = (nftId & (0xFF << 176)) >> 176;

        // For interpretation of values, refer to: https://github.com/animocabrands/f1dt-core_metadata/tree/v0.1.1/src/mappings
        // Types: https://github.com/animocabrands/f1dt-core_metadata/blob/v0.1.1/src/mappings/Common/Types/NameById.js
        // Seasons: https://github.com/animocabrands/f1dt-core_metadata/blob/v0.1.1/src/mappings/Common/Seasons/NameById.js
        // Rarities: https://github.com/animocabrands/f1dt-core_metadata/blob/v0.1.1/src/mappings/Common/Rarities/TierByRarity.js
        require(
            fungible == 1 &&
            tokenType == 1 &&
            tokenSeason == 2,
            "NftStaking: wrong token"
        );

        return weightsByRarity[tokenRarity];
    }
}
