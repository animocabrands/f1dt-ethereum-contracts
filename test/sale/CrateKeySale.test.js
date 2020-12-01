const {accounts, contract} = require('@openzeppelin/test-environment');
const {BN, expectEvent, expectRevert} = require('@openzeppelin/test-helpers');
const {toWei} = require('web3-utils');
const {ZeroAddress, Zero, One, Two} = require('@animoca/ethereum-contracts-core_library').constants;
const {stringToBytes32} = require('@animoca/ethereum-contracts-sale_base/test/utils/bytes32');

const Sale = contract.fromArtifact('CrateKeySale');
const CrateKey = contract.fromArtifact('F1DTCrateKey');
const PrePaid = contract.fromArtifact('PrePaid');
const REVV = contract.fromArtifact('REVV');

const [deployer, purchaser, holder] = accounts;

const sku = stringToBytes32('sku');

describe('CrateKeySale', function () {
    async function doDeploy(overrides = {}) {
        this.revv = await REVV.new(overrides.revvHolders || [purchaser], overrides.revvAmounts || [toWei('1000')], {
            from: overrides.deployer || deployer,
        });

        this.prepaid = await PrePaid.new(this.revv.address, {
            from: overrides.deployer || deployer,
        });

        this.sale = await Sale.new(this.prepaid.address, {
            from: overrides.deployer || deployer,
        });

        this.crateKey = await CrateKey.new(
            overrides.crateKeySymbol || 'CK',
            overrides.crateKeyName || 'Crate Key',
            overrides.crateKeyHolder || holder,
            overrides.crateKeySupply || new BN(10),
            {
                from: overrides.deployer || deployer,
            }
        );
    }

    async function doStartPrepaidPeriod(overrides = {}) {
        await this.prepaid.unpause({from: overrides.deployer || deployer});
    }

    async function doWhitelistSaleContract(overrides = {}) {
        await this.prepaid.whitelistOperator(
            this.sale.address,
            overrides.enabled == undefined || overrides.enabled == null ? true : overrides.enabled,
            {
                from: overrides.deployer || deployer,
            }
        );
    }

    async function doCreateSku(overrides = {}) {
        await this.crateKey.approve(this.sale.address, overrides.skuCapacity || One, {from: holder});
        await this.sale.createCrateKeySku(
            overrides.sku || sku,
            overrides.skuCapacity || One,
            overrides.skuTokenCapacity || One,
            this.crateKey.address,
            {from: overrides.deployer || deployer}
        );
    }

    async function doStartSalePeriod(overrides = {}) {
        const prepaidPaused = await this.prepaid.paused();

        if (prepaidPaused) {
            await doStartPrepaidPeriod.bind(this)(overrides);
        }

        const isSalePrepaidOperator = await this.prepaid.isOperator(this.sale.address);

        if (!isSalePrepaidOperator) {
            await doWhitelistSaleContract.bind(this)(overrides);
        }

        await this.sale.start({
            from: overrides.deployer || deployer,
        });
    }

    describe('constructor()', function () {
        it('reverts if the prepaid address is the zero address', async function () {
            const revert = Sale.new(ZeroAddress, {from: deployer});
            await expectRevert(revert, 'CrateKeySale: zero address');
        });

        it('stores the PrePaid contract reference', async function () {
            await doDeploy.bind(this)();
            const prepaid = await this.sale.prepaid();
            prepaid.should.equal(this.prepaid.address);
        });
    });

    describe('start()', function () {
        beforeEach(async function () {
            await doDeploy.bind(this)();
        });

        it('reverts if the prepaid contract is paused', async function () {
            const revert = this.sale.start({from: deployer});
            await expectRevert(revert, 'CrateKeySale: PrePaid contract paused');
        });

        it('reverts if the sale contract is not whitelisted with the prepaid contract', async function () {
            await this.prepaid.unpause({from: deployer});
            const revert = this.sale.start({from: deployer});
            await expectRevert(revert, 'CrateKeySale: sale contract is not operator');
        });

        it('reverts if called by any other than the contract owner', async function () {
            const revert = this.sale.start();
            await expectRevert(revert, 'Ownable: caller is not the owner');
        });

        it('reverts if the contract has already been started', async function () {
            await doStartPrepaidPeriod.bind(this)();
            await doWhitelistSaleContract.bind(this)();
            this.sale.start({from: deployer});
            const revert = this.sale.start({from: deployer});
            await expectRevert(revert, 'Startable: started');
        });

        it('starts the contract', async function () {
            const startedAtBefore = await this.sale.startedAt();
            startedAtBefore.should.be.bignumber.equal(Zero);
            await doStartSalePeriod.bind(this)();
            const startedAtAfter = await this.sale.startedAt();
            startedAtAfter.should.be.bignumber.not.equal(Zero);
        });

        it('emits the Started event', async function () {
            await doStartPrepaidPeriod.bind(this)();
            await doWhitelistSaleContract.bind(this)();
            const receipt = await this.sale.start({from: deployer});
            expectEvent(receipt, 'Started', {account: deployer});
        });

        it('emits the Unpaused event', async function () {
            await doStartPrepaidPeriod.bind(this)();
            await doWhitelistSaleContract.bind(this)();
            const receipt = await this.sale.start({from: deployer});
            expectEvent(receipt, 'Unpaused', {account: deployer});
        });

        describe('prepaid sale state', function () {
            it('starts the prepaid contract sale period if the prepaid state is BEFORE_SALE_STATE', async function () {
                await doStartPrepaidPeriod.bind(this)();
                await doWhitelistSaleContract.bind(this)();
                const prepaidBeforeSaleState = await this.prepaid.BEFORE_SALE_STATE();
                const prepaidSaleStartState = await this.prepaid.SALE_START_STATE();
                const stateBefore = await this.prepaid.state();
                stateBefore.should.be.bignumber.equal(prepaidBeforeSaleState);
                const receipt = await this.sale.start({from: deployer});
                expectEvent.inTransaction(receipt.tx, this.prepaid, 'StateChanged', {state: prepaidSaleStartState});
                const stateAfter = await this.prepaid.state();
                stateAfter.should.be.bignumber.equal(prepaidSaleStartState);
            });

            it('does not start the prepaid contract sale period if the prepaid state is SALE_START_STATE', async function () {
                await doStartPrepaidPeriod.bind(this)();
                await doWhitelistSaleContract.bind(this)();
                const prepaidSaleStartState = await this.prepaid.SALE_START_STATE();
                await this.prepaid.setSaleState(prepaidSaleStartState, {from: deployer});
                const stateBefore = await this.prepaid.state();
                stateBefore.should.be.bignumber.equal(prepaidSaleStartState);
                const receipt = await this.sale.start({from: deployer});
                expectEvent.notEmitted(receipt, 'StateChanged');
                const stateAfter = await this.prepaid.state();
                stateAfter.should.be.bignumber.equal(prepaidSaleStartState);
            });

            it('reverts if the prepaid contract state is SALE_END_STATE', async function () {
                await doStartPrepaidPeriod.bind(this)();
                await doWhitelistSaleContract.bind(this)();
                const prepaidSaleEndState = await this.prepaid.SALE_END_STATE();
                await this.prepaid.setSaleState(prepaidSaleEndState, {from: deployer});
                const stateBefore = await this.prepaid.state();
                stateBefore.should.be.bignumber.equal(prepaidSaleEndState);
                const revert = this.sale.start({from: deployer});
                await expectRevert(revert, 'CrateKeySale: invalid PrePaid state');
            });
        });
    });

    describe('createSku()', function () {
        it('reverts if called', async function () {
            await doDeploy.bind(this)();
            const revert = this.sale.createSku(sku, One, One, ZeroAddress, {from: deployer});
            await expectRevert(
                revert,
                'Deprecated. Please use `createCrateKeySku(bytes32, uint256, uint256, IF1DTCrateKey)`'
            );
        });
    });

    describe('createCrateKeySku', function () {
        beforeEach(async function () {
            await doDeploy.bind(this)();
        });

        it('reverts if called by any other than the contract owner', async function () {
            const revert = this.sale.createCrateKeySku(sku, One, One, this.crateKey.address);
            await expectRevert(revert, 'Ownable: caller is not the owner');
        });

        it('reverts if the total supply is unlimited', async function () {
            const totalSupply = await this.sale.SUPPLY_UNLIMITED();
            const revert = this.sale.createCrateKeySku(sku, totalSupply, One, this.crateKey.address, {from: deployer});
            await expectRevert(revert, 'CrateKeySale: invalid total supply');
        });

        it('reverts if the crate key is the zero address', async function () {
            const revert = this.sale.createCrateKeySku(sku, One, One, ZeroAddress, {from: deployer});
            await expectRevert(revert, 'CrateKeySale: zero address');
        });

        it('reverts if the sku already exists', async function () {
            await this.crateKey.approve(this.sale.address, One, {from: holder});
            await this.sale.createCrateKeySku(sku, One, One, this.crateKey.address, {from: deployer});
            const revert = this.sale.createCrateKeySku(sku, One, One, this.crateKey.address, {from: deployer});
            await expectRevert(revert, 'Sale: sku already created');
        });

        it('reverts if total supply is zero', async function () {
            const revert = this.sale.createCrateKeySku(sku, Zero, One, this.crateKey.address, {from: deployer});
            await expectRevert(revert, 'Sale: zero supply');
        });

        it('reverts if creating more than the fixed SKU capacity of 4', async function () {
            for (let index = 0; index < 4; ++index) {
                const crateKey = await CrateKey.new('CK', 'Crate Key', holder, new BN(10), {from: deployer});
                const sku = stringToBytes32(`sku${index}`);
                await crateKey.approve(this.sale.address, One, {from: holder});
                await this.sale.createCrateKeySku(sku, One, One, crateKey.address, {from: deployer});
            }
            const crateKey = await CrateKey.new('CK', 'Crate Key', holder, new BN(10), {from: deployer});
            const sku = stringToBytes32(`exceededSkuCapacity`);
            const revert = this.sale.createCrateKeySku(sku, One, One, crateKey.address, {from: deployer});
            await expectRevert(revert, 'Sale: too many skus');
        });

        it('creates the sku', async function () {
            await this.crateKey.approve(this.sale.address, One, {from: holder});
            const receipt = await this.sale.createCrateKeySku(sku, One, One, this.crateKey.address, {from: deployer});
            expectEvent(receipt, 'SkuCreation', {
                sku: sku,
                totalSupply: One,
                maxQuantityPerPurchase: One,
                notificationsReceiver: ZeroAddress,
            });
        });

        describe('crate key holder token balance', function () {
            it('reverts if the crate key holder token balance is less than SKU total supply', async function () {
                const balance = await this.crateKey.balanceOf(holder);
                await this.crateKey.approve(this.sale.address, balance, {from: holder});
                const totalSupply = balance.addn(1);
                const revert = this.sale.createCrateKeySku(sku, totalSupply, One, this.crateKey.address, {
                    from: deployer,
                });
                await expectRevert(revert, 'CrateKeySale: insufficient balance');
            });

            it('creates the sku if the crate key holder token balance equals the SKU total supply', async function () {
                const balance = await this.crateKey.balanceOf(holder);
                await this.crateKey.approve(this.sale.address, balance, {from: holder});
                const totalSupply = balance;
                const receipt = await this.sale.createCrateKeySku(sku, totalSupply, One, this.crateKey.address, {
                    from: deployer,
                });
                expectEvent(receipt, 'SkuCreation', {
                    sku: sku,
                    totalSupply: totalSupply,
                    maxQuantityPerPurchase: One,
                    notificationsReceiver: ZeroAddress,
                });
            });

            it('creates the sku if the crate key holder token balance is more than the SKU total supply', async function () {
                const balance = await this.crateKey.balanceOf(holder);
                await this.crateKey.approve(this.sale.address, balance, {from: holder});
                const totalSupply = balance.subn(1);
                const receipt = await this.sale.createCrateKeySku(sku, totalSupply, One, this.crateKey.address, {
                    from: deployer,
                });
                expectEvent(receipt, 'SkuCreation', {
                    sku: sku,
                    totalSupply: totalSupply,
                    maxQuantityPerPurchase: One,
                    notificationsReceiver: ZeroAddress,
                });
            });
        });

        describe('sale contract crate key allowance', function () {
            it('reverts if the sale contract has a crate key allowance less than the SKU total supply', async function () {
                const totalSupply = Two;
                const allowance = totalSupply.subn(1);
                await this.crateKey.approve(this.sale.address, allowance, {from: holder});
                const revert = this.sale.createCrateKeySku(sku, totalSupply, One, this.crateKey.address, {
                    from: deployer,
                });
                await expectRevert(revert, 'CrateKeySale: invalid allowance');
            });

            it('creates the sku if the sale contract has a crate key allowance equals the SKU total supply', async function () {
                const totalSupply = Two;
                const allowance = totalSupply;
                await this.crateKey.approve(this.sale.address, allowance, {from: holder});
                const receipt = await this.sale.createCrateKeySku(sku, totalSupply, One, this.crateKey.address, {
                    from: deployer,
                });
                expectEvent(receipt, 'SkuCreation', {
                    sku: sku,
                    totalSupply: totalSupply,
                    maxQuantityPerPurchase: One,
                    notificationsReceiver: ZeroAddress,
                });
            });

            it('creates the sku if the sale contract has a crate key allowance greater than the SKU total supply', async function () {
                const totalSupply = Two;
                const allowance = totalSupply.addn(1);
                await this.crateKey.approve(this.sale.address, allowance, {from: holder});
                const receipt = await this.sale.createCrateKeySku(sku, totalSupply, One, this.crateKey.address, {
                    from: deployer,
                });
                expectEvent(receipt, 'SkuCreation', {
                    sku: sku,
                    totalSupply: totalSupply,
                    maxQuantityPerPurchase: One,
                    notificationsReceiver: ZeroAddress,
                });
            });
        });

        it('binds the crate key with the sku', async function () {
            const crateKeyBefore = await this.sale.crateKeys(sku);
            crateKeyBefore.should.equal(ZeroAddress);
            await this.crateKey.approve(this.sale.address, One, {from: holder});
            await this.sale.createCrateKeySku(sku, One, One, this.crateKey.address, {from: deployer});
            const crateKeyAfter = await this.sale.crateKeys(sku);
            crateKeyAfter.should.equal(this.crateKey.address);
        });
    });

    describe('updateSkuPricing()', function () {
        it('reverts if setting the price with a token that exceeds the fixed SKU token capacity of 1', async function () {
            await doDeploy.bind(this)();
            await doCreateSku.bind(this)();
            const otherErc20 = await REVV.new([purchaser], [toWei('1000')], {from: deployer});
            const revert = this.sale.updateSkuPricing(sku, [this.revv.address, otherErc20.address], [One, One], {
                from: deployer,
            });
            await expectRevert(revert, 'Sale: too many tokens');
        });
    });

    describe('_payment()', function () {
        it('reverts if the purchaser has no prepaid amount deposited', async function () {
            // TODO:
        });

        it('reverts if the purchaser has an insufficient prepaid deposit for the purchase', async function () {
            // TODO:
        });

        it("purchases with the purchaser's prepaid deposit", async function () {
            // TODO:
        });
    });

    describe('_delivery()', function () {
        it('reverts if the holder has an insufficient crate key token balance for delivery', async function () {
            // TODO:
        });

        it('reverts if the sale contract has an insufficient crate key token allowance for delivery', async function () {
            // TODO:
        });
    });
});
