// SPDX-License-Identifier: MIT

pragma solidity 0.6.8;

import "@animoca/ethereum-contracts-nft_staking/contracts/staking/NftStakingV2.sol";

/**
 * @title Delta Time Staking
 * This contract allows owners of Delta Time 2019 Car and Driver NFTs to stake them in exchange for REVV rewards.
 * Staking requires escrowing of REVV in proportion of the staked weight.
 */
contract DeltaTimeStaking is NftStakingV2 {

    uint256 public immutable revvEscrowingWeightCoefficient;
    
    mapping(uint256 => uint64) public weightsByRarity;

    /**
     * Constructor.
     * @dev Reverts if `rarities` and `weights` have different lengths.
     * @dev Reverts if `revvEscrowingWeightCoefficient_` is zero.
     * @dev Reverts if `weights` contains at least one item that value is higher than half uint64
     * @param cycleLengthInSeconds_ The length of a cycle, in seconds.
     * @param periodLengthInCycles_ The length of a period, in cycles.
     * @param inventoryContract IERC1155721Transferrable the DeltaTimeInventory contract.
     * @param revvContract IERC20 the REVV contract.
     * @param rarities uint256[] the supported DeltaTimeInventory NFT rarities.
     * @param weights uint64[] the staking weights associated to the NFT rarities.
     * @param revvEscrowingWeightCoefficient_ uint256 the amount of REVV to escrow for staking one unit of weight, in wei.
     */
    constructor(
        uint32 cycleLengthInSeconds_,
        uint16 periodLengthInCycles_,
        IERC1155721Transferrable inventoryContract,
        IERC20 revvContract,
        uint256[] memory rarities,
        uint64[] memory weights,
        uint256 revvEscrowingWeightCoefficient_
    )
        public
        NftStakingV2(
            cycleLengthInSeconds_,
            periodLengthInCycles_,
            inventoryContract,
            revvContract 
        )
    {
        require(revvEscrowingWeightCoefficient_ != 0, "NftStaking: invalid coefficient");
        require(rarities.length == weights.length, "NftStaking: wrong arguments");

        // Max value will be a half of uint64 due to the condition that it can be multiplied by 2 according to token type
        uint64 weightMaxValue = type(uint64).max >> 1;
        for (uint256 i = 0; i < rarities.length; ++i) {
            uint64 weight = weights[i];
            require(weight > 0 && weight <= weightMaxValue, "NftStaking: invalid weight value");
            weightsByRarity[rarities[i]] = weight;
        }
        revvEscrowingWeightCoefficient = revvEscrowingWeightCoefficient_;
    }

    /**
     * Verifies that the token is eligible and returns its associated weight.
     * @dev Reverts if the token is not a 2019 Car or Driver NFT.
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
        require(nonFungible == 1 && (tokenType == 1 || tokenType == 2) && tokenSeason == 2, "NftStaking: wrong token");

        // Drivers(2) will have a regular weight as defined in the mapping, but for Cars(1) it will be the double
        if (tokenType == 1) {
            //Safe calculation due to the validation done on the constructor
            return weightsByRarity[tokenRarity] * 2;
        }
        return weightsByRarity[tokenRarity];
    }

    /**
     * Staking REVV tokens according to the total token weight multiplied by weight coefficient
     * Hook called on NFT(s) staking
     * @dev Reverts if the REVV escrow transfer fails.
     * @param owner uint256 the NFT(s) owner.
     * @param totalWeight uint256 the total weight of the staked NFT(s).
     */
    function _onStake(address owner, uint256 totalWeight) internal override {
        require(
            rewardsTokenContract.transferFrom(owner, address(this), totalWeight.mul(revvEscrowingWeightCoefficient)),
            "NFTStaking: REVV transfer failed"
        );
    }

    /**
     * Returns REVV tokens to the staker
     * Hook called on NFT(s) unstaking 
     * @dev Reverts if the REVV transfer fails.
     * @param owner uint256 the NFT(s) owner.
     * @param totalWeight uint256 the total weight of the unstaked NFT(s).
     */
    function _onUnstake(address owner, uint256 totalWeight) internal override {
        require(
            rewardsTokenContract.transfer(owner, totalWeight.mul(revvEscrowingWeightCoefficient)),
            "NFTStaking: REVV transfer failed"
        );
    }
}
