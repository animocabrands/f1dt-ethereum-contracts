const { accounts, contract } = require('@openzeppelin/test-environment');
const { expectRevert, expectEvent } = require('@openzeppelin/test-helpers');
const { toWei } = require('web3-utils');
const { ZeroAddress } = require('@animoca/ethereum-contracts-core_library').constants;

const PrePaid = contract.fromArtifact('PrePaid');
const REVV = contract.fromArtifact('REVV');

const [ deployer, ...participants ] = accounts;
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

    describe("deposit(amount)", function() {
        
        beforeEach(async function() {
            const revvAmount = new Array(participants.length);
            revvAmount.fill(toWei('1000000'));
            this.revv = await REVV.new(participants, revvAmount, {from: deployer});
            this.prepaid = await PrePaid.new(this.revv.address, {from: deployer});
            await this.prepaid.unpause({from: deployer});
            // approval revv token to prepaid contract
            await this.revv.approve(this.prepaid.address, toWei('1000000'), {from: participant});
            await this.revv.approve(this.prepaid.address, toWei('1000000'), {from: participant2});
        });

        it("deposit(1revv)", async function(){
            const receipt = await this.prepaid.deposit(toWei('1'), {from: participant});
            await expectEvent(receipt, "Deposited", {
                wallet: participant,
                amount: toWei('1'),
            });
            (await this.prepaid.balanceOf(participant)).should.be.bignumber.equal(toWei('1'));
            (await this.prepaid.globalDeposit()).should.be.bignumber.equal(toWei('1'));
        });

        it("deposit(1revv) X 3", async function(){
            const receipt = await this.prepaid.deposit(toWei('1'), {from: participant});
            const receipt1 = await this.prepaid.deposit(toWei('1'), {from: participant});
            const receipt2 = await this.prepaid.deposit(toWei('1'), {from: participant});
            await expectEvent(receipt, "Deposited", {
                wallet: participant,
                amount: toWei('1'),
            });
            await expectEvent(receipt1, "Deposited", {
                wallet: participant,
                amount: toWei('1'),
            });
            await expectEvent(receipt2, "Deposited", {
                wallet: participant,
                amount: toWei('1'),
            });
            (await this.prepaid.balanceOf(participant)).should.be.bignumber.equal(toWei('3'));
            (await this.prepaid.globalDeposit()).should.be.bignumber.equal(toWei('3'));
        });

        it("deposit(100revv) from different participant", async function(){
            const receipt = await this.prepaid.deposit(toWei('100'), {from: participant});
            const receipt1 = await this.prepaid.deposit(toWei('100'), {from: participant2});
            const receipt2 = await this.prepaid.deposit(toWei('100'), {from: participant2});
            await expectEvent(receipt, "Deposited", {
                wallet: participant,
                amount: toWei('100'),
            });
            await expectEvent(receipt1, "Deposited", {
                wallet: participant2,
                amount: toWei('100'),
            });
            await expectEvent(receipt2, "Deposited", {
                wallet: participant2,
                amount: toWei('100'),
            });
            (await this.prepaid.balanceOf(participant)).should.be.bignumber.equal(toWei('100'));
            (await this.prepaid.balanceOf(participant2)).should.be.bignumber.equal(toWei('200'));
            (await this.prepaid.globalDeposit()).should.be.bignumber.equal(toWei('300'));
        });

        it("should revert when paused", async function(){
            await this.prepaid.pause({from: deployer});
            const promiseResult = this.prepaid.deposit(toWei('1'), {from: participant});
            await expectRevert(promiseResult,'Pausable: paused');
        })

        it("should revert if the salesStart", async function() {
            await this.prepaid.setStartSale(true,{from: deployer});
            const promiseResult = this.prepaid.deposit(toWei('1'), {from: participant});
            await expectRevert(promiseResult,'PrePaid: sale started');
        });

        it("should revert if the salesEnd", async function() {
            await this.prepaid.setEndSale(true,{from: deployer});
            const promiseResult = this.prepaid.deposit(toWei('1'), {from: participant});
            await expectRevert(promiseResult,'PrePaid: sale ended');
        });

    });

});
