const { fromWei, toWei } = require('web3-utils');

const REVV = artifacts.require('REVV');
const Inventory = artifacts.require("DeltaTimeInventory");
const Staking = artifacts.require("DeltaTimeStakingBeta");

const RevvStakingPoolBalance = toWei('10000200');

const PayoutSchedule = [
    { startPeriod: 1, endPeriod: 4, payoutPerCycle: toWei('150000') },
    { startPeriod: 5, endPeriod: 5, payoutPerCycle: toWei('120000') },
    { startPeriod: 6, endPeriod: 6, payoutPerCycle: toWei('115000') },
    { startPeriod: 7, endPeriod: 7, payoutPerCycle: toWei('110000') },
    { startPeriod: 8, endPeriod: 8, payoutPerCycle: toWei('105000') },
    { startPeriod: 9, endPeriod: 9, payoutPerCycle: toWei('100000') },
    { startPeriod: 10, endPeriod: 10, payoutPerCycle: toWei('95000') },
    { startPeriod: 11, endPeriod: 11, payoutPerCycle: toWei('92000') },
    { startPeriod: 12, endPeriod: 12, payoutPerCycle: toWei('91600') },
];

module.exports = async (deployer, network, accounts) => {

    const revvContract = await REVV.deployed();
    const inventoryContract = await Inventory.deployed();

    await deployer.deploy(Staking,
        inventoryContract.address,
        revvContract.address
    );

    const stakingContract = await Staking.deployed();

    for (schedule of PayoutSchedule) {
        console.log(`Setting schedule: ${fromWei(schedule.payoutPerCycle)} REVVs per cycle for periods ${schedule.startPeriod} to ${schedule.endPeriod}`);
        await stakingContract.setRewardsForPeriods(
            schedule.startPeriod,
            schedule.endPeriod,
            schedule.payoutPerCycle
        );
    }

    // Requires the deployer to hold enough REVVs

    // console.log(`Giving approval to the staking contract for the reward pool before starting (${fromWei(RevvStakingPoolBalance)} REVVs)`);
    // await revvContract.approve(stakingContract.address, RevvStakingPoolBalance);

    // console.log('Starting the staking');
    // await stakingContract.start();
}
