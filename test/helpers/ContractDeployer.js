const { accounts, contract } = require('@openzeppelin/test-environment');
const { toWei } = require('web3-utils');
const deployer = accounts[0];
/**
 * @typedef {{from : string}} Web3Option
 */

/**
 * @async
 * @param {Web3Option} options 
 * @param {String[]} addresses 
 * @param {String[]} amountPerAccount 
 */
module.exports.deployREVV = async function (options = { from: deployer }, addresses = accounts, amountPerAccount = toWei('100000000')) {
    const REVV = contract.fromArtifact('REVV');
    const amounts = new Array(addresses.length).fill(amountPerAccount);
    this.revv = await REVV.new(addresses, amounts, options);
    return this.revv;
};


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
