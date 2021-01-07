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
     * @dev Reverts `rarities` and `weights` have different lengths.
     * @dev Reverts if `revvEscrowingWeightCoefficient_` is zero.
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
     * Verifies that the token is eligible and returns its associated weight.
     * @dev Reverts if the token is not a 2019 Car NFT.
     * @param nftId uint256 token identifier of the NFT.
     * @return uint64 the weight of the NFT.
     */
    function _validateAndGetNftWeight(uint256 nftId) internal virtual override view returns (uint64) {
        // Ids bits layout specification:
        // https://github.com/animocabrands/f1dt-core_metadata/blob/v0.1.1/src/constants.js
        uint256 nonFungible = (nftId >> 255) & 1;
        uint256 tokenType = (nftId >> 240) & 0xFF;
        uint256 tokenSeason = (nftId >> 224) & 0xFF;
        uint256 tokenRarity = (nftId >> 176) & 0xFF;

        // For interpretation of values, refer to https://github.com/animocabrands/f1dt-core_metadata/blob/version-1.0.3/src/mappings/
        // Types: https://github.com/animocabrands/f1dt-core_metadata/blob/version-1.0.3/src/mappings/CommonAttributes/Type/Types.js
        // Seasons: https://github.com/animocabrands/f1dt-core_metadata/blob/version-1.0.3/src/mappings/CommonAttributes/Season/Seasons.js
        // Rarities: https://github.com/animocabrands/f1dt-core_metadata/blob/version-1.0.3/src/mappings/CommonAttributes/Rarity/Rarities.js
        require(nonFungible == 1 && tokenType == 1 && tokenSeason == 2, "NftStaking: wrong token");

        return weightsByRarity[tokenRarity];
    }
}
