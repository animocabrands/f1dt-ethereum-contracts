const { accounts, contract } = require('@openzeppelin/test-environment');
const { BN, expectEvent, expectRevert } = require('@openzeppelin/test-helpers');
const ContractDeployer = require('../helpers/ContractDeployer');
const PrepaidBehavior = require("./PrepaidBehaviors");
const TokenBehavior = require("./TokenBehaviors");

const [deployer, operator, operation, holder, anonymous, ...participants] = accounts;
const [participant, participant2, participant3] = participants;

function addSkuBehavior() {
    describe("")
}

describe("scenario", async function () {
    
    before(async function () {
        this.revv = await ContractDeployer.deployREVV({from: deployer});
        this.prepaid = await ContractDeployer.deployPrepaid();
        //Tokens
        const tokens = await ContractDeployer.deployCrateKeyTokens({from: deployer}, holder);
        this.f1dtCck = tokens.F1DT_CCK;
        this.f1dtRck = tokens.F1DT_RCK;
        this.f1dtEck = tokens.F1DT_ECK;
        this.f1dtLck = tokens.F1DT_LCK;
    });

    describe("Prepaid", function() {
        /**        DEPLOY AND UNPAUSE PREPAID CONTRACT            */
        //1. this.prepaid.transferOwnership
        //2. this.prepaid.unpause
        PrepaidBehavior.beforeDeposit(deployer, operation);

        /**        USERS DEPOSIT DURING PREPAID PERIOD (BEFORE SALE START)            */
        PrepaidBehavior.userDeposit(participants);

        /**        DEPLOY CRATE TOKENS            */
        TokenBehavior.createCrateKeyTokens(holder);
    });

});
