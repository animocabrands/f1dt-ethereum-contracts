const { stringToBytes32 } = require('../src/utils');

const {
    EthAddress
} = require('@animoca/ethereum-contracts-core_library').constants;

const {
    QualifyingGameSalePayoutWallet,
    QualifyingGameSalePayoutToken,
    QualifyingGameSalePrices
} = require('../src/constants');

const QualifyingGameSale = artifacts.require('QualifyingGameSale.sol');
const REVV = artifacts.require('REVV.sol');

module.exports = async (deployer, network, [owner]) => {
    await deployer.deploy(
        QualifyingGameSale,
        QualifyingGameSalePayoutWallet,
        QualifyingGameSalePayoutToken,
        { from: owner });

    const sale = await QualifyingGameSale.deployed();
    const revv = await REVV.deployed();

    const tokens = [
        revv.address,
        EthAddress];

    console.log(`Adding supported payment tokens`);
    await sale.addSupportedPaymentTokens(
        tokens,
        { from: owner });

    const skus = QualifyingGameSalePrices.map(item => item.sku);

    console.log('Adding inventory skus');
    await sale.addInventorySkus(
        skus,
        { from: owner });

    console.log('Setting sku token prices ');
    for (const qualifyingGameSalePrice of QualifyingGameSalePrices) {
        await sale.setSkuTokenPrices(
            qualifyingGameSalePrice.sku,
            tokens,
            [
                qualifyingGameSalePrice.revvPrice,
                qualifyingGameSalePrice.ethPrice
            ],
            { from: owner });
    }

    console.log('Starting the qualifying game sale');
    await sale.start({ from: owner });
};
