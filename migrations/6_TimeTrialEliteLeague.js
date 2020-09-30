const {fromWei} = require('web3-utils');
const {toBytes32Attribute} = require('@animoca/ethereum-contracts-assets_inventory').bytes32Attributes;

const REVV = artifacts.require('REVV');
const TimeTrialEliteLeague = artifacts.require('TimeTrialEliteLeague');

const LeagueAmountsMap = {
    'A':10000,
    'B':5000,
    'C':1000,
}

const LockingPeriod = 1209600; // 14 Days

module.exports = async (deployer, network, accounts) => {
    const revvContract = await REVV.deployed();
    await deployer.deploy(
        TimeTrialEliteLeague,
        revvContract.address,
        LockingPeriod,
        Object.keys(LeagueAmountsMap).map(id=>toBytes32Attribute(id)),
        Object.values(LeagueAmountsMap)
    );

    const timeTrialEliteLeagueContract = await TimeTrialEliteLeague.deployed();
    console.log(timeTrialEliteLeagueContract);
};
