const {accounts, contract} = require('@openzeppelin/test-environment');
const {BN, expectRevert, expectEvent} = require('@openzeppelin/test-helpers');
const {toWei} = require('web3-utils');
const {ZeroAddress, Zero, One, Two, Five, MaxUInt256} = require('@animoca/ethereum-contracts-core_library').constants;
const {crates} = require('../metadata/Crates2020RNGLib.constants');
const {utils} = require('@animoca/f1dt-core_metadata');
const {getCoreMetadata} = utils;
const ContractDeployer = require('../helpers/ContractDeployer');
const {deployCrateKeyTokens} = ContractDeployer;

const OneKey = toWei(One);

const Crates = contract.fromArtifact('Crates2020Mock');
// const CrateKey = contract.fromArtifact('F1DTCrateKey');
const artifactsDir = contract.artifactsDir.toString();
contract.artifactsDir = './imports';
const Bytes = contract.fromArtifact('Bytes');
const DeltaTimeInventory = contract.fromArtifact('DeltaTimeInventory');
contract.artifactsDir = artifactsDir;

const [deployer, holder] = accounts;

describe('Crates2020', function () {
    const seed = 0;
    const legendaryTokens = [
        // to be updated if RNG lib changes
        new BN('800200030000000004010000000004036a033703540000000000000000000000', 'hex'),
        new BN('80040403000000000008000000000000fe00fd01100000000000000000000001', 'hex'),
        new BN('80040403000000000008000000000000fe00fd01100000000000000000000002', 'hex'),
        new BN('80040403000000000008000000000000fe00fd01100000000000000000000003', 'hex'),
        new BN('80040403000000000008000000000000fe00fd01100000000000000000000004', 'hex'),
    ];
    // const quantity = 1;
    const quantity = 5;

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
        this.crates = await Crates.new(
            this.inventory.address,
            this.crateKeyCommon.address,
            this.crateKeyRare.address,
            this.crateKeyEpic.address,
            this.crateKeyLegendary.address,
            {from: deployer}
        );
    }

    async function doSetCratesAsKeysOwner() {
        await this.crateKeyCommon.transferOwnership(this.crates.address, {from: deployer});
        await this.crateKeyRare.transferOwnership(this.crates.address, {from: deployer});
        await this.crateKeyEpic.transferOwnership(this.crates.address, {from: deployer});
        await this.crateKeyLegendary.transferOwnership(this.crates.address, {from: deployer});
    }

    async function doSetCratesAsInventoryMinter() {
        await this.inventory.addMinter(this.crates.address, {from: deployer});
    }

    describe('constructor()', function () {
        it('should revert with a zero address for the revv contract', async function () {
            await expectRevert(
                Crates.new(ZeroAddress, ZeroAddress, ZeroAddress, ZeroAddress, ZeroAddress, {from: deployer}),
                'Crates: zero address'
            );
        });

        it('should deploy with correct parameters', async function () {
            await doDeploy.bind(this)();
        });
    });

    describe('openCrates()', function () {
        beforeEach(async function () {
            await doDeploy.bind(this)();
        });

        it('should revert with an incorrect crate key tier', async function () {
            await expectRevert(this.crates.openCrates(10, 1, 0, {from: deployer}), 'Crates: wrong crate tier');
        });

        it('should revert if the caller does not have a key', async function () {
            await expectRevert(
                this.crates.openCrates(crates.Legendary.tier, quantity, seed, {from: deployer}),
                'ERC20: transfer amount exceeds balance'
            );
        });

        it('should revert if the holder did not set allowance to the contract', async function () {
            await expectRevert(
                this.crates.openCrates(crates.Legendary.tier, quantity, seed, {from: holder}),
                'ERC20: transfer amount exceeds allowance'
            );
        });

        it('should revert if the crates is not the crate key contract owner', async function () {
            await this.crateKeyLegendary.approve(this.crates.address, MaxUInt256, {from: holder});
            await expectRevert(
                this.crates.openCrates(crates.Legendary.tier, quantity, seed, {from: holder}),
                'Ownable: caller is not the owner'
            );
        });

        it('should revert if the crates is not an inventory minter', async function () {
            await doSetCratesAsKeysOwner.bind(this)();
            await this.crateKeyLegendary.approve(this.crates.address, MaxUInt256, {from: holder});
            await expectRevert(
                this.crates.openCrates(crates.Legendary.tier, quantity, seed, {from: holder}),
                'MinterRole: caller does not have the Minter role'
            );
        });

        describe('on success', function () {
            before(async function () {
                await doDeploy.bind(this)();
                await doSetCratesAsKeysOwner.bind(this)();
                await doSetCratesAsInventoryMinter.bind(this)();
                await this.crateKeyLegendary.approve(this.crates.address, MaxUInt256, {from: holder});
                this.counter = await this.crates.counter();
                this.receipt = await this.crates.openCrates(crates.Legendary.tier, quantity, seed, {from: holder});
                this.tokens = legendaryTokens;
            });
            it('should burn the crate key', async function () {
                await expectEvent.inTransaction(this.receipt.tx, this.crateKeyLegendary, 'Transfer', {
                    _from: holder,
                    _to: this.crates.address,
                    _value: OneKey.mul(new BN(quantity)),
                });

                await expectEvent.inTransaction(this.receipt.tx, this.crateKeyLegendary, 'Transfer', {
                    _from: this.crates.address,
                    _to: ZeroAddress,
                    _value: OneKey.mul(new BN(quantity)),
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
                        _operator: this.crates.address,
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
                const counter = await this.crates.counter();
                counter.should.be.bignumber.equal(this.counter.add(Five.mul(new BN(quantity))));
            });
        });
    });

    describe('transferCrateKeyOwnership()', function () {
        beforeEach(async function () {
            await doDeploy.bind(this)();
        });

        it('should revert if not called by the owner of this contract', async function () {
            await expectRevert(
                this.crates.transferCrateKeyOwnership(crates.Legendary.tier, deployer, {from: holder}),
                'Ownable: caller is not the owner'
            );
        });

        it('should revert if the crate key is not owned by this contract', async function () {
            await expectRevert(
                this.crates.transferCrateKeyOwnership(crates.Legendary.tier, deployer, {from: deployer}),
                'Ownable: caller is not the owner'
            );
        });

        it('should work with correct parameters', async function () {
            await doSetCratesAsKeysOwner.bind(this)();
            await this.crates.transferCrateKeyOwnership(crates.Legendary.tier, deployer, {from: deployer});
            const owner = await this.crateKeyLegendary.owner();
            owner.should.be.equal(deployer);
        });
    });
});
