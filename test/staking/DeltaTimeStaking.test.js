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

const Rarities = {
    Common: 1,
    Epic: 2,
    Legendary: 3,
    Apex: 4,
};

const RarityWeights = [
    {
        rarity: Rarities.Common,
        weight: 1,
    },
    {
        rarity: Rarities.Epic,
        weight: 10,
    },
    {
        rarity: Rarities.Legendary,
        weight: 100,
    },
    {
        rarity: Rarities.Apex,
        weight: 500,
    },
];

const cars = [
    {rarity: Rarities.Common, type: 'Car', season: '2019', model: 'Carbon', counter: '1'},
    {rarity: Rarities.Epic, type: 'Car', season: '2019', model: 'Carbon', counter: '2'},
    {rarity: Rarities.Legendary, type: 'Car', season: '2019', model: 'Carbon', counter: '3'},
    {rarity: Rarities.Apex, type: 'Car', season: '2019', model: 'Carbon', counter: '4'},
];

const drivers = [
    {rarity: Rarities.Common, type: 'Driver', season: '2019', model: 'Jet', counter: '1'},
    {rarity: Rarities.Epic, type: 'Driver', season: '2019', model: 'Jet', counter: '2'},
    {rarity: Rarities.Legendary, type: 'Driver', season: '2019', model: 'Jet', counter: '3'},
    {rarity: Rarities.Apex, type: 'Driver', season: '2019', model: 'Jet', counter: '4'},
];

const tokens = cars.concat(drivers);
const tokenIds = tokens.map((item) => createTokenId(item, true));

const weights = tokens.map((item) => new BN(WeightsByRarity[item.rarity]));
const revvEscrowValues = weights.map((weight) => toWei(weight.mul(REVVEscrowingWeightCoefficient)));

const revvForEscrowing = revvEscrowValues
    .slice(0, -1) // not enough to stake the last car
    .reduce((prev, curr) => prev.add(curr), new BN(0));

describe('DeltaTimeStaking', function () {
    // describe('constructor(CycleLengthInSeconds, PeriodLengthInCycles, inventoryContract, revvContract, weights, rarities, revvEscrowingWeightCoefficient)', function () {
    //     beforeEach(async function () {
    //         this.revv = await REVV.new([deployer], [revvForEscrowing], {from: deployer});
    //     });
    //     it('should revert with a zero weight coefficient', async function () {
    //         await expectRevert(
    //             DeltaTimeStaking.new(
    //                 CycleLengthInSeconds,
    //                 PeriodLengthInCycles,
    //                 this.revv.address,
    //                 this.revv.address,
    //                 RarityWeights.map((x) => x.rarity),
    //                 RarityWeights.map((x) => x.weight),
    //                 Zero,
    //                 {from: deployer}
    //             ),
    //             'NftStaking: invalid coefficient'
    //         );
    //     });
    //     it('should deploy with correct parameters', async function () {
    //         await DeltaTimeStaking.new(
    //             CycleLengthInSeconds,
    //             PeriodLengthInCycles,
    //             this.revv.address,
    //             this.revv.address,
    //             RarityWeights.map((x) => x.rarity),
    //             RarityWeights.map((x) => x.weight),
    //             revvForEscrowing,
    //             {from: deployer});
    //     });
    // });

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
                RarityWeights.map((x) => x.rarity),
                RarityWeights.map((x) => x.weight),
                toWei(REVVEscrowingWeightCoefficient),
                {from: deployer}
            );
            await this.revv.whitelistOperator(this.staking.address, true, {from: deployer});
            await this.staking.start({from: deployer});
        });

        describe('staking', function () {
            it('should execute single stake and escrow REVV', async function () {

                console.log("=========================");
                console.log(revvEscrowValues[0]);
                console.log("=========================");

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

            // it('should execute batch stake and escrow REVV', async function () {
            //     await this.inventory.methods['safeBatchTransferFrom(address,address,uint256[],uint256[],bytes)'](
            //         staker,
            //         this.staking.address,
            //         [tokenIds[0], tokenIds[1], tokenIds[3]],
            //         [1, 1, 1],
            //         '0x0',
            //         {
            //             from: staker,
            //         }
            //     );
            //     const contractBalance = await this.revv.balanceOf(this.staking.address);
            //     contractBalance.should.be.bignumber.equal(
            //         revvEscrowValues[0].add(revvEscrowValues[1]).add(revvEscrowValues[2])
            //     );
            // });

            // it('should fail if not enough REVV to escrow', async function () {
            //     await expectRevert(
            //         this.inventory.methods['safeBatchTransferFrom(address,address,uint256[],uint256[],bytes)'](
            //             staker,
            //             this.staking.address,
            //             tokenIds,
            //             tokenIds.map(() => 1),
            //             '0x0',
            //             {
            //                 from: staker,
            //             }
            //         ),
            //         'ERC20: transfer amount exceeds balance'
            //     );
            // });
        });
        // describe('unstaking', function () {
        //     it('should execute single unstake and unescrow REVV', async function () {
        //         await this.inventory.methods['safeTransferFrom(address,address,uint256,uint256,bytes)'](
        //             staker,
        //             this.staking.address,
        //             tokenIds[0],
        //             1,
        //             '0x0',
        //             {
        //                 from: staker,
        //             }
        //         );
        //         time.increase(CycleLengthInSeconds.mul(Two));
        //         await this.staking.unstakeNft(tokenIds[0], {from: staker});
        //         const contractBalance = await this.revv.balanceOf(this.staking.address);
        //         contractBalance.should.be.bignumber.equal(Zero);
        //         const stakerBalance = await this.revv.balanceOf(staker);
        //         stakerBalance.should.be.bignumber.equal(revvForEscrowing); // full balance
        //     });

        //     it('should execute batch unstake and unescrow REVV', async function () {
        //         await this.inventory.methods['safeBatchTransferFrom(address,address,uint256[],uint256[],bytes)'](
        //             staker,
        //             this.staking.address,
        //             [tokenIds[0], tokenIds[1], tokenIds[3]],
        //             [1, 1, 1],
        //             '0x0',
        //             {
        //                 from: staker,
        //             }
        //         );
        //         time.increase(CycleLengthInSeconds.mul(Two));
        //         await this.staking.batchUnstakeNfts([tokenIds[0], tokenIds[1], tokenIds[3]], {from: staker});
        //         const contractBalance = await this.revv.balanceOf(this.staking.address);
        //         contractBalance.should.be.bignumber.equal(Zero);
        //         const stakerBalance = await this.revv.balanceOf(staker);
        //         stakerBalance.should.be.bignumber.equal(revvForEscrowing); // full balance
        //     });
        // });
    });
});
