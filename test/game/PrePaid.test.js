const { accounts, contract } = require('@openzeppelin/test-environment');
const { expectRevert } = require('@openzeppelin/test-helpers');
const { toWei } = require('web3-utils');
const { ZeroAddress } = require('@animoca/ethereum-contracts-core_library').constants;

const PrePaid = contract.fromArtifact('PrePaid');
const REVV = contract.fromArtifact('REVV');

const [ deployer, participant ] = accounts;

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
            await doDeploy.bind(this)();
        });

    });

});
