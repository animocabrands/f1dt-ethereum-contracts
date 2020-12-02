const { accounts, contract } = require('@openzeppelin/test-environment');
const { toWei } = require('web3-utils');
const deployer = accounts[0];
/**
 * @typedef {{from : string}} Web3Option
 */

/**
 * @async
 * @param {Web3Option} options 
 * @param {string[]} addresses 
 * @param {string[]} amountPerAccount 
 */
module.exports.deployREVV = async function (options = { from: deployer }, addresses = accounts, amountPerAccount = toWei('100000000')) {
    const REVV = contract.fromArtifact('REVV');
    const amounts = new Array(addresses.length).fill(amountPerAccount);
    this.revv = await REVV.new(addresses, amounts, options);
    return this.revv;
};

/**
 * @async
 * @param {Web3Option} options 
 * @param {string} revvAddress
 */
module.exports.deployPrepaid = async function (options = { from: deployer }, revvAddress) {
    if(this.revv || revvAddress) {
        const PrePaid = contract.fromArtifact('Prepaid');
        const address = revvAddress || this.revv.address;
        this.prepaid = await PrePaid.new(address, options);
    } else {
        throw new Error("Cannot find Revv Contract");
    }
    return this.prepaid;
}


function getTokenDescription(type) {
    return `F1&#174; Delta Time ${type} Crate Key`;
}

const TOKENS = {
    F1DT_CCK: {symbol: 'F1DT.CCK', name: getTokenDescription('Common'), totalSupply: '5000'},
    F1DT_RCK: {symbol: 'F1DT.RCK', name: getTokenDescription('Rare'), totalSupply: '4000'},
    F1DT_ECK: {symbol: 'F1DT.ECK', name: getTokenDescription('Epic'), totalSupply: '3000'},
    F1DT_LCK: {symbol: 'F1DT.LCK', name: getTokenDescription('Legendary'), totalSupply: '1000'},
};

/**
 * F1DT Tokens Spec
 */
module.exports.TOKENS = TOKENS;

const TOKEN_DECIMALS = '18';

/**
 * Token Decimals Spec
 */
module.exports.TOKEN_DECIMALS = TOKEN_DECIMALS;

async function getCrateKeyInstance(token, accountHolder, options) {
    const F1DTCrateKey = contract.fromArtifact('F1DTCrateKey');

    return await F1DTCrateKey.new(
        token.symbol,
        token.name,
        accountHolder,
        token.totalSupply, 
        options
    ); 
};

/**
 * @async
 * @param {Web3Option} options 
 * @param {string} accountHolder
 */
module.exports.deployCrateKeyTokens = async function(options = {from: deployer}, accountHolder) {
    const f1dtCck = await getCrateKeyInstance(TOKENS.F1DT_CCK, accountHolder, options);
    const f1dtEck = await getCrateKeyInstance(TOKENS.F1DT_ECK, accountHolder, options);
    const f1dtLck = await getCrateKeyInstance(TOKENS.F1DT_LCK, accountHolder, options);
    const f1dtRck = await getCrateKeyInstance(TOKENS.F1DT_RCK, accountHolder, options);
    return { 
        F1DT_CCK: f1dtCck,
        F1DT_RCK: f1dtRck,
        F1DT_ECK: f1dtEck,
        F1DT_LCK: f1dtLck        
    };
}

/**
 * @async
 * @param {Web3Option} options 
 * @param {string} prepaidAddress 
 */
module.exports.deployCrateKeySale = async function(options = {from: deployer}, prepaidAddress) {
    if(this.prepaid || prepaidAddress) {
        const CrateKeySale = contract.fromArtifact('CrateKeySale');
        const address = prepaidAddress || this.prepaid.address;
        this.sale = await CrateKeySale.new(address, options);

        await this.prepaid.whitelistOperator(this.sale.address, true, options);

    } else {
        throw new Error("Cannot find Prepaid Contract");
    }
    return this.sale;
}
