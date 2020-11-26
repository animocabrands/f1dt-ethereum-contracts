const {accounts, contract} = require('@openzeppelin/test-environment');
const {BN, expectRevert, expectEvent} = require('@openzeppelin/test-helpers');
const {toWei} = require('web3-utils');
const {ZeroAddress, Zero, One, Two} = require('@animoca/ethereum-contracts-core_library').constants;

const PrePaid = contract.fromArtifact('PrePaid');
const REVV = contract.fromArtifact('REVV');

const [deployer, operator, operation, anonymous, ...participants] = accounts;
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
    describe('coverage', function () {
        describe('constructor()', function () {
            it('should revert with a zero address for the revv contract', async function () {
                await expectRevert(PrePaid.new(ZeroAddress, {from: deployer}), 'PrePaid: zero address');
            });

            it('should deploy with correct parameters', async function () {
                await doDeploy.bind(this)();
            });

            it('should assign the REVV contract component', async function () {
                await doDeploy.bind(this)();
                const actual = await this.prepaid.revv();
                actual.should.equal(this.revv.address);
            });

            it('should pause the contract', async function () {
                await doDeploy.bind(this)();
                const actual = await this.prepaid.paused();
                actual.should.be.true;
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

            it('should correctly update the global deposit amount', async function () {
                const amount = Two;
                const before = await this.prepaid.globalDeposit();
                const expected = before.add(amount);
                await this.prepaid.deposit(amount, {from: participant});
                const actual = await this.prepaid.globalDeposit();
                actual.should.be.bignumber.equal(expected);
            });

            it("should correctly update the sender's escrow balance", async function () {
                const amount = Two;
                const before = await this.prepaid.balanceOf(participant);
                const expected = before.add(amount);
                await this.prepaid.deposit(amount, {from: participant});
                const actual = await this.prepaid.balanceOf(participant);
                actual.should.be.bignumber.equal(expected);
            });

            it('should correctly transfer escrow amount from the sender', async function () {
                const amount = Two;
                const prepaidBalance = await this.revv.balanceOf(this.prepaid.address);
                const senderBalance = await this.revv.balanceOf(participant);
                const prepaidExpected = prepaidBalance.add(amount);
                const senderExpected = senderBalance.sub(amount);
                await this.prepaid.deposit(amount, {from: participant});
                const prepaidActual = await this.revv.balanceOf(this.prepaid.address);
                const senderActual = await this.revv.balanceOf(participant);
                prepaidActual.should.be.bignumber.equal(prepaidExpected);
                senderActual.should.be.bignumber.equal(senderExpected);
            });

            it('should emit the Deposited event', async function () {
                const amount = Two;
                const receipt = await this.prepaid.deposit(amount, {from: participant});
                expectEvent(receipt, 'Deposited', {
                    wallet: participant,
                    amount: amount,
                });
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

            it('should correctly transfer escrow balance to the sender', async function () {
                const amount = await this.prepaid.balanceOf(participant);
                const prepaidBalance = await this.revv.balanceOf(this.prepaid.address);
                const senderBalance = await this.revv.balanceOf(participant);
                const prepaidExpected = prepaidBalance.sub(amount);
                const senderExpected = senderBalance.add(amount);
                await this.prepaid.withdraw({from: participant});
                const prepaidActual = await this.revv.balanceOf(this.prepaid.address);
                const senderActual = await this.revv.balanceOf(participant);
                prepaidActual.should.be.bignumber.equal(prepaidExpected);
                senderActual.should.be.bignumber.equal(senderExpected);
            });

            it("should correctly zero out the sender's escrow balance", async function () {
                const balanceBefore = await this.prepaid.balanceOf(participant);
                balanceBefore.should.be.bignumber.not.equal(Zero);
                await this.prepaid.withdraw({from: participant});
                const balanceAfter = await this.prepaid.balanceOf(participant);
                balanceAfter.should.be.bignumber.equal(Zero);
            });

            it('should emit the Withddrawn event', async function () {
                const amount = await this.prepaid.balanceOf(participant);
                const receipt = await this.prepaid.withdraw({from: participant});
                expectEvent(receipt, 'Withdrawn', {
                    wallet: participant,
                    amount: amount,
                });
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
                await expectRevert(revert, 'PrePaid: zero amount');
            });

            it('should revert if the given wallet has an insufficient balance to deduct the specified amount from', async function () {
                const revert = this.prepaid.consume(participant2, toWei('100'), {from: operator});
                await expectRevert(revert, 'PrePaid: insufficient funds');
            });

            it('should correctly update the escrow balance of the wallet', async function () {
                const amount = Two;
                const balance = await this.prepaid.balanceOf(participant);
                const expected = balance.sub(amount);
                await this.prepaid.consume(participant, amount, {from: operator});
                const actual = await this.prepaid.balanceOf(participant);
                actual.should.be.bignumber.equal(expected);
            });

            it('should correctly update the global earnings amount', async function () {
                const amount = Two;
                const before = await this.prepaid.globalEarnings();
                const expected = before.add(amount);
                await this.prepaid.consume(participant, amount, {from: operator});
                const actual = await this.prepaid.globalEarnings();
                actual.should.be.bignumber.equal(expected);
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

            it('should correctly transfer the global earnings to the sender', async function () {
                const amount = await this.prepaid.globalEarnings();
                const prepaidBalance = await this.revv.balanceOf(this.prepaid.address);
                const senderBalance = await this.revv.balanceOf(deployer);
                const prepaidExpected = prepaidBalance.sub(amount);
                const senderExpected = senderBalance.add(amount);
                await this.prepaid.collectRevenue({from: deployer});
                const prepaidActual = await this.revv.balanceOf(this.prepaid.address);
                const senderActual = await this.revv.balanceOf(deployer);
                prepaidActual.should.be.bignumber.equal(prepaidExpected);
                senderActual.should.be.bignumber.equal(senderExpected);
            });

            it('should correctly zero out the global earnings amount', async function () {
                const before = await this.prepaid.globalEarnings();
                before.should.be.bignumber.not.equal(Zero);
                await this.prepaid.collectRevenue({from: deployer});
                const after = await this.prepaid.globalEarnings();
                after.should.be.bignumber.equal(Zero);
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

            it('reverts if the state is invalid', async function () {
                const revert = this.prepaid.setSaleState(0, {from: deployer});
                await expectRevert(revert, 'PrePaid: invalid state');
            });

            it('reverts if the current state is already set', async function () {
                const revert = this.prepaid.setSaleState(1, {from: deployer});
                await expectRevert(revert, 'PrePaid: state already set');
            });

            it('can set state BEFORE_SALE_STATE', async function () {
                await this.prepaid.setSaleState(2, {from: deployer});
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

            it('emits state change event when sale starts', async function () {
                const receipt = await this.prepaid.setSaleStart({from: operator});
                await expectEvent(receipt, 'StateChanged', {state: '2'});
                (await this.prepaid.state()).should.be.bignumber.equal('2');
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
                await doDeploy.bind(this)();
            });

            it('emits state change event when sale ends', async function () {
                const receipt = await this.prepaid.setSaleEnd({from: operator});
                await expectEvent(receipt, 'StateChanged', {state: '3'});
                (await this.prepaid.state()).should.be.bignumber.equal('3');
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

            it('should pause the contract', async function () {
                await this.prepaid.unpause({from: deployer});
                let paused = await this.prepaid.paused();
                paused.should.be.false;
                await this.prepaid.pause({from: deployer});
                paused = await this.prepaid.paused();
                paused.should.be.true;
            });

            it('should emit the Paused event', async function () {
                await this.prepaid.unpause({from: deployer});
                const receipt = await this.prepaid.pause({from: deployer});
                expectEvent(receipt, 'Paused');
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

            it('should unpause the contract', async function () {
                await this.prepaid.pause({from: deployer});
                let paused = await this.prepaid.paused();
                paused.should.be.true;
                await this.prepaid.unpause({from: deployer});
                paused = await this.prepaid.paused();
                paused.should.be.false;
            });

            it('should emit the Unpaused event', async function () {
                await this.prepaid.pause({from: deployer});
                const receipt = await this.prepaid.unpause({from: deployer});
                expectEvent(receipt, 'Unpaused');
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

            it('withdraw all balance', async function () {
                (await this.revv.balanceOf(participant)).should.be.bignumber.equal(toWei('99999000'));
                (await this.revv.balanceOf(deployer)).should.be.bignumber.equal(toWei('0'));
                await this.prepaid.withdraw({from: participant});
                await this.prepaid.withdraw({from: participant2});
                await this.prepaid.collectRevenue({from: deployer});
                (await this.revv.balanceOf(participant2)).should.be.bignumber.equal(toWei('99999990'));
                (await this.revv.balanceOf(participant)).should.be.bignumber.equal(toWei('100000000'));
                (await this.revv.balanceOf(deployer)).should.be.bignumber.equal(toWei('10'));
            });
        });

        describe('scenario', function () {
            before(async function () {
                await doDeploy.bind(this)({
                    holders: participants,
                    amounts: new Array(participants.length).fill(toWei('100000000')),
                });
                await doApproveSpender.bind(this)({
                    owners: participants,
                    allowances: new Array(participants.length).fill(toWei('100000000')),
                });
            });

            it('transfer ownership', async function () {
                const receipt = await this.prepaid.transferOwnership(operation, {from: deployer});
                await expectEvent(receipt, 'OwnershipTransferred', {previousOwner: deployer, newOwner: operation});
            });

            it('unpaused', async function () {
                const receipt = await this.prepaid.unpause({from: operation});
                await expectEvent(receipt, 'Unpaused', {account: operation});
            });

            it('user deposits', async function () {
                await this.prepaid.deposit(toWei('10000000'), {from: participant});
                (await this.revv.balanceOf(participant)).should.be.bignumber.equal(toWei('90000000'));
                await this.prepaid.deposit(toWei('20000000'), {from: participant2});
                (await this.revv.balanceOf(participant2)).should.be.bignumber.equal(toWei('80000000'));
                (await this.revv.balanceOf(this.prepaid.address)).should.be.bignumber.equal(toWei('30000000'));
                // todo discount check
                (await this.prepaid.getDiscount()).should.be.bignumber.equal('25');
                // todo total deposit check
                (await this.prepaid.globalDeposit()).should.be.bignumber.equal(toWei('30000000'));
            });

            it('user deposits more', async function () {
                await this.prepaid.deposit(toWei('10000000'), {from: participant});
                (await this.revv.balanceOf(participant)).should.be.bignumber.equal(toWei('80000000'));
                await this.prepaid.deposit(toWei('30000000'), {from: participant3});
                (await this.revv.balanceOf(participant3)).should.be.bignumber.equal(toWei('70000000'));
                (await this.revv.balanceOf(this.prepaid.address)).should.be.bignumber.equal(toWei('70000000'));
                // todo discount check
                (await this.prepaid.getDiscount()).should.be.bignumber.equal('50');
                // todo total deposit check
                (await this.prepaid.globalDeposit()).should.be.bignumber.equal(toWei('70000000'));
            });

            it('start sales', async function () {
                await expectEvent(await this.prepaid.setSaleStart({from: operator}), 'StateChanged', {state: '2'});
            });

            it('user consumes', async function () {
                await await this.prepaid.consume(participant, toWei('10000000'), {from: operator});
                await await this.prepaid.consume(participant2, toWei('10000000'), {from: operator});
                await await this.prepaid.consume(participant3, toWei('30000000'), {from: operator});
                (await this.prepaid.balanceOf(participant)).should.be.bignumber.equal(toWei('10000000'));
                (await this.prepaid.balanceOf(participant2)).should.be.bignumber.equal(toWei('10000000'));
                (await this.prepaid.balanceOf(participant3)).should.be.bignumber.equal(toWei('0'));
                (await this.prepaid.globalEarnings()).should.be.bignumber.equal(toWei('50000000'));
                // check total deposit and discount remain the same when user pays
                (await this.prepaid.getDiscount()).should.be.bignumber.equal('50');
                (await this.prepaid.globalDeposit()).should.be.bignumber.equal(toWei('70000000'));
            });

            it('ends sales', async function () {
                await expectEvent(await this.prepaid.setSaleEnd({from: operator}), 'StateChanged', {state: '3'});
            });

            it('collect revenue', async function () {
                await this.prepaid.collectRevenue({from: operation});
                (await this.revv.balanceOf(operation)).should.be.bignumber.equal(toWei('50000000'));
                (await this.revv.balanceOf(this.prepaid.address)).should.be.bignumber.equal(toWei('20000000'));
            });

            it('user withdraw', async function () {
                await this.prepaid.withdraw({from: participant});
                (await this.revv.balanceOf(participant)).should.be.bignumber.equal(toWei('90000000'));
                await this.prepaid.withdraw({from: participant2});
                (await this.revv.balanceOf(participant2)).should.be.bignumber.equal(toWei('90000000'));
                // user use up the balance no need for withdrawal
                const revert = this.prepaid.withdraw({from: participant3});
                expectRevert(revert, 'PrePaid: no balance');
                (await this.revv.balanceOf(this.prepaid.address)).should.be.bignumber.equal(toWei('0'));
            });
        });
    });
});
