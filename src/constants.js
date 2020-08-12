const {toWei} = require('web3-utils');
const {BN} = require('@openzeppelin/test-helpers');
const {rewardsPoolFromSchedule} = require('@animoca/ethereum-contracts-nft_staking').utils;
const {ZeroAddress} = require('@animoca/ethereum-contracts-core_library').constants;
const {stringToBytes32} = require('./utils');

const MetaTxPayoutWallet = '0x925C5d704193c8ED414bB0973a198185ad19AD8E'; // dummy address

const CycleLengthInSeconds = new BN(60 * 60 * 24); // 1 day
const PeriodLengthInCycles = new BN(7); // 1 week

const WeightsByRarity = {
    0: 500, // Apex,
    1: 100, // Legendary,
    2: 50, // Epic,
    3: 50, // Epic,
    4: 10, // Rare,
    5: 10, // Rare,
    6: 10, // Rare,
    7: 1, // Common,
    8: 1, // Common,
    9: 1, // Common,
};

const RewardsSchedule = [
    {startPeriod: 1, endPeriod: 4, payoutPerCycle: toWei('150000')},
    {startPeriod: 5, endPeriod: 5, payoutPerCycle: toWei('120000')},
    {startPeriod: 6, endPeriod: 6, payoutPerCycle: toWei('115000')},
    {startPeriod: 7, endPeriod: 7, payoutPerCycle: toWei('110000')},
    {startPeriod: 8, endPeriod: 8, payoutPerCycle: toWei('105000')},
    {startPeriod: 9, endPeriod: 9, payoutPerCycle: toWei('100000')},
    {startPeriod: 10, endPeriod: 10, payoutPerCycle: toWei('95000')},
    {startPeriod: 11, endPeriod: 11, payoutPerCycle: toWei('92000')},
    {startPeriod: 12, endPeriod: 12, payoutPerCycle: toWei('91600')},
];
const RewardsPool = rewardsPoolFromSchedule(RewardsSchedule, PeriodLengthInCycles);

const QualifyingGameSalePrices = [
    {sku: stringToBytes32('qualifying game'), ethPrice: toWei('0.01'), revvPrice: toWei('1')}
];
const QualifyingGameSalePayoutWallet = '0x925C5d704193c8ED414bB0973a198185ad19AD8E'; // dummy address
const QualifyingGameSalePayoutToken = '0x925C5d704193c8ED414bB0973a198185ad19AD8E'; // dummy address

module.exports = {
    MetaTxPayoutWallet,
    CycleLengthInSeconds,
    PeriodLengthInCycles,
    WeightsByRarity,
    RewardsSchedule,
    RewardsPool,
    QualifyingGameSalePrices,
    QualifyingGameSalePayoutWallet,
    QualifyingGameSalePayoutToken
};
