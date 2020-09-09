const BN = require('web3-utils').BN;
const {toWei} = require('web3-utils');
const {QualifyingGameSalePayoutWallet} = require('../src/constants');

const REVVSale = artifacts.require('REVVSale.sol');
const REVV = artifacts.require('REVV.sol');
const DeltaTimeInventory = artifacts.require('DeltaTimeInventory.sol');

module.exports = async (deployer, network, [owner]) => {
    const revv = await REVV.deployed();
    const inventory = await DeltaTimeInventory.deployed();
    await deployer.deploy(REVVSale, revv.address, inventory.address, QualifyingGameSalePayoutWallet, {from: owner});
    const sale = await REVVSale.deployed();
    await revv.whitelistOperator(sale.address, true, {from: owner});
};
