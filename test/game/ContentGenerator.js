const {accounts, contract} = require('@openzeppelin/test-environment');
const {expect} = require('chai');
const {expectEvent, expectRevert, time} = require('@openzeppelin/test-helpers');
const {BN, fromAscii, toWei} = require('web3-utils');
const {utils} = require('@animoca/f1dt-core_metadata');
const {ZeroAddress} = require('@animoca/ethereum-contracts-core_library').constants;

const ContentGenerator = contract.fromArtifact('ContentGenerator');

const sampleSize = 5000;

const [deployer, participant] = accounts;

const expectedSupply = {
    Common: {
        byTier: {
            Apex: {min: 0, max: 0},
            Legendary: {min: 0, max: 0.01},
            Epic: {min: 0.1, max: 0.3},
            Rare: {min: 20, max: 26},
            Common: {min: 72, max: 78},
        },
    },
    Legendary: {
        byTier: {
            Apex: {min: 0, max: 0},
            Legendary: {min: 30, max: 40},
            Epic: {min: 30, max: 40},
            Rare: {min: 30, max: 40},
            Common: {min: 0, max: 0},
        },
    },
};

function validateSupply(supply, expectedSupply) {
    for (const [tier, range] of Object.entries(expectedSupply.byTier)) {
        const percentage = supply.supplyByTier[tier] ? (supply.supplyByTier[tier] / supply.total) * 100 : 0;
        console.log(
            `${tier}: expected [${range.min}, ${range.max}]%, got ${supply.supplyByTier[tier] || 0}/${
                supply.total
            } = ${percentage}%`
        );
        percentage.should.be.gte(range.min, 'Supply too low');
        percentage.should.be.lte(range.max, 'Supply too high');
    }
}

function computeSupply(tokens) {
    const result = {
        total: tokens.length,
        supplyByType: {},
        supplyByTier: {},
        supplyByRarity: {},
    };

    for (const token of tokens) {
        let typeSupply = result.supplyByType[token.type];

        result.supplyByType[token.type] = typeSupply ? typeSupply + 1 : 1;

        let tierSupply = result.supplyByTier[token.rarityTier];
        result.supplyByTier[token.rarityTier] = tierSupply ? tierSupply + 1 : 1;

        let raritySupply = result.supplyByRarity[token.rarity];
        result.supplyByRarity[token.rarity] = raritySupply ? raritySupply + 1 : 1;
    }

    return result;
}

describe.only('ContentGenerator', function () {
    describe('enterTier(tierId, deposit)', function () {
        beforeEach(async function () {
            this.generator = await ContentGenerator.new(0, {from: deployer});
        });

        it('racing stats', async function () {
            const stats = await this.generator.generateRacingStats(1, 1, new BN('987875655632534253698768795847'));
            console.log(stats.map((bn) => bn.toString()));
        });

        context('common crates', function () {
            before(async function () {
                this.commonTokens = [];
                for (let i = 0; i < sampleSize; ++i) {
                    const result = await this.generator.generateCommonTokens();
                    for (let j = 0; j < 5; ++j) {
                        const meta = utils.getCoreMetadata(result[j].toString());

                        this.commonTokens.push(meta);
                    }
                    await time.increase();
                }
                this.commonTokensSupply = computeSupply(this.commonTokens);
                console.log(this.commonTokensSupply);
            });

            it('has expected rarity tier proportions', async function() {
                validateSupply(this.commonTokensSupply, expectedSupply.Common);
            });
        });

        context('legendary crates', function () {
            before(async function () {
                this.legendaryTokens = [];
                for (let i = 0; i < sampleSize; ++i) {
                    const result = await this.generator.generateLegendaryTokens();
                    for (let j = 0; j < 5; ++j) {
                        const meta = utils.getCoreMetadata(result[j].toString());

                        this.legendaryTokens.push(meta);
                    }
                    await time.increase();
                }
                this.legendaryTokensSupply = computeSupply(this.legendaryTokens);
                console.log(this.legendaryTokensSupply);
            });

            it('has expected rarity tier proportions', async function() {
                validateSupply(this.legendaryTokensSupply, expectedSupply.Legendary);
            });
        });
    });
});
