const { accounts, contract } = require('@openzeppelin/test-environment');
const { BN, expectEvent, expectRevert } = require('@openzeppelin/test-helpers');
const ContractDeployer = require('../helpers/ContractDeployer');
const PrepaidBehavior = require('./PrepaidBehaviors');
const TokenBehavior = require("./TokenBehaviors");
const { stringToBytes32 } = require('@animoca/ethereum-contracts-sale_base/test/utils/bytes32');
const { ZeroAddress, Zero, One, Two, EmptyByte} = require('@animoca/ethereum-contracts-core_library').constants;
const { toWei } = require('web3-utils');
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
        const maxQuantity = toWei("20");

        it('add Common Crate Keys sku(\'F1DT.CCK\')', async function () {
            // Simulate a sku value
            const tokenObject = TOKENS.F1DT_CCK;
            const tokenContract = this.f1dtCck;
            const sku = stringToBytes32(tokenObject.symbol);
            const presaleSupply = tokenObject.presaleSupply;
            await tokenContract.approve(this.sale.address, presaleSupply, { from: operation });
            const receipt = await this.sale.createCrateKeySku(sku, presaleSupply, maxQuantity, tokenContract.address, { from: deployer });
            expectEvent(receipt, 'SkuCreation', {
                sku: sku,
                totalSupply: presaleSupply,
                maxQuantityPerPurchase: maxQuantity,
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
            const receipt = await this.sale.createCrateKeySku(sku, presaleSupply, maxQuantity, tokenContract.address, { from: deployer });
            expectEvent(receipt, 'SkuCreation', {
                sku: sku,
                totalSupply: presaleSupply,
                maxQuantityPerPurchase: maxQuantity,
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
            const receipt = await this.sale.createCrateKeySku(sku, presaleSupply, maxQuantity, tokenContract.address, { from: deployer });
            expectEvent(receipt, 'SkuCreation', {
                sku: sku,
                totalSupply: presaleSupply,
                maxQuantityPerPurchase: maxQuantity,
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
            const receipt = await this.sale.createCrateKeySku(sku, presaleSupply, maxQuantity, tokenContract.address, { from: deployer });
            expectEvent(receipt, 'SkuCreation', {
                sku: sku,
                totalSupply: presaleSupply,
                maxQuantityPerPurchase: maxQuantity,
                notificationsReceiver: ZeroAddress,
            });
        });

        it('update sku price for all skus', async function () {
            for (const tokenObject of Object.values(TOKENS)) {
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
            }
        });
    })


    // /**        add sales contract as whitelist operator to prepaid          */
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
        it("should be able to purhcase all keys once", async function () {
            for (const tokenObject of Object.values(TOKENS)) {
                const sku = stringToBytes32(tokenObject.symbol);
                const beforePurchaseBal = await this.prepaid.balanceOf(participant);
                const receipt = await this.sale.purchaseFor(participant, 
                                                            this.revv.address, 
                                                            sku, 
                                                            One, 
                                                            EmptyByte, 
                                                            { from: participant });

                //Check the event
                await expectEvent.inTransaction(
                    receipt.tx,
                    this.sale,
                    'Purchase',
                    {
                        purchaser: participant,
                        recipient: participant,
                        token: this.revv.address,
                        sku: sku,
                        quantity: One,
                        userData: EmptyByte
                    });           

                //Actual price of the token
                const actualPrice = new BN(tokenObject.price).div(new BN('2'));
                const expectedBal = beforePurchaseBal.sub(actualPrice);

                //Check prepaid balance
                const afterPurchaseBal = await this.prepaid.balanceOf(participant);
                afterPurchaseBal.should.be.bignumber.eq(expectedBal);
                
                //Check key balance
                const keyBalance = await this.f1dtCck.balanceOf(participant);
                keyBalance.should.be.bignumber.eq("1");
            }
        });
        
        //TODO: Purchase key with different purchaser and receiptant
        //TODO: Purchase key check more than 1 quantity
        //TODO: Purchase key until out of stock
        //TODO: Purchase key until out of stock and should reject when there are one more purchase
    });
    
    //TODO: WITHDRAW DEPOSIT
});
