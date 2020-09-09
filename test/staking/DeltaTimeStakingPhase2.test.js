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

const DeltaTimeStaking = contract.fromArtifact('DeltaTimeStakingPhase2');
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

const tokenIds = cars.map((car) => createTokenId(car, true));

const weights = cars.map((car) => new BN(WeightsByRarity[car.rarity]));
const revvEscrowValues = weights.map((weight) => toWei(weight.mul(REVVEscrowingWeightCoefficient)));

const revvForEscrowing = revvEscrowValues
    .slice(0, -1) // not enough to stake the last car
    .reduce((prev, curr) => prev.add(curr), new BN(0));

describe('DeltaTimeStaking', function () {
    describe('constructor(CycleLengthInSeconds, PeriodLengthInCycles, inventoryContract, revvContract, weights, rarities, revvEscrowingWeightCoefficient)', function () {
        it('should revert with a zero weight coefficient', async function () {
            this.revv = await REVV.new([deployer], [revvForEscrowing], {from: deployer});
            await expectRevert(
                DeltaTimeStaking.new(
                    CycleLengthInSeconds,
                    PeriodLengthInCycles,
                    this.revv.address,
                    this.revv.address,
                    Object.keys(WeightsByRarity),
                    Object.values(WeightsByRarity),
                    Zero,
                    {from: deployer}
                ),
                'NftStaking: invalid coefficient'
            );
        });
    });

    describe('escrowing', function () {
        beforeEach(async function () {
            this.revv = await REVV.new([staker], [revvForEscrowing], {from: deployer});
            this.bytes = await Bytes.new({from: deployer});
            DeltaTimeInventory.network_id = 1337;
            await DeltaTimeInventory.link('Bytes', this.bytes.address);
            this.inventory = await DeltaTimeInventory.new(this.revv.address, ZeroAddress, {from: deployer});
            await this.inventory.batchMint(
                tokenIds.map(() => staker),
                tokenIds,
                tokenIds.map(() => ZeroBytes32),
                tokenIds.map(() => 1),
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
        });

        describe('staking', function () {
            it('should execute single stake and escrow REVV', async function () {
                await this.inventory.methods['safeTransferFrom(address,address,uint256,uint256,bytes)'](
                    staker,
                    this.staking.address,
                    tokenIds[0],
                    1,
                    '0x0',
                    {
                        from: staker,
                    }
                );
                const contractBalance = await this.revv.balanceOf(this.staking.address);
                contractBalance.should.be.bignumber.equal(revvEscrowValues[0]);
            });

            it('should execute batch stake and escrow REVV', async function () {
                await this.inventory.methods['safeBatchTransferFrom(address,address,uint256[],uint256[],bytes)'](
                    staker,
                    this.staking.address,
                    [tokenIds[0], tokenIds[1], tokenIds[3]],
                    [1, 1, 1],
                    '0x0',
                    {
                        from: staker,
                    }
                );
                const contractBalance = await this.revv.balanceOf(this.staking.address);
                contractBalance.should.be.bignumber.equal(
                    revvEscrowValues[0].add(revvEscrowValues[1]).add(revvEscrowValues[2])
                );
            });

            it('should fail if not enough REVV to escrow', async function () {
                await expectRevert(
                    this.inventory.methods['safeBatchTransferFrom(address,address,uint256[],uint256[],bytes)'](
                        staker,
                        this.staking.address,
                        tokenIds,
                        tokenIds.map(() => 1),
                        '0x0',
                        {
                            from: staker,
                        }
                    ),
                    'ERC20: transfer amount exceeds balance'
                );
            });
        });
        describe('unstaking', function () {
            it('should execute single unstake and unescrow REVV', async function () {
                await this.inventory.methods['safeTransferFrom(address,address,uint256,uint256,bytes)'](
                    staker,
                    this.staking.address,
                    tokenIds[0],
                    1,
                    '0x0',
                    {
                        from: staker,
                    }
                );
                time.increase(CycleLengthInSeconds.mul(Two));
                await this.staking.unstakeNft(tokenIds[0], {from: staker});
                const contractBalance = await this.revv.balanceOf(this.staking.address);
                contractBalance.should.be.bignumber.equal(Zero);
                const stakerBalance = await this.revv.balanceOf(staker);
                stakerBalance.should.be.bignumber.equal(revvForEscrowing); // full balance
            });

            it('should execute batch unstake and unescrow REVV', async function () {
                await this.inventory.methods['safeBatchTransferFrom(address,address,uint256[],uint256[],bytes)'](
                    staker,
                    this.staking.address,
                    [tokenIds[0], tokenIds[1], tokenIds[3]],
                    [1, 1, 1],
                    '0x0',
                    {
                        from: staker,
                    }
                );
                time.increase(CycleLengthInSeconds.mul(Two));
                await this.staking.batchUnstakeNfts([tokenIds[0], tokenIds[1], tokenIds[3]], {from: staker});
                const contractBalance = await this.revv.balanceOf(this.staking.address);
                contractBalance.should.be.bignumber.equal(Zero);
                const stakerBalance = await this.revv.balanceOf(staker);
                stakerBalance.should.be.bignumber.equal(revvForEscrowing); // full balance
            });
        });
    });
});
