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
            (await this.revv.balanceOf(participant)).should.be.bignumber.equal(toWei('100000000'));
            await this.prepaid.deposit(toWei('10000000'), { from: participant });
            (await this.revv.balanceOf(participant)).should.be.bignumber.equal(toWei('90000000'));
            await this.prepaid.deposit(toWei('20000000'), { from: participant2 });
            (await this.revv.balanceOf(participant2)).should.be.bignumber.equal(toWei('80000000'));
            (await this.revv.balanceOf(this.prepaid.address)).should.be.bignumber.equal(toWei('30000000'));
            // todo discount check
            (await this.prepaid.getDiscount()).should.be.bignumber.equal('25');
            // todo total deposit check
            (await this.prepaid.globalDeposit()).should.be.bignumber.equal(toWei('30000000'));
        });

        it('user deposits more', async function () {
            await this.prepaid.deposit(toWei('10000000'), { from: participant });
            (await this.revv.balanceOf(participant)).should.be.bignumber.equal(toWei('80000000'));
            await this.prepaid.deposit(toWei('30000000'), { from: participant3 });
            (await this.revv.balanceOf(participant3)).should.be.bignumber.equal(toWei('70000000'));
            (await this.revv.balanceOf(this.prepaid.address)).should.be.bignumber.equal(toWei('70000000'));
            // todo discount check
            (await this.prepaid.getDiscount()).should.be.bignumber.equal('50');
            // todo total deposit check
            (await this.prepaid.globalDeposit()).should.be.bignumber.equal(toWei('70000000'));
        });
    });
    return deposits;
};


