const { accounts, contract } = require('@openzeppelin/test-environment');
const { toWei } = require('web3-utils');
const { BN, expectRevert, expectEvent } = require('@openzeppelin/test-helpers');
const { ZeroAddress, Zero, One, Two } = require('@animoca/ethereum-contracts-core_library').constants;
const { stringToBytes32 } = require('@animoca/ethereum-contracts-sale_base/test/utils/bytes32');
const ContractDeployer = require('../helpers/ContractDeployer')

const [deployer, purchaser, operator, holder] = accounts;
const TOKENS = ContractDeployer.TOKENS;

const REVV = contract.fromArtifact('REVV');

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
module.exports.createCrateKeySku = function (
    holder = accounts[1],
    deployer = accounts[0],
    f1dtCckContract,
    f1dtRckContract,
    f1dtEckContract,
    f1dtLckContract,
    prepaidContract,
    saleContract
) {
    describe("Create Key SKU", function () {


        before(async function () {
            this.f1dtCck = f1dtCckContract || this.f1dtCck;
            this.f1dtRck = f1dtRckContract || this.f1dtRck;
            this.f1dtEck = f1dtEckContract || this.f1dtEck;
            this.f1dtLck = f1dtLckContract || this.f1dtLck;
            this.prepaid = prepaidContract || this.prepaid;
            this.sale = saleContract || this.sale;
        });

        //TODO add cases for failure...

        it('creates the sku', async function () {
            // Simulate a sku value
            const sku = stringToBytes32(TOKENS.F1DT_CCK.symbol);
            const totalSupply = TOKENS.F1DT_CCK.totalSupply;
            await this.f1dtCck.approve(this.sale.address, totalSupply, { from: holder });
            const receipt = await this.sale.createCrateKeySku(sku, totalSupply, totalSupply, this.f1dtCck.address, { from: deployer });
            expectEvent(receipt, 'SkuCreation', {
                sku: sku,
                totalSupply: totalSupply,
                maxQuantityPerPurchase: totalSupply,
                notificationsReceiver: ZeroAddress,
            });
        });

        it('set the sku price', async function () {
            // Simulate a sku value
            const sku = stringToBytes32(TOKENS.F1DT_CCK.symbol);
            //const otherErc20 = await REVV.new([purchaser], [toWei('1000')], {from: deployer});
            const revert = await this.sale.updateSkuPricing(sku, [this.revv.address], [One], { from: deployer });
        });
    });

}


