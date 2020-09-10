const BN = require('web3-utils').BN;
const {toWei} = require('web3-utils');
const {QualifyingGameSalePayoutWallet, QualifyingGameSalePayoutToken, QualifyingGameSalePrices} = require('../src/constants');

const QualifyingGameSale = artifacts.require('QualifyingGameSale.sol');
const REVV = artifacts.require('REVV.sol');

module.exports = async (deployer, network, [owner]) => {
    // await deployer.deploy(
    //     QualifyingGameSale,
    //     QualifyingGameSalePayoutWallet,
    //     QualifyingGameSalePayoutToken,
    //     { from: owner });
    // const sale = await QualifyingGameSale.deployed();
    // const rev = await REVV.deployed();
    // await rev.whitelistOperator(sale.address, true, { from: owner });
    // for (const price of QualifyingGameSalePrices) {
    //     const tx = await sale.setPrice(
    //         price.id,
    //         toWei(price.ethPrice),
    //         toWei(price.revvPrice),
    //         { from: owner });
    //     console.dir(tx.receipt);
    // }
};
