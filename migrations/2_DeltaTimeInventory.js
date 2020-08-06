const {MetaTxPayoutWallet} = require('../src/constants');

const REVV = artifacts.require('REVV');
const Bytes = artifacts.resolver.require('Bytes', '../imports');

const DeltaTimeInventory = artifacts.resolver.require('DeltaTimeInventory', '../imports');
DeltaTimeInventory.synchronization_timeout = 0;
artifacts.cache.push(DeltaTimeInventory);

module.exports = async (deployer, network, accounts) => {
    const revvContract = await REVV.deployed();

    await deployer.deploy(Bytes);
    await Bytes.deployed();
    const bytes = (await Bytes.deployed()).address;

    await DeltaTimeInventory.link('Bytes', bytes);

    await deployer.deploy(DeltaTimeInventory, revvContract.address, MetaTxPayoutWallet, {gas: 10000000});
    const inventoryContract = await DeltaTimeInventory.deployed();

    console.log(`Registering as REVV whitelisted operator`);
    await revvContract.whitelistOperator(inventoryContract.address, true);
};
