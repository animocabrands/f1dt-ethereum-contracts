const {accounts, contract, web3} = require('@openzeppelin/test-environment');
const {BN, expectRevert, expectEvent} = require('@openzeppelin/test-helpers');
const {ZeroAddress, Zero, One, Two, Five, MaxUInt256} = require('@animoca/ethereum-contracts-core_library').constants;
const {crates} = require('../metadata/Crates2020RNGLib.constants');
const ContractDeployer = require('../helpers/ContractDeployer');
const {deployCrateKeyTokens} = ContractDeployer;
const {fixSignature} = require('../helpers/sign');

const Locksmith = contract.fromArtifact('Crates2020Locksmith');
const artifactsDir = contract.artifactsDir.toString();
contract.artifactsDir = './imports';
const Bytes = contract.fromArtifact('Bytes');
const DeltaTimeInventory = contract.fromArtifact('DeltaTimeInventory');
contract.artifactsDir = artifactsDir;

const [deployer, holder, signer1, signer2] = accounts;

const maxQuantity = 5;

describe('Crates2020Locksmith', function () {
    const startCounter = 0;

    function createPayloadHash(holder, crateTier, nonce) {
        const payload = web3.eth.abi.encodeParameters(
            ['address', 'uint256', 'uint256'],
            [holder, `${crateTier}`, nonce.toString()]
        );
        return web3.utils.soliditySha3(payload);
    }

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
        this.locksmith = await Locksmith.new(
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
        await this.crateKeys.Common.transferOwnership(this.locksmith.address, {from: deployer});
        await this.crateKeys.Rare.transferOwnership(this.locksmith.address, {from: deployer});
        await this.crateKeys.Epic.transferOwnership(this.locksmith.address, {from: deployer});
        await this.crateKeys.Legendary.transferOwnership(this.locksmith.address, {from: deployer});
    }

    async function doSetCratesAsInventoryMinter() {
        await this.inventory.addMinter(this.locksmith.address, {from: deployer});
    }

    describe('constructor()', function () {
        it('should revert with a zero address for the revv contract', async function () {
            await expectRevert(
                Locksmith.new(ZeroAddress, ZeroAddress, ZeroAddress, ZeroAddress, ZeroAddress, startCounter, {
                    from: deployer,
                }),
                'Crates: zero address'
            );
        });

        it('should deploy with correct parameters', async function () {
            await doDeploy.bind(this)();
        });
    });

    describe('insertKeys()', function () {
        beforeEach(async function () {
            await doDeploy.bind(this)();
            await doSetCratesAsKeysOwner.bind(this)();
            await doSetCratesAsInventoryMinter.bind(this)();
        });

        // eslint-disable-next-line mocha/no-setup-in-describe
        for (const [tier, crate] of Object.entries(crates)) {
            it(`[${tier}] should revert with an incorrect quantity`, async function () {
                await expectRevert(
                    this.locksmith.insertKeys(crate.tier, maxQuantity + 1, '0x', {from: deployer}),
                    'Locksmith: above max quantity'
                );
            });

            it(`[${tier}] should revert if the signer key is not set`, async function () {
                await expectRevert(
                    this.locksmith.insertKeys(crate.tier, 1, '0x', {from: deployer}),
                    'Locksmith: signer key not set'
                );
            });

            // eslint-disable-next-line mocha/no-setup-in-describe
            for (let quantity = 1; quantity <= maxQuantity; quantity++) {
                it(`[${tier}] should revert if the sigature is from the wrong signer, qty=${quantity}`, async function () {
                    await this.locksmith.setSignerKey(signer1, {from: deployer});
                    this.nonce = await this.locksmith.nonces(holder, crate.tier);
                    const payloadHash = await createPayloadHash(holder, crate.tier, this.nonce);
                    this.signature = fixSignature(await web3.eth.sign(payloadHash, signer2));
                    await expectRevert(
                        this.locksmith.insertKeys(crate.tier, quantity, this.signature, {from: deployer}),
                        'Locksmith: invalid signature'
                    );
                });

                it(`[${tier}] should revert if the sigature has wrong parameters, qty=${quantity}`, async function () {
                    await this.locksmith.setSignerKey(signer1, {from: deployer});
                    this.nonce = await this.locksmith.nonces(holder, crate.tier);
                    const payloadHash = await createPayloadHash(holder, crate.tier, this.nonce.add(One));
                    this.signature = fixSignature(await web3.eth.sign(payloadHash, signer1));
                    await expectRevert(
                        this.locksmith.insertKeys(crate.tier, quantity, this.signature, {from: deployer}),
                        'Locksmith: invalid signature'
                    );
                });

                describe(`[${tier}] on success, qty=${quantity}`, function () {
                    before(async function () {
                        await doDeploy.bind(this)();
                        await doSetCratesAsKeysOwner.bind(this)();
                        await doSetCratesAsInventoryMinter.bind(this)();
                        await this.locksmith.setSignerKey(signer1, {from: deployer});
                        await this.crateKeys[tier].approve(this.locksmith.address, MaxUInt256, {from: holder});

                        this.nonce = await this.locksmith.nonces(holder, crate.tier);
                        const payloadHash = await createPayloadHash(holder, crate.tier, this.nonce);
                        this.signature = fixSignature(await web3.eth.sign(payloadHash, signer1));
                        this.receipt = await this.locksmith.insertKeys(crate.tier, quantity, this.signature, {
                            from: holder,
                        });
                        this.gasUsed = this.receipt.receipt.gasUsed;
                    });

                    it(`[${tier}] should update the nonce, qty=${quantity}`, async function () {
                        const nonce = await this.locksmith.nonces(holder, crate.tier);
                        nonce.should.be.bignumber.equal(this.nonce.add(One));
                    });

                    it(`[${tier}] should fail if trying to use the same signature again, qty=${quantity}`, async function () {
                        await expectRevert(
                            this.locksmith.insertKeys(crate.tier, 1, this.signature, {from: holder}),
                            'Locksmith: invalid signature'
                        );
                    });

                    it(`[${tier}] should cost less gas the second time, qty=${quantity}`, async function () {
                        this.nonce = await this.locksmith.nonces(holder, crate.tier);
                        const payloadHash = await createPayloadHash(holder, crate.tier, this.nonce);
                        this.signature = fixSignature(await web3.eth.sign(payloadHash, signer1));
                        const newReceipt = await this.locksmith.insertKeys(crate.tier, quantity, this.signature, {
                            from: holder,
                        });
                        const newGasUsed = newReceipt.receipt.gasUsed;
                        console.log(
                            `Opening ${quantity} ${tier} crates: Bootstrap gas cost: ${this.gasUsed}, later: ${newGasUsed}`
                        );
                        newGasUsed.should.be.lt(this.gasUsed);
                    });
                });
            }
        }
    });
});
