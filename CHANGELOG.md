# Changelog

## 1.0.0
 * Updated to `@animoca/ethereum-contracts-nft_staking:4.0.0`.
 * Staking is separated in phase 1 and phase 2.
 * Phase 2 requires escrowing of REVV for staking.
 * Added `TimeTrialEliteLeague.sol`, a contract to manage the participation status of players to the elite tiers.
 * Added `TimeTrialEliteLeague.sol` tests.
 * Added `CrateKeySale.sol`, a `FixedPricesSale` contract implementation that handle the purchase of ERC20 `F1DTCrateKey` tokens.
 * Added `CrateKeySale.sol` coverage and scenario tests.
 * Added `PrePaid.sol`, a contract to manage the pre-paid purchase deposits for a future sale.
 * Added `PrePaid.sol` tests and test behaviors.
 * Added and disabled `DeltaTimeStaking.sol`, an NFT V2 staking contract for F1 DeltaTime.
 * Disabled `DeltaTimeStaking.sol` tests.
 * `DeltaTimeStakingBeta.sol`: Removed the `revvEscrowingWeightCoefficient` state member variable and it's usages/references.
 * `DeltaTimeStakingBeta.sol`: Changed the type of the `inventoryContract` constructor parameter from `IERC1155721Transferrable` to `IWhitelistedNftContract`.
 * `DeltaTimeStakingBeta.sol`: Removed `_onStake()` function hooks.
 * `DeltaTimeStakingBeta.sol`: Removed `_onUnstake()` function hooks.
 * Added `DeltaTimeStakingBeta.sol` tests.
 * Added `F1DTCrateKey`, an ERC20 contract whose tokens represent a purchasable 'key' used to open a lootbox crate.
 * Added `F1DTCrateKey` coverage tests and test behaviors.
 * Removed `TrackTickets.sol`.
 * `1_REVV.js`: Updated the amount allocated for the account holder balance on the REVV contract construction.
 * Renamed `2a_REVVSale.js` migration script to `3_REVVSale.js`.
 * Renamed `3_NFTRepairCentre.js` migration script to `4_NFTRepairCentre.js`.
 * Renamed `4_DeltaTimeStakingBeta.js` migration script to `5_DeltaTimeStakingBeta.js`.
 * `5_DeltaTimeStakingBeta.js`: Used the `DeltaTimeInventoryV2` contract for the deployment.
 * `5_DeltaTimeStakingBeta.js`: Fixed missing `const` variable type declaration in the for-loop.
 * Added `6_DeltaTimeStaking.js` migration script for deploying the `DeltaTimeStaking.sol` contract.
 * Added `6_TimeTrialEliteLeague.js` migration script for deploying the `TimeTrialEliteLeague.sol` contract.
 * Renamed `5_QualifyingGameSale.js` migration script to `7_QualifyingGameSale.js`.
 * Added `ContractDeployer.js` test helper module.
 * Refreshed `yarn.lock`.

## 0.4.0
 * Added `NFTRepairCentre`, a contract to manage defunct NFTs.
 * Updated to `@animoca/ethereum-contracts-core_library:3.1.1`.
 * Updated to `@animoca/ethereum-contracts-sale_base:6.0.0`.
 * Removed `RaceEntrySale.sol` sale contract, tests, and sample migration script.
 * Updated `QualifyingGameSale.sol` with `@animoca/ethereum-contracts-sale_base:6.0.0` compatibility changes.
 * Added `REVVSale`.

## 0.3.0
 * Updated to `@animoca/ethereum-contracts-sale_base@4.0.0`.
 * Compatibility changes for `RaceEntrySale.sol` to use `@animoca/ethereum-contracts-sale_base@4.0.0`.
 * Added `QualifyingGameSale.sol` sale contract.
 * Updated to `@animoca/ethereum-contracts-nft_staking:3.0.3`.

## 0.2.3
 * Updated to `@animoca-ethereum-nft_staking@3.0.1` and `@animoca-ethereum-assets_inventory@4.0.0`.
 * Added documentation for `REVV`.
 * Linting configuration.
 * Migrated to `yarn`.

## 0.2.2
 * Optimise values retrieval in token id for staking.

## 0.2.1
 * Improved checks on NFT type for staking.

## 0.2.0
 * Updated to `@animoca/ethereum-contracts-nft_staking:3.0.0`.
 * Updated to `@animoca/ethereum-contracts-sale_base:3.0.0`.

## 0.1.0
 * Renamed `DeltaTimeInventory` to `DeltaTimeInventoryV2`.
 * Added solidity source for previously deployed contracts.
 * Added `DeltaTimeStakingBetaV2`.

## 0.0.1
 * Initial commit.
