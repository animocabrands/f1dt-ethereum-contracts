const {asciiToHex} = require('web3-utils');

const {
    EthAddress
} = require('@animoca/ethereum-contracts-core_library').constants;

const {
    RaceEntrySalePayoutWallet,
    RaceEntrySalePayoutToken,
    RaceEntrySalePrices
} = require('../src/constants');

const RaceEntrySale = artifacts.require('RaceEntrySale.sol');
const REVV = artifacts.require('REVV.sol');

module.exports = async (deployer, network, [owner]) => {
    await deployer.deploy(
        RaceEntrySale,
        RaceEntrySalePayoutWallet,
        RaceEntrySalePayoutToken,
        { from: owner });

    const sale = await RaceEntrySale.deployed();
    const revv = await REVV.deployed();

    const tokens = [
        revv.address,
        EthAddress];

    console.log(`Adding supported payment tokens`);
    await sale.addSupportedPaymentTokens(
        tokens,
        { from: owner });

    const skus = RaceEntrySalePrices.map(item => asciiToHex(item.id));

    console.log('Adding inventory skus');
    await sale.addInventorySkus(
        skus,
        { from: owner });

    console.log('Setting sku token prices ');
    for (const raceEntrySalePrice of RaceEntrySalePrices) {
        await sale.setSkuTokenPrices(
            asciiToHex(raceEntrySalePrice.id),
            tokens,
            [
                raceEntrySalePrice.revvPrice,
                raceEntrySalePrice.ethPrice
            ],
            { from: owner });
    }

    console.log('Starting the race entry sale');
    await sale.start({ from: owner });
};
