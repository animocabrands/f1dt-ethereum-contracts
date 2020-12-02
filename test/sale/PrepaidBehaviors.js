const { accounts, contract } = require('@openzeppelin/test-environment');
const { toWei } = require('web3-utils');
const { BN, expectRevert, expectEvent } = require('@openzeppelin/test-helpers');
const { ZeroAddress, Zero, One, Two } = require('@animoca/ethereum-contracts-core_library').constants;
const deployer = accounts[0];
/**
 * 
 * @param {string} deployer 
 * @param {string} operation 
 * @param {*} prepaidContract 
 */
module.exports.beforeDeposit = function (deployer = accounts[0], operation = accounts[1], prepaidContract) {
    context("before deposit", function () {
        before(function () {
            this.prepaid = prepaidContract || this.prepaid;
        });

        it('transfer ownership', async function () {
            const receipt = await this.prepaid.transferOwnership(operation, { from: deployer });
            await expectEvent(receipt, 'OwnershipTransferred', { previousOwner: deployer, newOwner: operation });
        });

        it('unpaused', async function () {
            const receipt = await this.prepaid.unpause({ from: operation });
            await expectEvent(receipt, 'Unpaused', { account: operation });
        });
    });
};

module.exports.userDeposit = function (partitipants, prepaidContract, revvContract) {
    const [participant, participant2, participant3] = partitipants;
    const deposits = {
        [participant]: toWei("20000000"),
        [participant2]: toWei("20000000"),
        [participant3]: toWei("30000000")
    };
    context("deposit phrase", function () {

        before(async function () {    
            this.prepaid = prepaidContract || this.prepaid;
            this.revv = revvContract || this.revv;
            const prepaidAddress = this.prepaid.address;
            await this.revv.approve(prepaidAddress, toWei("100000000"), {from: participant});
            await this.revv.approve(prepaidAddress, toWei("100000000"), {from: participant2});
            await this.revv.approve(prepaidAddress, toWei("100000000"), {from: participant3});
        });

        it('user deposits', async function () {
            //Participant 1
            (await this.revv.balanceOf(participant)).should.be.bignumber.equal(toWei('100000000'));
            
            const deposit_P1 = toWei('10000000');
            const receipt_P1 = await this.prepaid.deposit(deposit_P1, { from: participant });
            await expectEvent(receipt_P1, 'Deposited', {wallet: participant, amount: deposit_P1});

            (await this.revv.balanceOf(participant)).should.be.bignumber.equal(toWei('90000000'));
            (await this.prepaid.globalDeposit()).should.be.bignumber.equal(toWei('10000000'));
            
            // Discount check - First Condition
            (await this.prepaid.getDiscount()).should.be.bignumber.equal('0');

            //Participant 2
            const deposit_P2 = toWei('10000000');
            const receipt_P2 = await this.prepaid.deposit(deposit_P2, { from: participant2 });
            await expectEvent(receipt_P2, 'Deposited', {wallet: participant2, amount: deposit_P2});

            (await this.revv.balanceOf(participant2)).should.be.bignumber.equal(toWei('90000000'));
            (await this.revv.balanceOf(this.prepaid.address)).should.be.bignumber.equal(toWei('20000000'));
            (await this.prepaid.globalDeposit()).should.be.bignumber.equal(toWei('20000000'));
            
            // Discount check - Second Condition
            (await this.prepaid.getDiscount()).should.be.bignumber.equal('10');
        });

        it('user deposits more', async function () {
            //Participant 1
            const deposit_P1 = toWei('10000000');
            const receipt_P1 = await this.prepaid.deposit(deposit_P1, { from: participant });
            await expectEvent(receipt_P1, 'Deposited', {wallet: participant, amount: deposit_P1});

            (await this.revv.balanceOf(participant)).should.be.bignumber.equal(toWei('80000000'));
            (await this.prepaid.globalDeposit()).should.be.bignumber.equal(toWei('30000000'));

            // Discount check - Third Condition
            (await this.prepaid.getDiscount()).should.be.bignumber.equal('25');

            //Participant 3
            const deposit_P3 = toWei('30000000');
            const receipt_P3 = await this.prepaid.deposit(deposit_P3, { from: participant3 });
            await expectEvent(receipt_P3, 'Deposited', {wallet: participant3, amount: deposit_P3});

            
            (await this.revv.balanceOf(participant3)).should.be.bignumber.equal(toWei('70000000'));
            (await this.revv.balanceOf(this.prepaid.address)).should.be.bignumber.equal(toWei('60000000'));
            (await this.prepaid.globalDeposit()).should.be.bignumber.equal(toWei('60000000'));

            // Discount check - Fourth Condition
            (await this.prepaid.getDiscount()).should.be.bignumber.equal('50');
        });
    });
    return deposits;
};


