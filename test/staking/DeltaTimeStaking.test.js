const {accounts, contract, web3} = require('@openzeppelin/test-environment');
const {expect} = require('chai');
const {ether, expectEvent, expectRevert, time} = require('@openzeppelin/test-helpers');
const {BN, toAscii, toWei, fromWei} = require('web3-utils');
const {
    ZeroAddress,
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

const tyres = [
    {rarity: '0', type: 'Gear', subType: 'Suit', season: '2019', team: 'None', counter: '1'},
    {rarity: '1', type: 'Gear', subType: 'Suit', season: '2019', team: 'None', counter: '2'},
];

const tokens = cars
    .concat(drivers)
    .map(token => {
        token.id = createTokenId(token, true);

        const weight = token.type === 'Car' ? (WeightsByRarity[token.rarity] * 2) : WeightsByRarity[token.rarity];
        token.weight = new BN(weight);
        token.escrow = toWei(token.weight.mul(REVVEscrowingWeightCoefficient));
        return token;
    });

const invalidTokens = tyres
    .map(token => {
        token.id = createTokenId(token, true);
        token.weight = new BN(WeightsByRarity[token.rarity]);
        token.escrow = toWei(token.weight.mul(REVVEscrowingWeightCoefficient));
        return token;
    });

const revvForEscrowing = tokens
    .map(token => token.escrow)
    .slice(0, 3) // not enough to stake the last item
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
        it('should revert with a weight value out of the allowed range', async function () {
            //Max weight value allowed: uint64 / 2 -> 9223372036854775807
            await expectRevert(
                DeltaTimeStaking.new(
                    CycleLengthInSeconds,
                    PeriodLengthInCycles,
                    this.inventory.address,
                    this.revv.address,
                    [1],
                    ["9223372036854775808"], 
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

            await this.inventory.batchMint(
                invalidTokens.concat(tokens).map(() => staker),
                invalidTokens.concat(tokens).map(token => token.id),
                invalidTokens.concat(tokens).map(() => ZeroBytes32),
                invalidTokens.concat(tokens).map(() => 1),
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
                    tokens[0].id,
                    1,
                    '0x0',
                    {
                        from: staker,
                    }
                );

                const contractBalance = await this.revv.balanceOf(this.staking.address);
                contractBalance.should.be.bignumber.equal(tokens[0].escrow);
            });

            it('should execute batch stake and escrow REVV', async function () {
                const params = [tokens[0], tokens[1], tokens[3]];

                const receipt = await this.inventory.methods['safeBatchTransferFrom(address,address,uint256[],uint256[],bytes)'](
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

                // console.log("==================================");    
                // console.log(receipt);
                // console.log("==================================");

                // Event not available on this TX using this ABI

                // await expectEvent.inTransaction(
                //     receipt.tx,
                //     this.revv,
                //     'Transfer', 
                //     {
                //         _from: staker,
                //         _to: this.staking.address,
                //         _value: tokens[0].escrow
                //     }
                // );
            });

            it('should execute single stake and check for emitted events', async function () {
                    const receipt = await this.inventory.methods['safeTransferFrom(address,address,uint256,uint256,bytes)'](
                        staker,
                        this.staking.address,
                        tokens[0].id,
                        1,
                        '0x0',
                        {
                            from: staker,
                        }
                    );

                    // console.log("==================================");    
                    // console.log(receipt);
                    // console.log("==================================");

                    //safeTransferFrom -> _transferFrom (AssetInventory) -> emit Transfer / TransferSingle
                    //emit Transfer(from, to, tokenId);
                    //emit TransferSingle(sender, from, to, tokenId, 1);

                    await expectEvent(
                        receipt,
                        'Transfer', 
                        {
                            _from: staker,
                            _to: this.staking.address,
                            _tokenId: tokens[0].id
                        }
                    );

                    await expectEvent(
                        receipt,
                        'TransferSingle', 
                        {
                            _from: staker,
                            _to: this.staking.address,
                            _id: tokens[0].id,
                            _value: '1'
                        }
                    );
            });

            it('should fail if not enough REVV to escrow', async function () {
                await expectRevert(
                    this.inventory.methods['safeBatchTransferFrom(address,address,uint256[],uint256[],bytes)'](
                        staker,
                        this.staking.address,
                        tokens.map(token => token.id),
                        tokens.map(() => 1),
                        '0x0',
                        {
                            from: staker,
                        }
                    ),
                    'ERC20: transfer amount exceeds balance'
                );
            });

            it('should fail due to invalid token type', async function () {
                await expectRevert(
                    this.inventory.methods['safeTransferFrom(address,address,uint256,uint256,bytes)'](
                        staker,
                        this.staking.address,
                        invalidTokens[0].id,
                        1,
                        '0x0',
                        {
                            from: staker,
                        }
                    ), 
                    'NftStaking: wrong token'
                );
            });

            it('should fail to execute batch due to invalid token type', async function () {
                await expectRevert(
                    this.inventory.methods['safeBatchTransferFrom(address,address,uint256[],uint256[],bytes)'](
                        staker,
                        this.staking.address,
                        invalidTokens.map(token => token.id),
                        invalidTokens.map(() => 1),
                        '0x0',
                        {
                            from: staker,
                        }
                    ), 
                    'NftStaking: wrong token'
                );
            });
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

                let contractBalance = await this.revv.balanceOf(this.staking.address);
                contractBalance.should.be.bignumber.equal(tokens[0].escrow);
                
                await this.staking.unstakeNft(tokens[0].id, {from: staker});
                contractBalance = await this.revv.balanceOf(this.staking.address);
                
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
                
                let contractBalance = await this.revv.balanceOf(this.staking.address);
                contractBalance.should.be.bignumber.equal(
                    params.map(token => token.escrow).reduce((prev, cur) => prev.add(cur), new BN(0)));
                
                await this.staking.batchUnstakeNfts(params.map(token => token.id), {from: staker});
                
                contractBalance = await this.revv.balanceOf(this.staking.address);
                contractBalance.should.be.bignumber.equal(Zero);

                const stakerBalance = await this.revv.balanceOf(staker);
                stakerBalance.should.be.bignumber.equal(revvForEscrowing); // full balance
            });
        });
    });
});
