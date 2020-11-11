const {accounts, contract, web3} = require('@openzeppelin/test-environment');
const {expect} = require('chai');
const {ether, expectEvent, expectRevert, time} = require('@openzeppelin/test-helpers');
const {BN, toAscii, toWei, fromWei} = require('web3-utils');
const {
    ZeroAddress,
    // EthAddress,
    EmptyByte,
    Zero,
    One,
    Two,
    Three,
    Four,
    Five,
    ZeroBytes32,
} = require('@animoca/ethereum-contracts-core_library').constants;

const {
    CycleLengthInSeconds,
    PeriodLengthInCycles,
    WeightsByRarity,
    REVVEscrowingWeightCoefficient,
} = require('../../src/constants');

const {createTokenId, getCoreMetadata} = require('@animoca/f1dt-core_metadata').utils;

const DeltaTimeStaking = contract.fromArtifact('DeltaTimeStaking');
const REVV = contract.fromArtifact('REVV');
const artifactsDir = contract.artifactsDir.toString();
contract.artifactsDir = './imports';
const Bytes = contract.fromArtifact('Bytes');
const DeltaTimeInventory = contract.fromArtifact('DeltaTimeInventory');
contract.artifactsDir = artifactsDir;

const [deployer, staker] = accounts;

const cars = [
    {rarity: '0', type: 'Car', season: '2019', model: 'Carbon', counter: '1'},
    {rarity: '1', type: 'Car', season: '2019', model: 'Carbon', counter: '2'},
    {rarity: '2', type: 'Car', season: '2019', model: 'Carbon', counter: '3'},
    {rarity: '3', type: 'Car', season: '2019', model: 'Carbon', counter: '4'},
    {rarity: '5', type: 'Car', season: '2019', model: 'Carbon', counter: '5'},
    {rarity: '8', type: 'Car', season: '2019', model: 'Carbon', counter: '6'},
];

const drivers = [
    {rarity: '0', type: 'Driver', season: '2019', model: 'Jet', counter: '1'},
    {rarity: '1', type: 'Driver', season: '2019', model: 'Jet', counter: '2'},
    {rarity: '2', type: 'Driver', season: '2019', model: 'Jet', counter: '3'},
    {rarity: '3', type: 'Driver', season: '2019', model: 'Jet', counter: '4'},
    {rarity: '5', type: 'Driver', season: '2019', model: 'Jet', counter: '5'},
    {rarity: '8', type: 'Driver', season: '2019', model: 'Jet', counter: '6'},
];

const tokens = cars
        .concat(drivers)
        .map(token => {
            token.id = createTokenId(token, true);

            const rarity = token.type === 'Car' ? (WeightsByRarity[token.rarity] * 2) : WeightsByRarity[token.rarity];
            token.weight = new BN(rarity);
            token.escrow = toWei(token.weight.mul(REVVEscrowingWeightCoefficient));
            return token;
        });

// console.log("=====================================");
// console.log(tokens);
// console.log("=====================================");

const revvForEscrowing = tokens.map(token => token.escrow)
    //.slice(0, -1) // not enough to stake the last car
    .reduce((prev, curr) => prev.add(curr), new BN(0));

