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

        // //CrateKey Tokens
        const tokens = await ContractDeployer.deployCrateKeyTokens({ from: deployer }, operation);
        this.f1dtCck = tokens.F1DT_CCK;
        this.f1dtRck = tokens.F1DT_RCK;
        this.f1dtEck = tokens.F1DT_ECK;
        this.f1dtLck = tokens.F1DT_LCK;

        // //CrateKey Sale
        this.sale = await ContractDeployer.deployCrateKeySale({ from: deployer });
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
        TokenBehavior.createCrateKeyTokens(operation);

        SaleBehaviour.createCrateKeySku(deployer, operation);
    })


    // /**        CREATE SKUs          */
    
    describe("Prepaid", function () {
        before(function () {
            this.whitelistOperator = this.sale.address;
        })

        PrepaidBehavior.addWhiteListedOperator();
    });
    
    /**        START SALE          */
    describe("Sales start", function () {
        it("should start sales", async function () {
            const receipt = (await this.sale.start({ from: deployer }));
            await expectEvent(receipt, "Started", { account: deployer });
        });
    });

    /**        BUY ITEMS          */

    describe("Prepaid", function () {
        /**        PURCHASE ITEMS ON SALE          */
    });
});
