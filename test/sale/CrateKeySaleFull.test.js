const { accounts, contract } = require('@openzeppelin/test-environment');
const { BN, expectEvent, expectRevert } = require('@openzeppelin/test-helpers');
const ContractDeployer = require('../helpers/ContractDeployer');
const PrepaidBehavior = require('./PrepaidBehaviors');
const TokenBehavior = require("./TokenBehaviors");
const { stringToBytes32 } = require('@animoca/ethereum-contracts-sale_base/test/utils/bytes32');
const { ZeroAddress, Zero, One, Two } = require('@animoca/ethereum-contracts-core_library').constants;
const TOKENS = ContractDeployer.TOKENS;

const [deployer, operation, anonymous, ...participants] = accounts;
const [participant, participant2, participant3] = participants;

describe("scenario", async function () {

    before(async function () {
        this.revv = await ContractDeployer.deployREVV({ from: deployer });

        this.prepaid = await ContractDeployer.deployPrepaid({ from: deployer });

        // //CrateKey Sale
        this.sale = await ContractDeployer.deployCrateKeySale({ from: deployer });

        this.keys = await ContractDeployer.deployCrateKeyTokens({ from: deployer }, operation);
        const { F1DT_CCK, F1DT_RCK, F1DT_ECK, F1DT_LCK } = this.keys;
        this.f1dtCck = F1DT_CCK;
        this.f1dtEck = F1DT_ECK;
        this.f1dtLck = F1DT_LCK;
        this.f1dtRck = F1DT_RCK;
    });

    describe("Prepaid", function () {
        /**        DEPLOY AND UNPAUSE PREPAID CONTRACT            */
        //1. this.prepaid.unpause
        PrepaidBehavior.beforeDeposit(deployer);

        // /**        USERS DEPOSIT DURING PREPAID PERIOD (BEFORE SALE START)            */
        PrepaidBehavior.userDeposit(participants);

        PrepaidBehavior.pauseDeposit(participants);

        PrepaidBehavior.unpauseDeposit(participants);
    });

    describe("Sales(setup SKU)", function () {
        
        TokenBehavior.createCrateKeyTokens();

        it('add Common Crate Keys sku(\'F1DT.CCK\')', async function () {
            // Simulate a sku value
            const tokenObject = TOKENS.F1DT_CCK;
            const tokenContract = this.f1dtCck;
            const sku = stringToBytes32(tokenObject.symbol);
            const presaleSupply = tokenObject.presaleSupply;
            await tokenContract.approve(this.sale.address, presaleSupply, { from: operation });
            const receipt = await this.sale.createCrateKeySku(sku, presaleSupply, toWei("20"), tokenContract.address, { from: deployer });
            expectEvent(receipt, 'SkuCreation', {
                sku: sku,
                totalSupply: presaleSupply,
                maxQuantityPerPurchase: presaleSupply,
                notificationsReceiver: ZeroAddress,
            });
        });

        it('add Common Crate Keys sku(\'F1DT.RCK\')', async function () {
            // Simulate a sku value
            const tokenObject = TOKENS.F1DT_RCK;
            const tokenContract = this.f1dtRck;
            const sku = stringToBytes32(tokenObject.symbol);
            const presaleSupply = tokenObject.presaleSupply;
            await tokenContract.approve(this.sale.address, presaleSupply, { from: operation });
            const receipt = await this.sale.createCrateKeySku(sku, presaleSupply, toWei("20"), tokenContract.address, { from: deployer });
            expectEvent(receipt, 'SkuCreation', {
                sku: sku,
                totalSupply: presaleSupply,
                maxQuantityPerPurchase: presaleSupply,
                notificationsReceiver: ZeroAddress,
            });
        });

        it('add Common Crate Keys sku(\'F1DT.ECK\')', async function () {
            // Simulate a sku value
            const tokenObject = TOKENS.F1DT_ECK;
            const tokenContract = this.f1dtEck;
            const sku = stringToBytes32(tokenObject.symbol);
            const presaleSupply = tokenObject.presaleSupply;
            await tokenContract.approve(this.sale.address, presaleSupply, { from: operation });
            const receipt = await this.sale.createCrateKeySku(sku, presaleSupply, toWei("20"), tokenContract.address, { from: deployer });
            expectEvent(receipt, 'SkuCreation', {
                sku: sku,
                totalSupply: presaleSupply,
                maxQuantityPerPurchase: presaleSupply,
                notificationsReceiver: ZeroAddress,
            });
        });

        it('add Common Crate Keys sku(\'F1DT.LCK\')', async function () {
            // Simulate a sku value
            const tokenObject = TOKENS.F1DT_LCK;
            const tokenContract = this.f1dtLck;
            const sku = stringToBytes32(tokenObject.symbol);
            const presaleSupply = tokenObject.presaleSupply;
            await tokenContract.approve(this.sale.address, presaleSupply, { from: operation });
            const receipt = await this.sale.createCrateKeySku(sku, presaleSupply, toWei("20"), tokenContract.address, { from: deployer });
            expectEvent(receipt, 'SkuCreation', {
                sku: sku,
                totalSupply: presaleSupply,
                maxQuantityPerPurchase: presaleSupply,
                notificationsReceiver: ZeroAddress,
            });
        });

        it('update sku price for F1DT.CCK', async function () {
            const tokenObject = TOKENS.F1DT_CCK;
            const actualPrice = new BN(tokenObject.price).div(new BN('2'));
            const sku = stringToBytes32(tokenObject.symbol);
            const receipt = await this.sale.updateSkuPricing(sku, [this.revv.address], [actualPrice], { from: deployer });
            /* cannot test the array for prices, the test helper is using a array of [bignumber], it is using he deep comparison for each element,
                the array in the event is not instantiate by the test, so instance compare will fail. 
                expectEvent(receipt, "SkuPricingUpdate", {sku, tokens: [this.revv.address], prices:[actualPrice]})
            */
            expectEvent(receipt, "SkuPricingUpdate", {sku, tokens: [this.revv.address]});

            const {prices} = await this.sale.getSkuInfo(sku);
            prices[0].should.be.bignumber.eq(actualPrice);
        });

        it('update sku price for F1DT.RCK', async function () {
            const tokenObject = TOKENS.F1DT_RCK;
            const actualPrice = new BN(tokenObject.price).div(new BN('2'));
            const sku = stringToBytes32(tokenObject.symbol);
            const receipt = await this.sale.updateSkuPricing(sku, [this.revv.address], [actualPrice], { from: deployer });
            expectEvent(receipt, "SkuPricingUpdate", {sku, tokens: [this.revv.address]});

            const {prices} = await this.sale.getSkuInfo(sku);
            prices[0].should.be.bignumber.eq(actualPrice);
        });

        it('update sku price for F1DT.ECK', async function () {
            const tokenObject = TOKENS.F1DT_ECK;
            const actualPrice = new BN(tokenObject.price).div(new BN('2'));
            const sku = stringToBytes32(tokenObject.symbol);
            const receipt = await this.sale.updateSkuPricing(sku, [this.revv.address], [actualPrice], { from: deployer });
            expectEvent(receipt, "SkuPricingUpdate", {sku, tokens: [this.revv.address]});

            const {prices} = await this.sale.getSkuInfo(sku);
            prices[0].should.be.bignumber.eq(actualPrice);
        });

        it('update sku price for F1DT.LCK', async function () {
            const tokenObject = TOKENS.F1DT_LCK;
            const actualPrice = new BN(tokenObject.price).div(new BN('2'));
            const sku = stringToBytes32(tokenObject.symbol);
            const receipt = await this.sale.updateSkuPricing(sku, [this.revv.address], [actualPrice], { from: deployer });
            expectEvent(receipt, "SkuPricingUpdate", {sku, tokens: [this.revv.address]});

            const {prices} = await this.sale.getSkuInfo(sku);
            prices[0].should.be.bignumber.eq(actualPrice);
        });        
    })


    // /**        CREATE SKUs          */
    describe("Prepaid", function () {
        before(function () {
            this.whitelistOperator = this.sale.address;
        })

        PrepaidBehavior.addWhiteListedOperator();
    });
    /**        START SALE          */
    describe("Sales(Start)", function () {
        it("should start sales", async function () {
            const receipt = (await this.sale.start({ from: deployer }));
            await expectEvent(receipt, "Started", { account: deployer });
            (await this.sale.startedAt()).should.be.bignumber.gt("0");
        });
        it("prepaid should switch to start state", async function () {
            const startState = (await this.prepaid.SALE_START_STATE());
            (await this.prepaid.state()).should.be.bignumber.eq(startState);
        });
    });

    /**        BUY ITEMS          */

    describe("Sales(Purchase)", function () {
        /**        PURCHASE ITEMS ON SALE          */
        it("should be able to purhcase Common Crate Key", async function () {
            
        });

    });
});