describe('DeltaTimeStaking', function () {
    describe('constructor(CycleLengthInSeconds, PeriodLengthInCycles, inventoryContract, revvContract, weights, rarities, revvEscrowingWeightCoefficient)', function () {
        beforeEach(async function () {
            this.revv = await REVV.new([deployer], [revvForEscrowing], {from: deployer});
            this.bytes = await Bytes.new({from: deployer});
            DeltaTimeInventory.network_id = 1337;
            await DeltaTimeInventory.link('Bytes', this.bytes.address);
            this.inventory = await DeltaTimeInventory.new(this.revv.address, ZeroAddress, {from: deployer});
        });
        it('should revert with a zero weight coefficient', async function () {
            await expectRevert(
                DeltaTimeStaking.new(
                    CycleLengthInSeconds,
                    PeriodLengthInCycles,
                    this.inventory.address,
                    this.revv.address,
                    Object.keys(WeightsByRarity),
                    Object.values(WeightsByRarity),
                    Zero,
                    {from: deployer}
                ),
                'NftStaking: invalid coefficient'
            );
        });
        it('should revert with a different size of rarities and weights', async function () {
            await expectRevert(
                DeltaTimeStaking.new(
                    CycleLengthInSeconds,
                    PeriodLengthInCycles,
                    this.inventory.address,
                    this.revv.address,
                    Object.keys(WeightsByRarity),
                    [1, 2, 3],
                    revvForEscrowing,
                    {from: deployer}
                ),
                'NftStaking: wrong arguments'
            );
        });
        it('should revert with a zero item into weights', async function () {
            await expectRevert(
                DeltaTimeStaking.new(
                    CycleLengthInSeconds,
                    PeriodLengthInCycles,
                    this.inventory.address,
                    this.revv.address,
                    Object.keys(WeightsByRarity),
                    Object.values(WeightsByRarity).map((x) => 0),
                    revvForEscrowing,
                    {from: deployer}
                ),
                'NftStaking: invalid weight value'
            );
        });
        it('should deploy with correct parameters', async function () {
            await DeltaTimeStaking.new(
                CycleLengthInSeconds,
                PeriodLengthInCycles,
                this.inventory.address,
                this.revv.address,
                Object.keys(WeightsByRarity),
                Object.values(WeightsByRarity),
                revvForEscrowing,
                {from: deployer});
        });
    });

    describe('escrowing', function () {
        beforeEach(async function () {
            this.revv = await REVV.new([staker], [revvForEscrowing], {from: deployer});
            this.bytes = await Bytes.new({from: deployer});

            DeltaTimeInventory.network_id = 1337;
            await DeltaTimeInventory.link('Bytes', this.bytes.address);

            this.inventory = await DeltaTimeInventory.new(this.revv.address, ZeroAddress, {from: deployer});

            // ========================================================================
            // console.log("===================== BEFORE =====================");
            // console.log("[ Staker ]");
            // console.log("address: " + staker);
            // const stakerBalanceBefore = await this.revv.balanceOf(staker);
            // console.log("balance revv: " + stakerBalanceBefore.toString());

            // console.log("[ Escrow Param ]");
            // console.log("revvForEscrowing: " + revvForEscrowing.toString());
            // console.log(" ");
            // ========================================================================

            await this.inventory.batchMint(
                tokens.map(() => staker),
                tokens.map(token => token.id),
                tokens.map(() => ZeroBytes32),
                tokens.map(() => 1),
                true,
                {from: deployer}
            );

            this.staking = await DeltaTimeStaking.new(
                CycleLengthInSeconds,
                PeriodLengthInCycles,
                this.inventory.address,
                this.revv.address,
                Object.keys(WeightsByRarity),
                Object.values(WeightsByRarity),
                toWei(REVVEscrowingWeightCoefficient),
                {from: deployer}
            );

            await this.revv.whitelistOperator(this.staking.address, true, {from: deployer});
            await this.staking.start({from: deployer});

            // ========================================================================
            // console.log("===================== AFTER =====================");
            // console.log("[ Staker ]");
            // console.log("address: " + staker);
            // const stakerBalanceAfter = await this.revv.balanceOf(staker);
            // console.log("balance revv: " + stakerBalanceAfter.toString());

            // console.log("[ DeltaTimeStaking ]");
            // const contractBalanceAfter = await this.revv.balanceOf(this.staking.address);
            // console.log("balance revv: " + contractBalanceAfter.toString());

            // console.log("[ DeltaTimeInventory ]");
            // const assetBalanceStakerAfter = await this.inventory.balanceOf(staker);
            // console.log("assetBalance staker: " + assetBalanceStakerAfter.toString());

            // const assetBalanceStakingAfter = await this.inventory.balanceOf(this.staking.address);
            // console.log("assetBalance staking: " + assetBalanceStakingAfter.toString());

            // console.log("[ Escrow Param ]");
            // console.log("revvForEscrowing: " + revvForEscrowing.toString());
            // console.log(" ");
            // ========================================================================
        });

        describe('staking', function () {
            it('should execute single stake and escrow REVV', async function () {

                await this.inventory.methods['safeTransferFrom(address,address,uint256,uint256,bytes)'](
                    staker,
                    this.staking.address,
                    tokens[0].id,
                    1,
                    '0x0',
                    {
                        from: staker,
                    }
                );

                // ========================================================================
                // console.log("===================== AFTER STAKING =====================");
                // console.log("[ Staker ]");
                // console.log("address: " + staker);
                // const stakerBalanceAfter = await this.revv.balanceOf(staker);
                // console.log("balance revv: " + stakerBalanceAfter.toString());

                // console.log("[ DeltaTimeStaking ]");
                // const contractBalanceAfter = await this.revv.balanceOf(this.staking.address);
                // console.log("balance revv: " + contractBalanceAfter.toString());

                // console.log("[ DeltaTimeInventory ]");
                // const assetBalanceStakerAfter = await this.inventory.balanceOf(staker);
                // console.log("assetBalance staker: " + assetBalanceStakerAfter.toString());

                // const assetBalanceStakingAfter = await this.inventory.balanceOf(this.staking.address);
                // console.log("assetBalance staking: " + assetBalanceStakingAfter.toString());

                // console.log("[ Escrow Param ]");
                // console.log("revvForEscrowing: " + revvForEscrowing.toString());

                // console.log("[ Token Param ]");
                // console.log("revvEscrowValuesCheck: " + tokens[0].escrow);

                // console.log(" ");
                // ========================================================================

                const contractBalance = await this.revv.balanceOf(this.staking.address);
                contractBalance.should.be.bignumber.equal(tokens[0].escrow);
            });

            it('should execute batch stake and escrow REVV', async function () {
                const params = [tokens[0], tokens[1], tokens[3]];

                await this.inventory.methods['safeBatchTransferFrom(address,address,uint256[],uint256[],bytes)'](
                    staker,
                    this.staking.address,
                    params.map(token => token.id),
                    params.map(() => 1),
                    '0x0',
                    {
                        from: staker,
                    }
                );
                const contractBalance = await this.revv.balanceOf(this.staking.address);
                const revvEscrowValues = params.map(token => token.escrow).reduce((prev, cur) => prev.add(cur), new BN(0));
                
                contractBalance.should.be.bignumber.equal(revvEscrowValues);
            });

            // TODO - Not reverting

            // it('should fail if not enough REVV to escrow', async function () {
            //     await expectRevert(
            //         this.inventory.methods['safeBatchTransferFrom(address,address,uint256[],uint256[],bytes)'](
            //             staker,
            //             this.staking.address,
            //             tokens.map(token => token.id),
            //             tokens.map(() => 1),
            //             '0x0',
            //             {
            //                 from: staker,
            //             }
            //         ),
            //         'ERC20: transfer amount exceeds balance'
            //     );
            // });
        });
        describe('unstaking', function () {
            it('should execute single unstake and unescrow REVV', async function () {
                await this.inventory.methods['safeTransferFrom(address,address,uint256,uint256,bytes)'](
                    staker,
                    this.staking.address,
                    tokens[0].id,
                    1,
                    '0x0',
                    {
                        from: staker,
                    }
                );
                time.increase(CycleLengthInSeconds.mul(Two));
                await this.staking.unstakeNft(tokens[0].id, {from: staker});
                
                const contractBalance = await this.revv.balanceOf(this.staking.address);
                contractBalance.should.be.bignumber.equal(Zero);

                const stakerBalance = await this.revv.balanceOf(staker);
                stakerBalance.should.be.bignumber.equal(revvForEscrowing); // full balance
            });

            it('should execute batch unstake and unescrow REVV', async function () {
                const params = [tokens[0], tokens[1], tokens[3]];

                await this.inventory.methods['safeBatchTransferFrom(address,address,uint256[],uint256[],bytes)'](
                    staker,
                    this.staking.address,
                    params.map(token => token.id),
                    params.map(() => 1),
                    '0x0',
                    {
                        from: staker,
                    }
                );
                time.increase(CycleLengthInSeconds.mul(Two));
                await this.staking.batchUnstakeNfts(params.map(token => token.id), {from: staker});
                
                const contractBalance = await this.revv.balanceOf(this.staking.address);
                contractBalance.should.be.bignumber.equal(Zero);

                const stakerBalance = await this.revv.balanceOf(staker);
                stakerBalance.should.be.bignumber.equal(revvForEscrowing); // full balance
            });
        });
    });
});
