const REVV = artifacts.require('REVV');

module.exports = async (deployer, network, accounts) => {
    await deployer.deploy(REVV);
    REVV.deployed();
}