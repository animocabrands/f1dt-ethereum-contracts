const { MetaTxPayoutWallet } = require('../src/constants');

const REVV = artifacts.require('REVV');
const Address = artifacts.require('Address.sol');
const SafeMath = artifacts.require('SafeMath.sol');
const UInt256ToDecimalString = artifacts.require('UInt256ToDecimalString.sol');
const Bytes32ToBase32String = artifacts.require('Bytes32ToBase32String.sol');
const DeltaTimeInventory = artifacts.require('DeltaTimeInventory.sol');

module.exports = async (deployer, network, accounts) => {

    await deployer.deploy(Address);
    await Address.deployed();
    const address = (await Address.deployed()).address;

    await deployer.deploy(SafeMath);
    await SafeMath.deployed();
    const safeMath = (await SafeMath.deployed()).address;

    await deployer.deploy(UInt256ToDecimalString);
    await UInt256ToDecimalString.deployed();
    const uInt256ToDecimalString = (await UInt256ToDecimalString.deployed()).address;

    await deployer.deploy(Bytes32ToBase32String);
    await Bytes32ToBase32String.deployed();
    const bytes32ToBase32String = (await Bytes32ToBase32String.deployed()).address;

    await DeltaTimeInventory.link("Address", address);
    await DeltaTimeInventory.link("SafeMath", safeMath);
    await DeltaTimeInventory.link("UInt256ToDecimalString", uInt256ToDecimalString);
    await DeltaTimeInventory.link("Bytes32ToBase32String", bytes32ToBase32String);

    const revvContract = await REVV.deployed();

    await deployer.deploy(DeltaTimeInventory, revvContract.address, MetaTxPayoutWallet, { gas: 10000000 });
    const inventoryContract = await DeltaTimeInventory.deployed();

    console.log(`Registering as REVV whitelisted operator`);
    await revvContract.whitelistOperator(inventoryContract.address, true);
}