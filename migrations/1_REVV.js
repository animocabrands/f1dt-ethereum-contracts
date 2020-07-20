const REVV = artifacts.require('REVV');
const {RewardsPool} = require('../src/constants');

module.exports = async (deployer, network, accounts) => {
    await deployer.deploy(REVV, [accounts[0]], [RewardsPool]);
    REVV.deployed();
};
