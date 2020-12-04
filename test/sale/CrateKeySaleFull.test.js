const { accounts, contract } = require('@openzeppelin/test-environment');
const { BN, expectEvent, expectRevert } = require('@openzeppelin/test-helpers');
const ContractDeployer = require('../helpers/ContractDeployer');
const PrepaidBehavior = require('./PrepaidBehaviors');
const TokenBehavior = require("./TokenBehaviors");
const { stringToBytes32 } = require('@animoca/ethereum-contracts-sale_base/test/utils/bytes32');
const { ZeroAddress, Zero, One, Two, EmptyByte} = require('@animoca/ethereum-contracts-core_library').constants;
const { toWei } = require('web3-utils');
const { Four } = require('@animoca/ethereum-contracts-core_library/src/constants');
const TOKENS = ContractDeployer.TOKENS;

const [deployer, operation, accountDept, ...participants] = accounts;
const [participant, participant2, participant3, participant4] = participants;
const maxQuantity = toWei("20");

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
            }
        });

        it("should be able to deliver all keys to the participant", async function() {
            for (const key of Object.values(this.keys))
            {
                const keyBalance = await key.balanceOf(participant);
                keyBalance.should.be.bignumber.eq("1");
            }
        });
        
        it("should be able to purchase a cratekey using different purchaser and receiptant", async function () {
            const tokenObject = TOKENS.F1DT_CCK;
            const sku = stringToBytes32(tokenObject.symbol);
            const beforePurchaseBal = await this.prepaid.balanceOf(participant3);
            const receipt = await this.sale.purchaseFor(participant2, 
                                                        this.revv.address, 
                                                        sku, 
                                                        One, 
                                                        EmptyByte, 
                                                        { from: participant3 });
            //Check the event
            await expectEvent.inTransaction(
                receipt.tx,
                this.sale,
                'Purchase',
                {
                    purchaser: participant3,
                    recipient: participant2,
                    token: this.revv.address,
                    sku: sku,
                    quantity: One,
                    userData: EmptyByte
                });   

            //Actual price of the token
            const actualPrice = new BN(tokenObject.price).div(new BN('2'));
            const expectedBal = beforePurchaseBal.sub(actualPrice);

            //Check prepaid balance
            const afterPurchaseBal = await this.prepaid.balanceOf(participant3);
            afterPurchaseBal.should.be.bignumber.eq(expectedBal);
            
            //Check key balance
            const keyBalance = await this.f1dtCck.balanceOf(participant2);
            keyBalance.should.be.bignumber.eq("1");
        });

        it("should be able to purhcase more than one item", async function () { 
            const tokenObject = TOKENS.F1DT_LCK;
            const sku = stringToBytes32(tokenObject.symbol);
            const quantity = Four;
            const beforePurchaseBal = await this.prepaid.balanceOf(participant3);
            const receipt = await this.sale.purchaseFor(participant2, 
                                                        this.revv.address, 
                                                        sku, 
                                                        quantity, 
                                                        EmptyByte, 
                                                        { from: participant3 });
            //Check the event
            await expectEvent.inTransaction(
                receipt.tx,
                this.sale,
                'Purchase',
                {
                    purchaser: participant3,
                    recipient: participant2,
                    token: this.revv.address,
                    sku: sku,
                    quantity: quantity,
                    userData: EmptyByte
                });   

            //Actual price of the token
            const actualPrice = new BN(tokenObject.price).div(new BN('2'));
            const expectedBal = beforePurchaseBal.sub(actualPrice.mul(quantity));

            //Check prepaid balance
            const afterPurchaseBal = await this.prepaid.balanceOf(participant3);
            afterPurchaseBal.should.be.bignumber.eq(expectedBal);
            
            //Check key balance
            const keyBalance = await this.f1dtCck.balanceOf(participant2);
            keyBalance.should.be.bignumber.eq("1");            
        });

        it("should be able to purhcase until out of stock", async function () { 
            const tokenObject = TOKENS.F1DT_ECK;
            const sku = stringToBytes32(tokenObject.symbol);
            const skuInfo = await this.sale.getSkuInfo(sku, {from: deployer});
            const remainingSupply = skuInfo.totalSupply;

            //Total of purchase operations based on max quantity in order to optimize the test
            let purchaseOperations = remainingSupply.div(new BN(maxQuantity));
                purchaseOperations = purchaseOperations.sub(new BN(1));
            
            for (saleIndex = 0; saleIndex < purchaseOperations; saleIndex++) {
                // console.log(`Purchase item ${saleIndex} of ${purchaseOperations}. Quantity ${maxQuantity}`);    

                const receipt = await this.sale.purchaseFor(participant2, 
                                                            this.revv.address, 
                                                            sku, 
                                                            maxQuantity, 
                                                            EmptyByte, 
                                                            { from: participant3 });
                //Check the event
                await expectEvent.inTransaction(
                    receipt.tx,
                    this.sale,
                    'Purchase',
                    {
                        purchaser: participant3,
                        recipient: participant2,
                        token: this.revv.address,
                        sku: sku,
                        quantity: maxQuantity,
                        userData: EmptyByte
                    });  
            }
        });

        it("should be able to purhcase until out of stock and should reject when there are one more purchase", async function () { 
            //WIP
            
            // await expectRevert(this.sale.purchaseFor(participant2, 
            //                                         this.revv.address, 
            //                                         sku, 
            //                                         One, 
            //                                         EmptyByte, 
            //                                         { from: participant3 }),
            //                     'Sale: insufficient supply');
        });
        
        //TODO: check delivery operation 
    });

    // TODO: END sales
    describe("Sales(End)", function(){
        // TODO: purchase should revert after sales end
        PrepaidBehavior.endSales();

        describe("user withdraw after sales end", function(){
            PrepaidBehavior.withdraws({
                [participant]: {
                    name : "participant",
                    amount : toWei("10")
                },
            });
        });


        describe("user withdraw after transfer ownership", function(){

            it('transfer ownership', async function () {
                const receipt = await this.prepaid.transferOwnership(accountDept, {from: deployer});
                await expectEvent(receipt, 'OwnershipTransferred', {previousOwner: deployer, newOwner: accountDept});
            });

            // PrepaidBehavior.withdraws({
            //     [participant2]: {
            //         name : "participant2",
            //         amount : toWei("10")
            //     }
            // });

        });
        
        PrepaidBehavior.collectRevenue(accountDept, toWei("100"));

        describe.skip("user withdraw with zero deposit should revert", function() {
            //todo
        });

        describe("user withdraw after collect revenue", function() {
            PrepaidBehavior.withdraws({
                [participant4]: {
                    name : "participant4",
                    amount : toWei("10")
                },
            });
        });
        
    });

    
});
