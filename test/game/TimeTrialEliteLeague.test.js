const {accounts, contract} = require('@openzeppelin/test-environment');
const {expect} = require('chai');
const {expectEvent, expectRevert, time} = require('@openzeppelin/test-helpers');
const {BN, fromAscii, toWei} = require('web3-utils');
const {ZeroAddress} = require('@animoca/ethereum-contracts-core_library').constants;

const EthAddress = '0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE';

const TimeTrialEliteLeague = contract.fromArtifact('TimeTrialEliteLeague');
const REVV = contract.fromArtifact('REVV');

const [deployer, participant] = accounts;

const tiers = {
    A: '100000',
    B: '50000',
    C: '30000',
};

describe('TimeTrialEliteLeague', function () {
    describe('constructor(revvContractAddress, lockingPeriod, tierIds, tierMinDeposits)', function () {
        it('should revert with a zero address for the revv contract', async function () {
            await expectRevert(
                TimeTrialEliteLeague.new(
                    ZeroAddress,
                    1,
                    Object.keys(tiers).map((k) => fromAscii(k)),
                    Object.values(tiers).map((v) => toWei(v)),
                    {from: deployer}
                ),
                'Leagues: zero address'
            );
        });
        it('should revert with a zero locking period', async function () {
            await expectRevert(
                TimeTrialEliteLeague.new(
                    EthAddress,
                    0,
                    Object.keys(tiers).map((k) => fromAscii(k)),
                    Object.values(tiers).map((v) => toWei(v)),
                    {from: deployer}
                ),
                'Leagues: zero lock'
            );
        });
        it('should revert with different lengths', async function () {
            await expectRevert(
                TimeTrialEliteLeague.new(
                    EthAddress,
                    1,
                    Object.keys(tiers).map((k) => fromAscii(k)),
                    Object.values(tiers)
                        .map((v) => toWei(v))
                        .slice(1),
                    {from: deployer}
                ),
                'Leagues: inconsistent arrays'
            );
        });
        it('should revert with a zero amount', async function () {
            await expectRevert(
                TimeTrialEliteLeague.new(
                    EthAddress,
                    1,
                    Object.keys(tiers).map((k) => fromAscii(k)),
                    Object.values(tiers).map(() => 0),
                    {from: deployer}
                ),
                'Leagues: zero amount'
            );
        });

        it('should deploy with correct parameters', async function () {
            TimeTrialEliteLeague.new(
                EthAddress,
                1,
                Object.keys(tiers).map((k) => fromAscii(k)),
                Object.values(tiers).map((v) => toWei(v)),
                {from: deployer}
            );
        });
    });

    describe('enterTier(tierId, deposit)', function () {
        beforeEach(async function () {
            this.revv = await REVV.new([participant], [toWei('1000000')], {from: deployer});
            this.timeTrialEliteLeague = await TimeTrialEliteLeague.new(
                this.revv.address,
                100,
                Object.keys(tiers).map((k) => fromAscii(k)),
                Object.values(tiers).map((v) => toWei(v)),
                {from: deployer}
            );
            await this.revv.whitelistOperator(this.timeTrialEliteLeague.address, true, {from: deployer});
        });

        describe('when not paused', function () {
            it('should revert if tier does not exist', async function () {
                await expectRevert(
                    this.timeTrialEliteLeague.enterTier(fromAscii('D'), 10, {from: participant}),
                    'Leagues: tier not found'
                );
            });

            it('should revert if insufficient deposit', async function () {
                await expectRevert(
                    this.timeTrialEliteLeague.enterTier(fromAscii('A'), 100, {from: participant}),
                    'Leagues: insufficient amount'
                );
            });

            it('should revert if already participant', async function () {
                await this.timeTrialEliteLeague.enterTier(fromAscii('A'), toWei('100000'), {from: participant});
                await expectRevert(
                    this.timeTrialEliteLeague.enterTier(fromAscii('A'), toWei('100000'), {from: participant}),
                    'Leagues: already participant'
                );
            });

            it('should revert if not enough REVV in wallet', async function () {
                await this.revv.transfer(deployer, toWei('999990'), {from: participant}); // remaining 10 REVV
                await expectRevert(
                    this.timeTrialEliteLeague.enterTier(fromAscii('A'), toWei('100000'), {from: participant}),
                    'ERC20: transfer amount exceeds balance'
                );
            });

            it('should emit ParticipationUpdated event and transfer REVV to the contract (exact deposit)', async function () {
                const receipt = await this.timeTrialEliteLeague.enterTier(fromAscii('A'), toWei('100000'), {
                    from: participant,
                });

                expectEvent(receipt, 'ParticipationUpdated', {
                    participant,
                    // tierId: fromAscii('A'), // TODO right-padding is missing when using `fromAscii`
                    deposit: toWei('100000'),
                });

                const revvContractBalance = await this.revv.balanceOf(this.timeTrialEliteLeague.address);
                revvContractBalance.should.be.bignumber.equal(toWei('100000'));
            });

            it('should emit ParticipationUpdated event and transfer REVV to the contract (extra deposit)', async function () {
                const receipt = await this.timeTrialEliteLeague.enterTier(fromAscii('A'), toWei('200000'), {
                    from: participant,
                });

                expectEvent(receipt, 'ParticipationUpdated', {
                    participant,
                    // tierId: fromAscii('A'), // TODO right-padding is missing when using `fromAscii`
                    deposit: toWei('200000'),
                });

                const revvContractBalance = await this.revv.balanceOf(this.timeTrialEliteLeague.address);
                revvContractBalance.should.be.bignumber.equal(toWei('200000'));
            });
        });

        describe('when paused', function () {
            beforeEach(async function () {
                await this.timeTrialEliteLeague.pause({from: deployer});
            });

            it('should revert if tier does not exist (paused)', async function () {
                await expectRevert(
                    this.timeTrialEliteLeague.enterTier(fromAscii('D'), 10, {from: participant}),
                    'Pausable: paused'
                );
            });

            it('should revert if insufficient deposit (paused)', async function () {
                await expectRevert(
                    this.timeTrialEliteLeague.enterTier(fromAscii('A'), 100, {from: participant}),
                    'Pausable: paused'
                );
            });

            it('should revert if not enough REVV in wallet (paused)', async function () {
                await this.revv.transfer(deployer, toWei('999990'), {from: participant}); // remaining 10 REVV
                await expectRevert(
                    this.timeTrialEliteLeague.enterTier(fromAscii('A'), toWei('100000'), {from: participant}),
                    'Pausable: paused'
                );
            });

            it('should revert with correct arguments (paused)', async function () {
                await expectRevert(
                    this.timeTrialEliteLeague.enterTier(fromAscii('A'), toWei('100000'), {from: participant}),
                    'Pausable: paused'
                );
            });
        });
    });

    describe('increaseDeposit(tierId, amount)', function () {
        beforeEach(async function () {
            this.revv = await REVV.new([participant], [toWei('1000000')], {from: deployer});
            this.timeTrialEliteLeague = await TimeTrialEliteLeague.new(
                this.revv.address,
                100,
                Object.keys(tiers).map((k) => fromAscii(k)),
                Object.values(tiers).map((v) => toWei(v)),
                {from: deployer}
            );
            await this.revv.whitelistOperator(this.timeTrialEliteLeague.address, true, {from: deployer});
            await this.timeTrialEliteLeague.enterTier(fromAscii('A'), toWei('100000'), {from: participant});
            // await this.timeTrialEliteLeague.enterTier(fromAscii('B'), toWei('50000'));
            await this.timeTrialEliteLeague.enterTier(fromAscii('C'), toWei('30000'), {from: participant});
        });

        describe('when not paused', function () {
            it('should revert if tier does not exist', async function () {
                await expectRevert(
                    this.timeTrialEliteLeague.increaseDeposit(fromAscii('D'), 10, {from: participant}),
                    'Leagues: tier not found'
                );
            });

            it('should revert if user is not in tier', async function () {
                await expectRevert(
                    this.timeTrialEliteLeague.increaseDeposit(fromAscii('B'), 10, {from: participant}),
                    'Leagues: non participant'
                );
            });

            it('should emit ParticipationUpdated event and transfer REVV to the contract', async function () {
                const receipt = await this.timeTrialEliteLeague.increaseDeposit(fromAscii('A'), toWei('1000'), {
                    from: participant,
                });

                expectEvent(receipt, 'ParticipationUpdated', {
                    participant,
                    // tierId: fromAscii('A'), // TODO right-padding is missing when using `fromAscii`
                    deposit: toWei('101000'),
                });

                const revvContractBalance = await this.revv.balanceOf(this.timeTrialEliteLeague.address);
                revvContractBalance.should.be.bignumber.equal(toWei('131000'));
            });
        });

        describe('when paused', function () {
            beforeEach(async function () {
                await this.timeTrialEliteLeague.pause({from: deployer});
            });

            it('should revert if tier does not exist (paused)', async function () {
                await expectRevert(
                    this.timeTrialEliteLeague.increaseDeposit(fromAscii('D'), 10, {from: participant}),
                    'Pausable: paused'
                );
            });

            it('should revert if user is not in tier (paused)', async function () {
                await expectRevert(
                    this.timeTrialEliteLeague.increaseDeposit(fromAscii('B'), 10, {from: participant}),
                    'Pausable: paused'
                );
            });

            it('should revert with correct parameters (paused)', async function () {
                await expectRevert(
                    this.timeTrialEliteLeague.increaseDeposit(fromAscii('A'), toWei('1000'), {from: participant}),
                    'Pausable: paused'
                );
            });
        });
    });

    describe('exitTier(tierId)', function () {
        beforeEach(async function () {
            this.revv = await REVV.new([participant], [toWei('1000000')], {from: deployer});
            this.timeTrialEliteLeague = await TimeTrialEliteLeague.new(
                this.revv.address,
                100,
                Object.keys(tiers).map((k) => fromAscii(k)),
                Object.values(tiers).map((v) => toWei(v)),
                {from: deployer}
            );
            await this.revv.whitelistOperator(this.timeTrialEliteLeague.address, true, {from: deployer});
            await this.timeTrialEliteLeague.enterTier(fromAscii('A'), toWei('100000'), {from: participant});
            // await this.timeTrialEliteLeague.enterTier(fromAscii('B'), toWei('50000'), {from: participant});
            await this.timeTrialEliteLeague.enterTier(fromAscii('C'), toWei('30000'), {from: participant});
        });

        describe('when not paused', function () {
            it('should revert if the tier does not exist', async function () {
                await expectRevert(
                    this.timeTrialEliteLeague.exitTier(fromAscii('D'), {from: participant}),
                    'Leagues: non-participant'
                );
            });

            it('should revert if the participant is not in the tier', async function () {
                await expectRevert(
                    this.timeTrialEliteLeague.exitTier(fromAscii('B'), {from: participant}),
                    'Leagues: non-participant'
                );
            });

            it('should revert if the participant is still time locked', async function () {
                await expectRevert(
                    this.timeTrialEliteLeague.exitTier(fromAscii('A'), {from: participant}),
                    'Leagues: time-locked'
                );
            });

            it('should emit ParticipationUpdated event and transfer REVV back to the participant', async function () {
                await time.increase(101);
                const receipt = await this.timeTrialEliteLeague.exitTier(fromAscii('A'), {
                    from: participant,
                });

                expectEvent(receipt, 'ParticipationUpdated', {
                    participant,
                    // tierId: fromAscii('A'), // TODO right-padding is missing when using `fromAscii`
                    deposit: toWei('0'),
                });

                const revvContractBalance = await this.revv.balanceOf(this.timeTrialEliteLeague.address);
                revvContractBalance.should.be.bignumber.equal(toWei('30000'));
            });
        });

        describe('when paused', function () {
            it('should revert if the tier does not exist', async function () {
                await expectRevert(
                    this.timeTrialEliteLeague.exitTier(fromAscii('D'), {from: participant}),
                    'Leagues: non-participant'
                );
            });

            it('should revert if the participant is not in the tier', async function () {
                await expectRevert(
                    this.timeTrialEliteLeague.exitTier(fromAscii('B'), {from: participant}),
                    'Leagues: non-participant'
                );
            });

            it('should revert if the participant is still time locked', async function () {
                await expectRevert(
                    this.timeTrialEliteLeague.exitTier(fromAscii('A'), {from: participant}),
                    'Leagues: time-locked'
                );
            });

            it('should emit ParticipationUpdated event and transfer REVV back to the participant', async function () {
                await time.increase(101);
                const receipt = await this.timeTrialEliteLeague.exitTier(fromAscii('A'), {
                    from: participant,
                });

                expectEvent(receipt, 'ParticipationUpdated', {
                    participant,
                    // tierId: fromAscii('A'), // TODO right-padding is missing when using `fromAscii`
                    deposit: toWei('0'),
                });

                const revvContractBalance = await this.revv.balanceOf(this.timeTrialEliteLeague.address);
                revvContractBalance.should.be.bignumber.equal(toWei('30000'));
            });
        });
    });
});
