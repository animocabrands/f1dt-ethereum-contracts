const {accounts, contract} = require('@openzeppelin/test-environment');
const {BN, expectRevert, expectEvent} = require('@openzeppelin/test-helpers');
const {toWei} = require('web3-utils');
const {ZeroAddress, Zero, One, Two, Five, MaxUInt256} = require('@animoca/ethereum-contracts-core_library').constants;
const {crates} = require('../metadata/Crates2020RNGLib.constants');
const ContractDeployer = require('../helpers/ContractDeployer');
const {deployCrateKeyTokens} = ContractDeployer;

const OneKey = toWei(One);

const Crates = contract.fromArtifact('Crates2020Mock');
const artifactsDir = contract.artifactsDir.toString();
contract.artifactsDir = './imports';
const Bytes = contract.fromArtifact('Bytes');
const DeltaTimeInventory = contract.fromArtifact('DeltaTimeInventory');
contract.artifactsDir = artifactsDir;

const [deployer, holder] = accounts;

const TransferEventHash = '0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef'; // Transfer(address,address,uint256)

const maxQuantity = 5;

describe('Crates2020', function () {
    const startCounter = 0;
    const seed = 0;
    const legendaryTokens = [
        // to be updated if RNG lib changes
        new BN('800200030000000004010000000004036a033703540000000000000000000000', 'hex'),
        new BN('80040403000000000008000000000000fe00fd01100000000000000000000001', 'hex'),
        new BN('80040403000000000008000000000000fe00fd01100000000000000000000002', 'hex'),
        new BN('80040403000000000008000000000000fe00fd01100000000000000000000003', 'hex'),
        new BN('80040403000000000008000000000000fe00fd01100000000000000000000004', 'hex'),
    ];

    async function doDeploy() {
        const bytes = await Bytes.new({from: deployer});
        DeltaTimeInventory.network_id = 1337;
        await DeltaTimeInventory.link('Bytes', bytes.address);
        this.inventory = await DeltaTimeInventory.new(ZeroAddress, ZeroAddress, {from: deployer});
        const keys = await deployCrateKeyTokens({from: deployer}, holder);
        this.crateKeys = {
            Common: keys.F1DT_CCK,
            Rare: keys.F1DT_RCK,
            Epic: keys.F1DT_ECK,
            Legendary: keys.F1DT_LCK,
        };
        this.crates = await Crates.new(
            this.inventory.address,
            this.crateKeys.Common.address,
            this.crateKeys.Rare.address,
            this.crateKeys.Epic.address,
            this.crateKeys.Legendary.address,
            startCounter,
            {from: deployer}
        );
    }

    async function doSetCratesAsKeysOwner() {
        await this.crateKeys.Common.transferOwnership(this.crates.address, {from: deployer});
        await this.crateKeys.Rare.transferOwnership(this.crates.address, {from: deployer});
        await this.crateKeys.Epic.transferOwnership(this.crates.address, {from: deployer});
        await this.crateKeys.Legendary.transferOwnership(this.crates.address, {from: deployer});
    }

    async function doSetCratesAsInventoryMinter() {
        await this.inventory.addMinter(this.crates.address, {from: deployer});
    }

    describe('constructor()', function () {
        it('should revert with a zero address for the revv contract', async function () {
            await expectRevert(
                Crates.new(ZeroAddress, ZeroAddress, ZeroAddress, ZeroAddress, ZeroAddress, startCounter, {
                    from: deployer,
                }),
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
            await expectRevert(this.crates.openCrates(10, 1, seed, {from: deployer}), 'Crates: wrong crate tier');
        });

        // eslint-disable-next-line mocha/no-setup-in-describe
        for (const [tier, crate] of Object.entries(crates)) {
            it(`[${tier}] should revert with zero quantity`, async function () {
                await expectRevert(
                    this.crates.openCrates(crate.tier, 0, seed, {from: deployer}),
                    'Crates: zero quantity'
                );
            });

            // eslint-disable-next-line mocha/no-setup-in-describe
            for (let quantity = 1; quantity <= maxQuantity; quantity++) {
                it(`[${tier}] should revert if the caller does not have a key, qty=${quantity}`, async function () {
                    await expectRevert(
                        this.crates.openCrates(crate.tier, quantity, seed, {from: deployer}),
                        'ERC20: transfer amount exceeds balance'
                    );
                });

                it(`[${tier}] should revert if the holder did not set allowance to the contract, qty=${quantity}`, async function () {
                    await expectRevert(
                        this.crates.openCrates(crate.tier, quantity, seed, {from: holder}),
                        'ERC20: transfer amount exceeds allowance'
                    );
                });

                it(`[${tier}] should revert if the crates is not the crate key contract owner, qty=${quantity}`, async function () {
                    await this.crateKeys[tier].approve(this.crates.address, MaxUInt256, {from: holder});
                    await expectRevert(
                        this.crates.openCrates(crate.tier, quantity, seed, {from: holder}),
                        'Ownable: caller is not the owner'
                    );
                });

                it(`[${tier}] should revert if the crates is not an inventory minter, qty=${quantity}`, async function () {
                    await doSetCratesAsKeysOwner.bind(this)();
                    await this.crateKeys[tier].approve(this.crates.address, MaxUInt256, {from: holder});
                    await expectRevert(
                        this.crates.openCrates(crate.tier, quantity, seed, {from: holder}),
                        'MinterRole: caller does not have the Minter role'
                    );
                });

                describe(`[${tier}] on success, qty=${quantity}`, function () {
                    before(async function () {
                        await doDeploy.bind(this)();
                        await doSetCratesAsKeysOwner.bind(this)();
                        await doSetCratesAsInventoryMinter.bind(this)();
                        await this.crateKeys[tier].approve(this.crates.address, MaxUInt256, {from: holder});
                        this.counter = await this.crates.counter();
                        this.receipt = await this.crates.openCrates(crate.tier, quantity, seed, {
                            from: holder,
                        });
                        this.tokens = legendaryTokens;
                    });
                    it(`[${tier}] should burn the crate keys, qty=${quantity}`, async function () {
                        await expectEvent.inTransaction(this.receipt.tx, this.crateKeys[tier], 'Transfer', {
                            _from: holder,
                            _to: this.crates.address,
                            _value: OneKey.mul(new BN(quantity)),
                        });

                        await expectEvent.inTransaction(this.receipt.tx, this.crateKeys[tier], 'Transfer', {
                            _from: this.crates.address,
                            _to: ZeroAddress,
                            _value: OneKey.mul(new BN(quantity)),
                        });
                    });

                    it(`[${tier}] should mint the NFTs, qty=${quantity}`, async function () {
                        const erc721MintingEvents = this.receipt.receipt.rawLogs.filter(
                            (log) =>
                                log.address == this.inventory.address &&
                                log.topics[0] == TransferEventHash && // "Transfer(address,address,uint256)"
                                new BN(log.topics[1].slice(2 /* remove '0x' */), 'hex').isZero() // from address zero
                        );
                        erc721MintingEvents.length.should.be.equal(quantity * 5);
                    });

                    it(`[${tier}] should update the counter, qty=${quantity}`, async function () {
                        const counter = await this.crates.counter();
                        counter.should.be.bignumber.equal(this.counter.add(Five.mul(new BN(quantity))));
                    });
                });
            }
        }
    });

    describe('transferCrateKeyOwnership()', function () {
        beforeEach(async function () {
            await doDeploy.bind(this)();
        });

        // eslint-disable-next-line mocha/no-setup-in-describe
        for (const [tier, crate] of Object.entries(crates)) {
            it(`[${tier}] should revert if not called by the owner of this contract`, async function () {
                await expectRevert(
                    this.crates.transferCrateKeyOwnership(crate.tier, deployer, {from: holder}),
                    'Ownable: caller is not the owner'
                );
            });

            it(`[${tier}] should revert if the crate key is not owned by this contract`, async function () {
                await expectRevert(
                    this.crates.transferCrateKeyOwnership(crate.tier, deployer, {from: deployer}),
                    'Ownable: caller is not the owner'
                );
            });

            it(`[${tier}] should work with correct parameters`, async function () {
                await doSetCratesAsKeysOwner.bind(this)();
                await this.crates.transferCrateKeyOwnership(crate.tier, deployer, {from: deployer});
                const owner = await this.crateKeys[tier].owner();
                owner.should.be.equal(deployer);
            });
        }
    });
});
