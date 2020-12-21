const {accounts, contract} = require('@openzeppelin/test-environment');
const {BN, expectRevert, expectEvent} = require('@openzeppelin/test-helpers');
const {toWei} = require('web3-utils');
const {ZeroAddress, Zero, One, Two, Five, MaxUInt256} = require('@animoca/ethereum-contracts-core_library').constants;
const {utils} = require('@animoca/f1dt-core_metadata');
const {getCoreMetadata} = utils;
const ContractDeployer = require('../helpers/ContractDeployer');
const {deployCrateKeyTokens} = ContractDeployer;

const OneKey = toWei(One);

const Locksmith = contract.fromArtifact('Crates2020Locksmith');
// const CrateKey = contract.fromArtifact('F1DTCrateKey');
const artifactsDir = contract.artifactsDir.toString();
contract.artifactsDir = './imports';
const Bytes = contract.fromArtifact('Bytes');
const DeltaTimeInventory = contract.fromArtifact('DeltaTimeInventory');
contract.artifactsDir = artifactsDir;

const [deployer, holder] = accounts;

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

    async function doSetLocksmithAsKeysOwner() {
        await this.crateKeyCommon.transferOwnership(this.locksmith.address, {from: deployer});
        await this.crateKeyRare.transferOwnership(this.locksmith.address, {from: deployer});
        await this.crateKeyEpic.transferOwnership(this.locksmith.address, {from: deployer});
        await this.crateKeyLegendary.transferOwnership(this.locksmith.address, {from: deployer});
    }

    async function doSetLocksmithAsInventoryMinter() {
        await this.inventory.addMinter(this.locksmith.address, {from: deployer});
    }

    describe('constructor()', function () {
        it('should revert with a zero address for the revv contract', async function () {
            await expectRevert(
                Locksmith.new(ZeroAddress, ZeroAddress, ZeroAddress, ZeroAddress, ZeroAddress, {from: deployer}),
                'Locksmith: zero address'
            );
        });

        it('should deploy with correct parameters', async function () {
            await doDeploy.bind(this)();
        });
    });

    describe('openCrate()', function () {
        beforeEach(async function () {
            await doDeploy.bind(this)();
        });

        it('should revert with an incorrect crate key tier', async function () {
            await expectRevert(this.locksmith.openCrate(10, {from: deployer}), 'Locksmith: wrong crate tier');
        });

        it('should revert if the caller does not have a key', async function () {
            await expectRevert(this.locksmith.openCrate(0, {from: deployer}), 'ERC20: transfer amount exceeds balance');
        });

        it('should revert if the holder did not set allowance to the contract', async function () {
            await expectRevert(this.locksmith.openCrate(0, {from: holder}), 'ERC20: transfer amount exceeds allowance');
        });

        it('should revert if the locksmith is not the crate key contract owner', async function () {
            await this.crateKeyLegendary.approve(this.locksmith.address, MaxUInt256, {from: holder});
            await expectRevert(this.locksmith.openCrate(0, {from: holder}), 'Ownable: caller is not the owner');
        });

        it('should revert if the locksmith is not an inventory minter', async function () {
            await doSetLocksmithAsKeysOwner.bind(this)();
            await this.crateKeyLegendary.approve(this.locksmith.address, MaxUInt256, {from: holder});
            await expectRevert(
                this.locksmith.openCrate(0, {from: holder}),
                'MinterRole: caller does not have the Minter role'
            );
        });

        describe('on success', function () {
            before(async function () {
                await doDeploy.bind(this)();
                await doSetLocksmithAsKeysOwner.bind(this)();
                await doSetLocksmithAsInventoryMinter.bind(this)();
                await this.crateKeyLegendary.approve(this.locksmith.address, MaxUInt256, {from: holder});
                this.counter = await this.locksmith.counter();
                this.receipt = await this.locksmith.openCrate(0, {from: holder});

                this.tokens = [ // to be updated if contract changes
                    new BN('800200030000000004010000000004036a033703540000000000000000000000', 'hex'),
                    new BN('80040403000000000008000000000000fe00fd01100000000000000000000001', 'hex'),
                    new BN('80040403000000000008000000000000fe00fd01100000000000000000000002', 'hex'),
                    new BN('80040403000000000008000000000000fe00fd01100000000000000000000003', 'hex'),
                    new BN('80040403000000000008000000000000fe00fd01100000000000000000000004', 'hex'),
                ];
            });
            it('should burn the crate key', async function () {
                await expectEvent.inTransaction(this.receipt.tx, this.crateKeyLegendary, 'Transfer', {
                    _from: holder,
                    _to: this.locksmith.address,
                    _value: OneKey,
                });

                await expectEvent.inTransaction(this.receipt.tx, this.crateKeyLegendary, 'Transfer', {
                    _from: this.locksmith.address,
                    _to: ZeroAddress,
                    _value: OneKey,
                });
            });

            it('should mint the NFTs', async function () {
                for (let i = 0; i < 5; i++) {
                    const tokenId = this.tokens[i];

                    await expectEvent.inTransaction(this.receipt.tx, this.inventory, 'Transfer', {
                        _from: ZeroAddress,
                        _to: holder,
                        _tokenId: tokenId,
                    });

                    await expectEvent.inTransaction(this.receipt.tx, this.inventory, 'TransferSingle', {
                        _operator: this.locksmith.address,
                        _from: ZeroAddress,
                        _to: holder,
                        _id: tokenId,
                        _value: 1,
                    });

                    const tokenCounter = new BN(getCoreMetadata(tokenId.toString()).counter);
                    tokenCounter.should.be.bignumber.equal(this.counter.add(new BN(`${i}`)));
                }
            });

            it('should update the counter', async function () {
                const counter = await this.locksmith.counter();
                counter.should.be.bignumber.equal(this.counter.add(Five));
            });
        });
    });
});
