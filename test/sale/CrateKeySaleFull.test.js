const { accounts, contract } = require('@openzeppelin/test-environment');
const { BN, expectEvent, expectRevert } = require('@openzeppelin/test-helpers');
const ContractDeployer = require('../helpers/ContractDeployer');
const PrepaidBehavior = require("./PrepaidBehaviors");

const [deployer, operator, operation, anonymous, ...participants] = accounts;
const [participant, participant2, participant3] = participants;

function addSkuBehavior() {
    describe("")
}

describe("scenario", async function () {
    
    before(async function () {
        this.revv = await ContractDeployer.deployREVV({from: deployer});
        this.prepaid = await ContractDeployer.deployPrepaid({from:deployer});
    });

    describe("Prepaid", function() {
        PrepaidBehavior.beforeDeposit(deployer, operation);

        PrepaidBehavior.userDeposit(participants);
    })
    
    


});
