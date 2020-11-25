const { accounts, contract } = require('@openzeppelin/test-environment');
const { expectRevert, expectEvent } = require('@openzeppelin/test-helpers');
const { toWei } = require('web3-utils');
const { ZeroAddress } = require('@animoca/ethereum-contracts-core_library').constants;

const PrePaid = contract.fromArtifact('PrePaid');
const REVV = contract.fromArtifact('REVV');

const [ deployer, operator, anonymous, ...participants ] = accounts;
const [participant, participant2] = participants;

describe('PrePaid', function () {

    async function doDeploy(overrides = {}) {
        this.revv = await REVV.new(
            overrides.holders || [ participant ],
            overrides.amounts || [ toWei('1000000') ],
            { from: overrides.deployer || deployer });

        this.contract = await PrePaid.new(
            this.revv.address,
            { from: overrides.deployer || deployer });
    }

    describe('constructor()', function () {

        it('should revert with a zero address for the revv contract', async function () {
            await expectRevert(
                PrePaid.new(
                    ZeroAddress,
                    {from: deployer}
                ),
                'PrePaid: zero address'
            );
        });

        it('should deploy with correct parameters', async function () {
            this.revv = await REVV.new([participant], [toWei('1000000')], {from: deployer});
            PrePaid.new(
                this.revv.address,
                {from: deployer}
            );
        });

    });

    describe("contract", function() {
        beforeEach(async function() {
            const revvAmount = new Array(participants.length);
            revvAmount.fill(toWei('1000000'));
            this.revv = await REVV.new(participants, revvAmount, {from: deployer});
            this.prepaid = await PrePaid.new(this.revv.address, {from: deployer});
            this.prepaid.whitelistOperator( operator, true ,{from:deployer});
            // approval revv token to prepaid contract
            await this.revv.approve(this.prepaid.address, toWei('1000000'), {from: participant});
            await this.revv.approve(this.prepaid.address, toWei('1000000'), {from: participant2});
        });

        describe("setSaleState", function() {

            it("can set state BEFORE_SALE_STATE", async function() {
                await expectEvent(await this.prepaid.setSaleState('0', {from: deployer}), "StateChange", {state : "0"});
                (await this.prepaid.state()).should.be.bignumber.equal("0");
            });

            it("can set state SALE_START_STATE", async function() {
                await expectEvent(await this.prepaid.setSaleState('1', {from: deployer}), "StateChange", {state : "1"});
                (await this.prepaid.state()).should.be.bignumber.equal("1");
            });

            it("can set state SALE_END_STATE", async function() {
                await expectEvent(await this.prepaid.setSaleState('2', {from: deployer}), "StateChange", {state : "2"});
                (await this.prepaid.state()).should.be.bignumber.equal("2");
            });

            it("revert if unknown state", async function() {
                const revert = this.prepaid.setSaleState('3', {from: deployer});
                await expectRevert(revert, 'PrePaid: invalid state');
            });

            it("revert if not owner", async function() {
                const revert = this.prepaid.setSaleState(0, {from: anonymous});
                await expectRevert(revert, "Ownable: caller is not the owner");
                const revert2 = this.prepaid.setSaleState(0, {from: participant});
                await expectRevert(revert2, "Ownable: caller is not the owner");
            });

        });

        describe("unpaused beforeSales", function() {
            // Contract unpaused and beforeSales Starts
            beforeEach(async function() {
                await this.prepaid.unpause({from: deployer});
            });

            it("state is BEFORE_SALE_STATE", async function() {
                const state = (await this.prepaid.BEFORE_SALE_STATE());
                (await this.prepaid.state()).should.be.bignumber.equal(state);
            });
            
            it("deposit(1revv)", async function(){
                const receipt = await this.prepaid.deposit(toWei('1'), {from: participant});
                await expectEvent(receipt, "Deposited", {wallet: participant,amount: toWei('1')});
                (await this.prepaid.balanceOf(participant)).should.be.bignumber.equal(toWei('1'));
                (await this.prepaid.globalDeposit()).should.be.bignumber.equal(toWei('1'));
            });
    
            it("deposit(1revv) X 3", async function(){
                const receipt = await this.prepaid.deposit(toWei('1'), {from: participant});
                const receipt1 = await this.prepaid.deposit(toWei('1'), {from: participant});
                const receipt2 = await this.prepaid.deposit(toWei('1'), {from: participant});
                await expectEvent(receipt, "Deposited", {wallet: participant,amount: toWei('1')});
                await expectEvent(receipt1, "Deposited", {wallet: participant,amount: toWei('1')});
                await expectEvent(receipt2, "Deposited", {wallet: participant,amount: toWei('1')});
                (await this.prepaid.balanceOf(participant)).should.be.bignumber.equal(toWei('3'));
                (await this.prepaid.globalDeposit()).should.be.bignumber.equal(toWei('3'));
            });
    
            it("deposit(100revv) from different participant", async function(){
                const receipt = await this.prepaid.deposit(toWei('100'), {from: participant});
                const receipt1 = await this.prepaid.deposit(toWei('100'), {from: participant2});
                const receipt2 = await this.prepaid.deposit(toWei('100'), {from: participant2});
                await expectEvent(receipt, "Deposited", {wallet: participant,amount: toWei('100')});
                await expectEvent(receipt1, "Deposited", {wallet: participant2,amount: toWei('100')});
                await expectEvent(receipt2, "Deposited", {wallet: participant2,amount: toWei('100')});
                (await this.prepaid.balanceOf(participant)).should.be.bignumber.equal(toWei('100'));
                (await this.prepaid.balanceOf(participant2)).should.be.bignumber.equal(toWei('200'));
                (await this.prepaid.globalDeposit()).should.be.bignumber.equal(toWei('300'));
            });

            it("consume should revert", async function() {
                await this.prepaid.deposit(toWei('100'), {from: participant});
                expectRevert(this.prepaid.consume(participant, toWei('1'), {from: deployer}), "PrePaid: state locked");
            });

            it("withdraw should revert", async function() {
                await this.prepaid.deposit(toWei('100'), {from: participant});
                expectRevert(this.prepaid.withdraw({from: deployer}), "PrePaid: state locked");
            });

            it("collectRevenue should revert", async function() {
                expectRevert(this.prepaid.collectRevenue({from: deployer}), "PrePaid: state locked");
            });
        });
        
        describe("during sales", function() {
            beforeEach(async function() {
                await this.prepaid.unpause({from: deployer});
                await this.prepaid.deposit(toWei('1000'), {from: participant});
                await this.prepaid.setSaleState('1', {from: deployer});
            });

            it.skip("consumes", async function() {

            })

            it("deposit should revert", async function(){
                const revert = this.prepaid.deposit(toWei('1'), {from: participant});
                await expectRevert(revert, "PrePaid: state locked");
            });

            it("withdraw should revert", async function() {
                const revert = this.prepaid.withdraw({from: deployer});
                expectRevert(revert, "PrePaid: state locked");
            });


            it("collectRevenue should revert", async function() {
                expectRevert(this.prepaid.collectRevenue({from: deployer}), "PrePaid: state locked");
            });

        });

    });

});
