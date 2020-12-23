const Web3 = require('web3');
const {accounts, contract, web3} = require('@openzeppelin/test-environment');
const {BN, expectRevert, expectEvent} = require('@openzeppelin/test-helpers');
const {toWei} = require('web3-utils');
const {ZeroAddress, Zero, One, Two, Five, MaxUInt256} = require('@animoca/ethereum-contracts-core_library').constants;
const {utils} = require('@animoca/f1dt-core_metadata');
const {getCoreMetadata} = utils;
const ContractDeployer = require('../helpers/ContractDeployer');
const {deployCrateKeyTokens} = ContractDeployer;
const {toEthSignedMessageHash, fixSignature} = require('../helpers/sign');

const OneKey = toWei(One);

const Locksmith = contract.fromArtifact('Crates2020Locksmith');
// const CrateKey = contract.fromArtifact('F1DTCrateKey');
const artifactsDir = contract.artifactsDir.toString();
contract.artifactsDir = './imports';
const Bytes = contract.fromArtifact('Bytes');
const DeltaTimeInventory = contract.fromArtifact('DeltaTimeInventory');
contract.artifactsDir = artifactsDir;

const [deployer, holder, signer1, signer2] = accounts;

describe('Crates2020Locksmith', function () {
    async function doDeploy() {
        const bytes = await Bytes.new({from: deployer});
        DeltaTimeInventory.network_id = 1337;
        await DeltaTimeInventory.link('Bytes', bytes.address);
        this.inventory = await DeltaTimeInventory.new(ZeroAddress, ZeroAddress, {from: deployer});
        const keys = await deployCrateKeyTokens({from: deployer}, holder);
        this.crateKeyCommon = keys.F1DT_CCK;
        this.crateKeyRare = keys.F1DT_RCK;
        this.crateKeyEpic = keys.F1DT_ECK;
        this.crateKeyLegendary = keys.F1DT_LCK;
        this.locksmith = await Locksmith.new(
            this.inventory.address,
            this.crateKeyCommon.address,
            this.crateKeyRare.address,
            this.crateKeyEpic.address,
            this.crateKeyLegendary.address,
            {from: deployer}
        );
    }

    async function doSetCratesAsKeysOwner() {
        await this.crateKeyCommon.transferOwnership(this.locksmith.address, {from: deployer});
        await this.crateKeyRare.transferOwnership(this.locksmith.address, {from: deployer});
        await this.crateKeyEpic.transferOwnership(this.locksmith.address, {from: deployer});
        await this.crateKeyLegendary.transferOwnership(this.locksmith.address, {from: deployer});
    }

    async function doSetCratesAsInventoryMinter() {
        await this.inventory.addMinter(this.locksmith.address, {from: deployer});
    }

    describe('constructor()', function () {
        it('should revert with a zero address for the revv contract', async function () {
            await expectRevert(
                Locksmith.new(ZeroAddress, ZeroAddress, ZeroAddress, ZeroAddress, ZeroAddress, {from: deployer}),
                'Crates: zero address'
            );
        });

        it('should deploy with correct parameters', async function () {
            await doDeploy.bind(this)();
        });
    });

    describe('insertKeys()', function () {
        // beforeEach(async function () {
        //     await doDeploy.bind(this)();
        // });

        // it('should revert with an incorrect crate key tier', async function () {
        //     await expectRevert(this.locksmith.openCrate(10, 0, {from: deployer}), 'Crates: wrong crate tier');
        // });

        // it('should revert if the caller does not have a key', async function () {
        //     await expectRevert(this.locksmith.openCrate(0, 0, {from: deployer}), 'ERC20: transfer amount exceeds balance');
        // });

        // it('should revert if the holder did not set allowance to the contract', async function () {
        //     await expectRevert(this.locksmith.openCrate(0, 0, {from: holder}), 'ERC20: transfer amount exceeds allowance');
        // });

        // it('should revert if the crates is not the crate key contract owner', async function () {
        //     await this.crateKeyLegendary.approve(this.locksmith.address, MaxUInt256, {from: holder});
        //     await expectRevert(this.locksmith.openCrate(0, 0, {from: holder}), 'Ownable: caller is not the owner');
        // });

        // it('should revert if the crates is not an inventory minter', async function () {
        //     await doSetCratesAsKeysOwner.bind(this)();
        //     await this.crateKeyLegendary.approve(this.locksmith.address, MaxUInt256, {from: holder});
        //     await expectRevert(
        //         this.locksmith.openCrate(0, 0, {from: holder}),
        //         'MinterRole: caller does not have the Minter role'
        //     );
        // });

        function createPayloadHash(holder, crateTier, nonce) {
            const payload = web3.eth.abi.encodeParameters(
                ['address', 'uint256', 'uint256'],
                [holder, crateTier.toString(), nonce.toString()]
            );
            return web3.utils.soliditySha3(payload);
        }

        describe('on success', function () {
            const crateTier = Zero; // Legendary
            before(async function () {
                await doDeploy.bind(this)();
                await doSetCratesAsKeysOwner.bind(this)();
                await doSetCratesAsInventoryMinter.bind(this)();
                await this.locksmith.setSignerKey(signer1, {from: deployer});
                await this.crateKeyLegendary.approve(this.locksmith.address, MaxUInt256, {from: holder});

                this.nonce = await this.locksmith.nonces(holder, crateTier);
                const payloadHash = await createPayloadHash(holder, crateTier, this.nonce);
                this.signature = fixSignature(await web3.eth.sign(payloadHash, signer1));
                this.receipt = await this.locksmith.insertKeys(crateTier, 1, this.signature, {from: holder});
                this.gasUsed = this.receipt.receipt.gasUsed;
            });

            it('should update the nonce', async function () {
                const nonce = await this.locksmith.nonces(holder, crateTier);
                nonce.should.be.bignumber.equal(this.nonce.add(One));
            });

            it('should fail if trying to use the same signature again', async function () {
                await expectRevert(
                    this.locksmith.insertKeys(crateTier, 1, this.signature, {from: holder}),
                    'Locksmith: invalid signature'
                );
            });

            it('should cost less gas the second time', async function () {
                this.nonce = await this.locksmith.nonces(holder, crateTier);
                const payloadHash = await createPayloadHash(holder, crateTier, this.nonce);
                this.signature = fixSignature(await web3.eth.sign(payloadHash, signer1));
                const newReceipt = await this.locksmith.insertKeys(crateTier, 1, this.signature, {from: holder});
                const newGasUsed = newReceipt.receipt.gasUsed;
                console.log(`Bootstrap gas cost: ${this.gasUsed}, later: ${newGasUsed}`);
                newGasUsed.should.be.lt(this.gasUsed);
            });
        });
    });
});
