const { accounts, contract } = require('@openzeppelin/test-environment');
const { toWei } = require('web3-utils');
const { BN, expectRevert, expectEvent } = require('@openzeppelin/test-helpers');
const { ZeroAddress, Zero, One, Two } = require('@animoca/ethereum-contracts-core_library').constants;
const {stringToBytes32} = require('@animoca/ethereum-contracts-sale_base/test/utils/bytes32');
const ContractDeployer = require('../helpers/ContractDeployer')

const [deployer, holder] = accounts;
const TOKENS = ContractDeployer.TOKENS;


/**
 * Set Allowance and Create CrateKey Sku
 * 
 * @param {string} tokenHolder 
 * @param {string} f1dtCckContract 
 * @param {string*} f1dtRckContract 
 * @param {string} f1dtEckContract 
 * @param {string} f1dtLckContract 
 * @param {string} saleContract 
 */
module.exports.createCrateKeySku = function(
    tokenHolder = holder, 
    f1dtCckContract,
    f1dtRckContract,
    f1dtEckContract,
    f1dtLckContract,
    saleContract
) {
    before(async function() {
        this.f1dtCck = f1dtCckContract || this.f1dtCck;
        this.f1dtRck = f1dtRckContract || this.f1dtRck;
        this.f1dtEck = f1dtEckContract || this.f1dtEck;
        this.f1dtLck = f1dtLckContract || this.f1dtLck;
        this.sale = saleContract || this.sale;
    });

    //TODO add cases for failure...

    it('creates the sku', async function () {
        // Simulate a sku value
        const sku = stringToBytes32(TOKENS.F1DT_CCK.symbol);

        await this.f1dtCck.approve(this.sale.address, One, {from: tokenHolder});
        const receipt = await this.sale.createCrateKeySku(sku, One, One, this.f1dtCck.address, {from: deployer});
            expectEvent(receipt, 'SkuCreation', {
                sku: sku,
                totalSupply: One,
                maxQuantityPerPurchase: One,
                notificationsReceiver: ZeroAddress,
            });

    });
}


