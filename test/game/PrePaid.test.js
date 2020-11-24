const {accounts, contract} = require('@openzeppelin/test-environment');
const {expect} = require('chai');
const {expectEvent, expectRevert, time} = require('@openzeppelin/test-helpers');
const {BN, fromAscii, toWei} = require('web3-utils');
const {ZeroAddress} = require('@animoca/ethereum-contracts-core_library').constants;

const PrePaid = contract.fromArtifact('PrePaid');
const REVV = contract.fromArtifact('REVV');

const [deployer, participant] = accounts;


describe('PrePaid', function () {
    describe('constructor(revvContractAddress)', function () {
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
                1,
                Object.keys(tiers).map((k) => fromAscii(k)),
                Object.values(tiers).map((v) => toWei(v)),
                {from: deployer}
            );
        });
    });
});
