const { accounts, contract } = require('@openzeppelin/test-environment');
const { BN, expectEvent, expectRevert } = require('@openzeppelin/test-helpers');
const ContractDeployer = require('../helpers/ContractDeployer');
const PrepaidBehavior = require('./PrepaidBehaviors');
const TokenBehavior = require("./TokenBehaviors");
const SaleBehaviour = require('./SaleBehaviours')

const [deployer, operator, operation, holder, purchaser, anonymous, ...participants] = accounts;

describe("scenario", async function () {
    
    before(async function () {
        this.revv = await ContractDeployer.deployREVV({from: deployer});
        this.prepaid = await ContractDeployer.deployPrepaid({from: deployer});

        //CrateKey Tokens
        const tokens = await ContractDeployer.deployCrateKeyTokens({from: deployer}, holder);
        this.f1dtCck = tokens.F1DT_CCK;
        this.f1dtRck = tokens.F1DT_RCK;
        this.f1dtEck = tokens.F1DT_ECK;
        this.f1dtLck = tokens.F1DT_LCK;

        //CrateKey Sale
        this.sale = await ContractDeployer.deployCrateKeySale({from: deployer});
    });

    describe("Prepaid", function() {
        /**        DEPLOY AND UNPAUSE PREPAID CONTRACT            */
        PrepaidBehavior.beforeDeposit(deployer, operation);

        /**        USERS DEPOSIT DURING PREPAID PERIOD (BEFORE SALE START)            */
        PrepaidBehavior.userDeposit(participants);

        /**        PAUSE DEPOSIT        */
        PrepaidBehavior.pauseDeposit(participants, operation);

        /**        UNPAUSE DEPOSIT        */
        PrepaidBehavior.unpauseDeposit(participants, operation);        
    });

    describe("Token", function() {
        /**        CREATE TOKENS            */
        TokenBehavior.createCrateKeyTokens(holder);

        /**        CREATE SKUs, SET PRICE AND START SALE          */
        SaleBehaviour.createCrateKeySku(deployer, operation, holder, purchaser);
    });

    describe("Prepaid", function() {
        /**        PURCHASE ITEMS ON SALE          */
    });
});
