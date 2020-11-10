// SPDX-License-Identifier: MIT

pragma solidity 0.6.8;

import "@animoca/ethereum-contracts-nft_staking/contracts/staking/NftStakingV2.sol";


// /**
//  * @title Delta Time Staking
//  * This contract allows owners of Delta Time 2019 Car NFTs to stake them in exchange for REVV rewards.
//  * Staking requires escrowing of REVV in proportion of the staked weight.
//  */
// contract DeltaTimeStaking is DeltaTimeStakingV2 {
//     uint256 public immutable revvEscrowingWeightCoefficient;

//     /**
//      * Constructor.
//      * @dev Reverts `rarities` and `weights` have different lengths.
//      * @dev Reverts if `revvEscrowingWeightCoefficient_` is zero.
//      * @param cycleLengthInSeconds_ The length of a cycle, in seconds.
//      * @param periodLengthInCycles_ The length of a period, in cycles.
//      * @param inventoryContract IERC1155721Transferrable the DeltaTimeInventory contract.
//      * @param revvContract IERC20 the REVV contract.
//      * @param rarities uint256[] the supported DeltaTimeInventory NFT rarities.
//      * @param weights uint64[] the staking weights associated to the NFT rarities.
//      * @param revvEscrowingWeightCoefficient_ uint256 the amount of REVV to escrow for staking one unit of weight, in wei.
//      */
//     constructor(
//         uint32 cycleLengthInSeconds_,
//         uint16 periodLengthInCycles_,
//         IERC1155721Transferrable inventoryContract,
//         IERC20 revvContract,
//         uint256[] memory rarities,
//         uint64[] memory weights,
//         uint256 revvEscrowingWeightCoefficient_
//     )
//         public
//         DeltaTimeStakingPhase1(
//             cycleLengthInSeconds_,
//             periodLengthInCycles_,
//             inventoryContract,
//             revvContract,
//             rarities,
//             weights
//         )
//     {
//         require(revvEscrowingWeightCoefficient_ != 0, "NftStaking: invalid coefficient");
//         revvEscrowingWeightCoefficient = revvEscrowingWeightCoefficient_;
//     }

//     /**
//      * Hook called on NFT(s) staking.
//      * @dev Reverts if the REVV escrow transfer fails.
//      * @param owner uint256 the NFT(s) owner.
//      * @param totalWeight uint256 the total weight of the staked NFT(s).
//      */
//     function _onStake(address owner, uint256 totalWeight) internal override {
//         require(
//             rewardsTokenContract.transferFrom(owner, address(this), totalWeight.mul(revvEscrowingWeightCoefficient)),
//             "NFTStaking: REVV transfer failed"
//         );
//     }

//     /**
//      * Hook called on NFT(s) unstaking.
//      * @dev Reverts if the REVV transfer fails.
//      * @param owner uint256 the NFT(s) owner.
//      * @param totalWeight uint256 the total weight of the unstaked NFT(s).
//      */
//     function _onUnstake(address owner, uint256 totalWeight) internal override {
//         require(
//             rewardsTokenContract.transfer(owner, totalWeight.mul(revvEscrowingWeightCoefficient)),
//             "NFTStaking: REVV transfer failed"
//         );
//     }
// }
