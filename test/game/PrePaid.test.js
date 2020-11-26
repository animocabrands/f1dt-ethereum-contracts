const {accounts, contract} = require('@openzeppelin/test-environment');
const {BN, expectRevert, expectEvent} = require('@openzeppelin/test-helpers');
const {toWei} = require('web3-utils');
const {ZeroAddress, Zero, One, Two} = require('@animoca/ethereum-contracts-core_library').constants;

const PrePaid = contract.fromArtifact('PrePaid');
const REVV = contract.fromArtifact('REVV');

const [deployer, operator, anonymous, ...participants] = accounts;
const [participant, participant2, participant3] = participants;

describe('PrePaid', function () {
    async function doDeploy(overrides = {}) {
        this.revv = await REVV.new(overrides.holders || [participant], overrides.amounts || [toWei('100000000')], {
            from: overrides.deployer || deployer,
        });

        this.prepaid = await PrePaid.new(this.revv.address, {from: overrides.deployer || deployer});

        await this.prepaid.whitelistOperator(overrides.operator || operator, true, {
            from: overrides.deployer || deployer,
        });
    }

    async function doApproveSpender(overrides = {}) {
        const owners = overrides.owners || participants;
        const spender = overrides.spender || this.prepaid.address;
        const allowances = overrides.allowances || new Array(owners.length).fill(toWei('100000000'));

        for (let index = 0; index < owners.length; ++index) {
            await this.revv.approve(spender, allowances[index], {from: owners[index]});
        }
    }
    describe("coverage", function() {
        describe('constructor()', function () {
            it('should revert with a zero address for the revv contract', async function () {
                await expectRevert(PrePaid.new(ZeroAddress, {from: deployer}), 'PrePaid: zero address');
            });

            it('should deploy with correct parameters', async function () {
                this.revv = await REVV.new([participant], [toWei('1000000')], {from: deployer});
                PrePaid.new(this.revv.address, {from: deployer});
            });
        });

        describe('deposit()', function () {
            beforeEach(async function () {
                this.revvMaxSupply = Two.pow(new BN(256)).sub(One);
                await doDeploy.bind(this)({
                    holders: [participant],
                    amounts: [this.revvMaxSupply],
                });
                await doApproveSpender.bind(this)({
                    owners: [participant],
                    allowances: [this.revvMaxSupply],
                });
                await this.prepaid.unpause({from: deployer});
            });

            it('should revert if the contract is paused', async function () {
                await this.prepaid.pause({from: deployer});
                const revert = this.prepaid.deposit(toWei('100'), {from: participant});
                await expectRevert(revert, 'Pausable: paused');
            });

            it('should revert if the sale has started', async function () {
                await this.prepaid.setSaleStart({from: operator});
                const revert = this.prepaid.deposit(toWei('100'), {from: participant});
                await expectRevert(revert, 'PrePaid: state locked');
            });

            it('should revert if the sale has ended', async function () {
                await this.prepaid.setSaleEnd({from: operator});
                const revert = this.prepaid.deposit(toWei('100'), {from: participant});
                await expectRevert(revert, 'PrePaid: state locked');
            });

            it('should revert if the deposit amount is zero', async function () {
                const revert = this.prepaid.deposit(Zero, {from: participant});
                await expectRevert(revert, 'PrePaid: zero deposit');
            });

            it('should revert if the updated global deposit balance overflows', async function () {
                await this.prepaid.deposit(this.revvMaxSupply, {from: participant});
                const revert = this.prepaid.deposit(this.revvMaxSupply, {from: participant});
                await expectRevert(revert, 'SafeMath: addition overflow');
            });

            it('should revert if the deposit transfer from the sender fails', async function () {
                await doApproveSpender.bind(this)({
                    owners: [participant],
                    allowances: [Zero],
                });
                const revert = this.prepaid.deposit(toWei('100'), {from: participant});
                await expectRevert.unspecified(revert);
            });
        });

        describe('withdraw()', function () {
            beforeEach(async function () {
                await doDeploy.bind(this)({
                    holders: [participant],
                    amounts: [toWei('1000000')],
                });
                await doApproveSpender.bind(this)({
                    owners: [participant],
                    allowances: [toWei('1000000')],
                });
                await this.prepaid.unpause({from: deployer});
                await this.prepaid.deposit(toWei('100'), {from: participant});
                await this.prepaid.setSaleEnd({from: operator});
            });

            it('should revert if the sale has not ended', async function () {
                await this.prepaid.setSaleStart({from: operator});
                const revert = this.prepaid.withdraw({from: participant});
                await expectRevert(revert, 'PrePaid: state locked');
            });

            it('should revert if the sender has no balance to withdraw from', async function () {
                const revert = this.prepaid.withdraw({from: participant2});
                await expectRevert(revert, 'PrePaid: no balance');
            });
        });

        describe('consume()', function () {
            beforeEach(async function () {
                await doDeploy.bind(this)({
                    holders: [participant],
                    amounts: [toWei('1000000')],
                });
                await doApproveSpender.bind(this)({
                    owners: [participant],
                    allowances: [toWei('1000000')],
                });
                await this.prepaid.unpause({from: deployer});
                await this.prepaid.deposit(toWei('100'), {from: participant});
                await this.prepaid.setSaleStart({from: operator});
            });

            it('should revert if the contract is paused', async function () {
                await this.prepaid.pause({from: deployer});
                const revert = this.prepaid.consume(participant, toWei('100'), {from: operator});
                await expectRevert(revert, 'Pausable: paused');
            });

            it('should revert if the sale has not started', async function () {
                await this.prepaid.setSaleState(1, {from: deployer});
                const revert = this.prepaid.consume(participant, toWei('100'), {from: operator});
                await expectRevert(revert, 'PrePaid: state locked');
            });

            it('should revert if the sale has ended', async function () {
                await this.prepaid.setSaleEnd({from: operator});
                const revert = this.prepaid.consume(participant, toWei('100'), {from: operator});
                await expectRevert(revert, 'PrePaid: state locked');
            });

            it('should revert if called by any other than a whitelisted operator', async function () {
                const revert = this.prepaid.consume(participant, toWei('100'), {from: participant});
                await expectRevert(revert, 'PrePaid: invalid operator');
            });

            it('should revert if the consumption amount is zero', async function () {
                const revert = this.prepaid.consume(participant, Zero, {from: operator});
                await expectRevert(revert, 'PrePaid: zero consumption');
            });

            it('should revert if the given wallet has an insufficient balance to deduct the specified amount from', async function () {
                const revert = this.prepaid.consume(participant2, toWei('100'), {from: operator});
                await expectRevert(revert, 'PrePaid: insufficient funds');
            });
        });

        describe('collectRevenue()', function () {
            beforeEach(async function () {
                await doDeploy.bind(this)({
                    holders: [participant],
                    amounts: [toWei('1000000')],
                });
                await doApproveSpender.bind(this)({
                    owners: [participant],
                    allowances: [toWei('1000000')],
                });
                await this.prepaid.unpause({from: deployer});
                await this.prepaid.deposit(toWei('100'), {from: participant});
                await this.prepaid.setSaleStart({from: operator});
                await this.prepaid.consume(participant, toWei('100'), {from: operator});
                await this.prepaid.setSaleEnd({from: operator});
            });

            it('reverts if the sale has not ended', async function () {
                await this.prepaid.setSaleStart({from: operator});
                const revert = this.prepaid.collectRevenue({from: deployer});
                await expectRevert(revert, 'PrePaid: state locked');
            });

            it('reverts if called by any other than the contract owner', async function () {
                const revert = this.prepaid.collectRevenue({from: participant});
                await expectRevert(revert, 'Ownable: caller is not the owner');
            });

            it('reverts if the global earnings balance is zero', async function () {
                await this.prepaid.collectRevenue({from: deployer});
                const revert = this.prepaid.collectRevenue({from: deployer});
                await expectRevert(revert, 'PrePaid: no earnings');
            });
        });

        describe('setSaleState()', function () {
            beforeEach(async function () {
                await doDeploy.bind(this)();
            });

            it('reverts if called by any other than the contract owner', async function () {
                const revert = this.prepaid.setSaleState(2, {from: participant});
                await expectRevert(revert, 'Ownable: caller is not the owner');
            });

            it('reverts if the state is already', async function () {
                const revert = this.prepaid.setSaleState(0, {from: deployer});
                await expectRevert(revert, 'PrePaid: invalid state');
            });

            it('reverts if the current state is already set', async function () {
                const revert = this.prepaid.setSaleState(1, {from: deployer});
                await expectRevert(revert, 'PrePaid: state already set');
            });

            it('can set state BEFORE_SALE_STATE', async function () {
                await expectEvent(await this.prepaid.setSaleState('1', {from: deployer}), 'StateChanged', {state: '1'});
                (await this.prepaid.state()).should.be.bignumber.equal('1');
            });
    
            it('can set state SALE_START_STATE', async function () {
                await expectEvent(await this.prepaid.setSaleState('2', {from: deployer}), 'StateChanged', {state: '2'});
                (await this.prepaid.state()).should.be.bignumber.equal('2');
            });
    
            it('can set state SALE_END_STATE', async function () {
                await expectEvent(await this.prepaid.setSaleState('3', {from: deployer}), 'StateChanged', {state: '3'});
                (await this.prepaid.state()).should.be.bignumber.equal('3');
            });
    
            it('revert if unknown state', async function () {
                const revert = this.prepaid.setSaleState('0', {from: deployer});
                await expectRevert(revert, 'PrePaid: invalid state');
            });
    
            it('revert if not owner', async function () {
                const revert = this.prepaid.setSaleState(0, {from: anonymous});
                await expectRevert(revert, 'Ownable: caller is not the owner');
                const revert2 = this.prepaid.setSaleState(0, {from: participant});
                await expectRevert(revert2, 'Ownable: caller is not the owner');
            });
        });

        describe('setSaleStart()', function () {
            beforeEach(async function () {
                await doDeploy.bind(this)();
            });

            it('reverts if called by any other than a whitelisted operator', async function () {
                const revert = this.prepaid.setSaleStart({from: participant});
                await expectRevert(revert, 'PrePaid: invalid operator');
            });

            it('reverts if the current state is already set', async function () {
                await this.prepaid.setSaleStart({from: operator});
                const revert = this.prepaid.setSaleStart({from: operator});
                await expectRevert(revert, 'PrePaid: state already set');
            });
        });

        describe('setSaleEnd()', function () {
            beforeEach(async function () {
                await doDeploy.bind(this)({
                    holders: [participant],
                    amounts: [toWei('1000000')],
                });
            });

            it('reverts if called by any other than a whitelisted operator', async function () {
                const revert = this.prepaid.setSaleEnd({from: participant});
                await expectRevert(revert, 'PrePaid: invalid operator');
            });

            it('reverts if the current state is already set', async function () {
                await this.prepaid.setSaleEnd({from: operator});
                const revert = this.prepaid.setSaleEnd({from: operator});
                await expectRevert(revert, 'PrePaid: state already set');
            });
        });

        describe('pause()', function () {
            beforeEach(async function () {
                await doDeploy.bind(this)();
            });

            it('reverts if called by any other than the contract owner', async function () {
                const revert = this.prepaid.pause({from: participant});
                await expectRevert(revert, 'Ownable: caller is not the owner');
            });

            it('reverts if the contract is already paused', async function () {
                const revert = this.prepaid.pause({from: deployer});
                await expectRevert(revert, 'Pausable: paused');
            });
        });

        describe('unpause()', function () {
            beforeEach(async function () {
                await doDeploy.bind(this)();
                await this.prepaid.unpause({from: deployer});
            });

            it('reverts if called by any other than the contract owner', async function () {
                const revert = this.prepaid.unpause({from: participant});
                await expectRevert(revert, 'Ownable: caller is not the owner');
            });

            it('reverts if the contract is already unpaused', async function () {
                const revert = this.prepaid.unpause({from: deployer});
                await expectRevert(revert, 'Pausable: not paused');
            });
        });
    });

    describe('discount', function () {

        beforeEach(async function () {
            await doDeploy.bind(this)({
                holders: [participant],
                amounts: [toWei('1000000')],
            });
            await doApproveSpender.bind(this)({
                owners: [participant],
                allowances: [toWei('1000000')],
            });
        });

        it('should default to 0% discount', async function () {
            (await this.prepaid.getDiscount()).should.be.bignumber.equal('0');
        });
    });

    describe('contract', function () {
        beforeEach(async function () {
            await doDeploy.bind(this)({
                holders: participants,
                amounts: new Array(participants.length).fill(toWei('100000000')),
            });
            await doApproveSpender.bind(this)({
                owners: [participant, participant2],
                allowances: new Array(2).fill(toWei('100000000')),
            });
        });

        describe('beforeSales', function () {
            // Contract unpaused and beforeSales Starts
            beforeEach(async function () {
                await this.prepaid.unpause({from: deployer});
            });

            it('state is BEFORE_SALE_STATE', async function () {
                const state = await this.prepaid.BEFORE_SALE_STATE();
                (await this.prepaid.state()).should.be.bignumber.equal(state);
            });

            it('deposit(1revv) will send revv to contract', async function () {
                (await this.revv.balanceOf(participant)).should.be.bignumber.equal(toWei('100000000'));
                (await this.revv.balanceOf(this.prepaid.address)).should.be.bignumber.equal(toWei('0'));
                await this.prepaid.deposit(toWei('100000000'), {from: participant});
                (await this.revv.balanceOf(participant)).should.be.bignumber.equal(toWei('0'));
                (await this.revv.balanceOf(this.prepaid.address)).should.be.bignumber.equal(toWei('100000000'));
            });

            it('deposit(1revv)', async function () {
                const receipt = await this.prepaid.deposit(toWei('1'), {from: participant});
                await expectEvent(receipt, 'Deposited', {wallet: participant, amount: toWei('1')});
                (await this.prepaid.balanceOf(participant)).should.be.bignumber.equal(toWei('1'));
                (await this.prepaid.globalDeposit()).should.be.bignumber.equal(toWei('1'));
                (await this.prepaid.getDiscount()).should.be.bignumber.equal('0');
            });

            it('deposit(1revv) X 3', async function () {
                const receipt = await this.prepaid.deposit(toWei('1'), {from: participant});
                const receipt1 = await this.prepaid.deposit(toWei('1'), {from: participant});
                const receipt2 = await this.prepaid.deposit(toWei('1'), {from: participant});
                await expectEvent(receipt, 'Deposited', {wallet: participant, amount: toWei('1')});
                await expectEvent(receipt1, 'Deposited', {wallet: participant, amount: toWei('1')});
                await expectEvent(receipt2, 'Deposited', {wallet: participant, amount: toWei('1')});
                (await this.prepaid.balanceOf(participant)).should.be.bignumber.equal(toWei('3'));
                (await this.prepaid.globalDeposit()).should.be.bignumber.equal(toWei('3'));
                (await this.prepaid.getDiscount()).should.be.bignumber.equal('0');
            });

            it('deposit(100revv) from various participant', async function () {
                const receipt = await this.prepaid.deposit(toWei('100'), {from: participant});
                const receipt1 = await this.prepaid.deposit(toWei('100'), {from: participant2});
                const receipt2 = await this.prepaid.deposit(toWei('100'), {from: participant2});
                await expectEvent(receipt, 'Deposited', {wallet: participant, amount: toWei('100')});
                await expectEvent(receipt1, 'Deposited', {wallet: participant2, amount: toWei('100')});
                await expectEvent(receipt2, 'Deposited', {wallet: participant2, amount: toWei('100')});
                (await this.prepaid.balanceOf(participant)).should.be.bignumber.equal(toWei('100'));
                (await this.prepaid.balanceOf(participant2)).should.be.bignumber.equal(toWei('200'));
                (await this.prepaid.globalDeposit()).should.be.bignumber.equal(toWei('300'));
                (await this.prepaid.getDiscount()).should.be.bignumber.equal('0');
            });

            it('deposit(20M REVV) with 10% discount', async function () {
                await this.prepaid.deposit(toWei('20000000'), {from: participant});
                (await this.prepaid.getDiscount()).should.be.bignumber.equal('10');
            });

            it('deposit(30M REVV) with 25% discount', async function () {
                await this.prepaid.deposit(toWei('30000000'), {from: participant});
                (await this.prepaid.getDiscount()).should.be.bignumber.equal('25');
            });

            it('deposit(40M REVV) with 50% discount', async function () {
                await this.prepaid.deposit(toWei('40000000'), {from: participant});
                (await this.prepaid.getDiscount()).should.be.bignumber.equal('50');
            });

            it('deposit(50M REVV) with 50% discount', async function () {
                await this.prepaid.deposit(toWei('50000000'), {from: participant});
                (await this.prepaid.getDiscount()).should.be.bignumber.equal('50');
            });

            it('consume should revert', async function () {
                await this.prepaid.deposit(toWei('100'), {from: participant});
                expectRevert(this.prepaid.consume(participant, toWei('1'), {from: operator}), 'PrePaid: state locked');
            });

            it('withdraw should revert', async function () {
                await this.prepaid.deposit(toWei('100'), {from: participant});
                expectRevert(this.prepaid.withdraw({from: participant}), 'PrePaid: state locked');
            });

            it('collectRevenue should revert', async function () {
                expectRevert(this.prepaid.collectRevenue({from: deployer}), 'PrePaid: state locked');
            });
        });

        describe('during sales', function () {
            beforeEach(async function () {
                await this.prepaid.unpause({from: deployer});
                await this.prepaid.deposit(toWei('1000'), {from: participant});
                await this.prepaid.deposit(toWei('1000'), {from: participant2});
                await this.prepaid.setSaleStart({from: operator});
            });

            it('consumes', async function () {
                await this.prepaid.consume(participant, toWei('10'), {from: operator});
                (await this.prepaid.balanceOf(participant)).should.be.bignumber.equal(toWei('990'));
                (await this.prepaid.globalEarnings()).should.be.bignumber.equal(toWei('10'));
                (await this.prepaid.globalDeposit()).should.be.bignumber.equal(toWei('2000'));
            });

            it('consumes various participant', async function () {
                await this.prepaid.consume(participant, toWei('10'), {from: operator});
                await this.prepaid.consume(participant2, toWei('10'), {from: operator});
                (await this.prepaid.balanceOf(participant)).should.be.bignumber.equal(toWei('990'));
                (await this.prepaid.balanceOf(participant2)).should.be.bignumber.equal(toWei('990'));
                (await this.prepaid.globalEarnings()).should.be.bignumber.equal(toWei('20'));
                (await this.prepaid.globalDeposit()).should.be.bignumber.equal(toWei('2000'));
            });

            it('consumes reverts if insufficient funds', async function () {
                const revert = this.prepaid.consume(participant3, toWei('10'), {from: operator});
                expectRevert(revert, 'PrePaid: insufficient funds');
            });

            it('deposit should revert', async function () {
                const revert = this.prepaid.deposit(toWei('1'), {from: participant});
                expectRevert(revert, 'PrePaid: state locked');
            });

            it('withdraw should revert', async function () {
                const revert = this.prepaid.withdraw({from: participant});
                expectRevert(revert, 'PrePaid: state locked');
            });

            it('collectRevenue should revert', async function () {
                expectRevert(this.prepaid.collectRevenue({from: deployer}), 'PrePaid: state locked');
            });
        });

        describe('post sales', function () {
            beforeEach(async function () {
                await this.prepaid.unpause({from: deployer});
                await this.prepaid.deposit(toWei('1000'), {from: participant});
                await this.prepaid.deposit(toWei('1000'), {from: participant2});
                await this.prepaid.setSaleStart({from: operator});
                await this.prepaid.consume(participant2, toWei('10'), {from: operator});
                await this.prepaid.setSaleEnd({from: operator});
            });

            it('deposit should revert', async function () {
                const revert = this.prepaid.deposit(toWei('1'), {from: participant});
                await expectRevert(revert, 'PrePaid: state locked');
            });

            it('withdraw should not revert', async function () {
                (await this.revv.balanceOf(participant)).should.be.bignumber.equal(toWei('99999000'));
                await this.prepaid.withdraw({from: participant});
                (await this.revv.balanceOf(participant)).should.be.bignumber.equal(toWei('100000000'));
                (await this.prepaid.balanceOf(participant)).should.be.bignumber.equal(toWei('0'));
            });

            it('withdraw twice should revert', async function () {
                (await this.revv.balanceOf(participant)).should.be.bignumber.equal(toWei('99999000'));
                await this.prepaid.withdraw({from: participant});
                const revert = this.prepaid.withdraw({from: participant});
                await expectRevert(revert, 'PrePaid: no balance');
                (await this.revv.balanceOf(participant)).should.be.bignumber.equal(toWei('100000000'));
                (await this.prepaid.balanceOf(participant)).should.be.bignumber.equal(toWei('0'));
            });

            it('collectRevenue should revert if called twice', async function () {
                await this.prepaid.collectRevenue({from: deployer});
                const revert = this.prepaid.collectRevenue({from: deployer});
                await expectRevert(revert, 'PrePaid: no earnings');
            });

            it("withdraw all balance", async function() {
                (await this.revv.balanceOf(participant)).should.be.bignumber.equal(toWei('99999000'));
                (await this.revv.balanceOf(deployer)).should.be.bignumber.equal(toWei('0'));
                await this.prepaid.withdraw({from: participant});
                await this.prepaid.withdraw({from: participant2});
                await this.prepaid.collectRevenue({from: deployer});
                (await this.revv.balanceOf(participant)).should.be.bignumber.equal(toWei('99999990'));
                (await this.revv.balanceOf(participant2)).should.be.bignumber.equal(toWei('100000000'));
                (await this.revv.balanceOf(deployer)).should.be.bignumber.equal(toWei('10'));
            });
        });

    });
});
