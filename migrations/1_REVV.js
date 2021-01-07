const {BN} = require('web3-utils');
const REVV = artifacts.require('REVV');
const {RewardsPool} = require('../src/constants');

module.exports = async (deployer, network, accounts) => {
    await deployer.deploy(REVV, [accounts[0]], [RewardsPool.mul(new BN(2)).add(new BN('100000000000000000000000'))]);
};
