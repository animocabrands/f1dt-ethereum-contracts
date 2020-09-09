const {fromWei, toWei} = require('web3-utils');
const {rewardsPoolFromSchedule} = require('@animoca/ethereum-contracts-nft_staking').utils;
const {CycleLengthInSeconds, PeriodLengthInCycles, WeightsByRarity, RewardsSchedule, REVVEscrowingWeightCoefficient} = require('../src/constants');

const REVV = artifacts.require('REVV');
const Inventory = artifacts.require('DeltaTimeInventory');
const Staking = artifacts.require('DeltaTimeStakingPhase2');

const RewardsPool = rewardsPoolFromSchedule(RewardsSchedule, PeriodLengthInCycles);

module.exports = async (deployer, network, accounts) => {
    const revvContract = await REVV.deployed();
    const inventoryContract = await Inventory.deployed();

    await deployer.deploy(
        Staking,
        CycleLengthInSeconds,
        PeriodLengthInCycles,
        inventoryContract.address,
        revvContract.address,
        Object.keys(WeightsByRarity),
        Object.values(WeightsByRarity),
        toWei(REVVEscrowingWeightCoefficient)
    );

    const stakingContract = await Staking.deployed();

    console.log(`Approving ${fromWei(RewardsPool)} REVVs to the staking contract for the reward pool before starting`);
    await revvContract.approve(stakingContract.address, RewardsPool);

    for (schedule of RewardsSchedule) {
        console.log(
            `Setting schedule: ${fromWei(schedule.payoutPerCycle)} REVVs per-cycle for periods ${
                schedule.startPeriod
            } to ${schedule.endPeriod}`
        );
        await stakingContract.addRewardsForPeriods(schedule.startPeriod, schedule.endPeriod, schedule.payoutPerCycle);
    }

    console.log('Starting the staking schedule');
    await stakingContract.start();
};
