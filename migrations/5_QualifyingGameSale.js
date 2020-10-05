// const BN = require('web3-utils').BN;
// const {toWei} = require('web3-utils');
// const {RaceEntrySalePayoutWallet, RaceEntrySalePayoutToken, RaceEntrySalePrices} = require('../src/constants');

// const RaceEntrySale = artifacts.require('RaceEntrySale.sol');
// const REVV = artifacts.require('REVV.sol');

module.exports = async (deployer, network, [owner]) => {
    // await deployer.deploy(
    //     RaceEntrySale,
    //     RaceEntrySalePayoutWallet,
    //     RaceEntrySalePayoutToken,
    //     { from: owner });
    // const sale = await RaceEntrySale.deployed();
    // const rev = await REVV.deployed();
    // await rev.whitelistOperator(sale.address, true, { from: owner });
    // for (const price of RaceEntrySalePrices) {
    //     const tx = await sale.setPrice(
    //         price.id,
    //         toWei(price.ethPrice),
    //         toWei(price.revvPrice),
    //         { from: owner });
    //     console.dir(tx.receipt);
    // }
};
