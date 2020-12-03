const { accounts, contract } = require('@openzeppelin/test-environment');
const { BN, expectEvent, expectRevert } = require('@openzeppelin/test-helpers');
const ContractDeployer = require('../helpers/ContractDeployer');
const PrepaidBehavior = require('./PrepaidBehaviors');
const TokenBehavior = require("./TokenBehaviors");
const SaleBehaviour = require('./SaleBehaviours')

const [deployer, operation, anonymous, ...participants] = accounts;
const [participant, participant2, participant3] = participants;

describe("scenario", async function () {

    before(async function () {
        this.revv = await ContractDeployer.deployREVV({ from: deployer });

        this.prepaid = await ContractDeployer.deployPrepaid({ from: deployer });

        // //CrateKey Sale
        this.sale = await ContractDeployer.deployCrateKeySale({ from: deployer });

        this.keys = await ContractDeployer.deployCrateKeyTokens({ from: deployer }, operation);
        const {F1DT_CCK,F1DT_RCK, F1DT_ECK, F1DT_LCK } = this.keys;
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

        SaleBehaviour.createCrateKeySku();
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
        it("prepaid should switch to start state", async function() {
            const startState = (await this.prepaid.SALE_START_STATE());
            (await this.prepaid.state()).should.be.bignumber.eq(startState);
        });
    });

    /**        BUY ITEMS          */

    describe("Purchase", function () {
        /**        PURCHASE ITEMS ON SALE          */
        

    });
});
