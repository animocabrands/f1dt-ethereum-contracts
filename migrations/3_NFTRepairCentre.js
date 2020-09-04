const {MetaTxPayoutWallet} = require('../src/constants');

const REVV = artifacts.require('REVV');
const DeltaTimeInventory = artifacts.require('DeltaTimeInventory');
const RepairCentre = artifacts.require('NFTRepairCentre');

let RepairList = require('@animoca/f1dt-core_metadata/src/mappings/RepairList');
RepairList = Object.fromEntries(Object.entries(RepairList).slice(-10));
const TotalCompensation = Object.keys(RepairList).length;

module.exports = async (deployer, network, [owner]) => {
    const revv = await REVV.deployed();
    const inventory = await DeltaTimeInventory.deployed();

    await deployer.deploy(RepairCentre, inventory.address, MetaTxPayoutWallet, revv.address, 1);
    const repairCentre = await RepairCentre.deployed();

    console.log(`Registering as Delta Time Inventory minter`);
    await inventory.addMinter(repairCentre.address);

    console.log(`Approving ${TotalCompensation} REVVs for depositing the compensation`);
    await revv.approve(repairCentre.address, TotalCompensation);

    console.log(`Adding the tokens to repair and depositing the REVVs for compensation`);
    await repairCentre.addTokensToRepair(Object.keys(RepairList), Object.values(RepairList));
};
