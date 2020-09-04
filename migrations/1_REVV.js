const {BN} = require('web3-utils');
const REVV = artifacts.require('REVV');
const {RewardsPool} = require('../src/constants');

module.exports = async (deployer, network, accounts) => {
    await deployer.deploy(REVV, [accounts[0]], [RewardsPool.add(new BN(10000))]);
};
