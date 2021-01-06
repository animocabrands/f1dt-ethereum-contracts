// refer to https://docs.google.com/spreadsheets/d/146kqi8xS1fLb8IhJO1wx6qZIVMQSvDacTXcTtUtSO3Y/

// TODO confirm values

// section "Type Drop Rates"
const expectedTypes = {
    Car: {min: 8, max: 12}, // 10%
    Driver: {min: 8, max: 12}, // 10%
    Gear: {min: 20, max: 24}, // 22%
    Part: {min: 42, max: 46}, // 44%
    Tyres: {min: 12, max: 16}, // 14%
};

// section "Aggregated Rarity Drop Rates" for the `expectedRarities`
const crates = {
    Legendary: {
        tier: 0,
        expectedRarities: {
            Apex: {min: 0, max: 0},
            Legendary: {min: 20, max: 22},
            Epic: {min: 3, max: 5},
            Rare: {min: 24, max: 26},
            Common: {min: 50, max: 51},
        },
    },
    Epic: {
        tier: 1,
        expectedRarities: {
            Apex: {min: 0, max: 0},
            Legendary: {min: 0, max: 1},
            Epic: {min: 21, max: 23},
            Rare: {min: 22, max: 23},
            Common: {min: 55, max: 56},
        },
    },
    Rare: {
        tier: 2,
        expectedRarities: {
            Apex: {min: 0, max: 0},
            Legendary: {min: 0, max: 1},
            Epic: {min: 0, max: 1},
            Rare: {min: 60, max: 61},
            Common: {min: 38, max: 39},
        },
    },
    Common: {
        tier: 3,
        expectedRarities: {
            Apex: {min: 0, max: 0},
            Legendary: {min: 0, max: 1},
            Epic: {min: 0, max: 1},
            Rare: {min: 20, max: 22},
            Common: {min: 78, max: 80},
        },
    },
};

module.exports = {
    crates,
    expectedTypes,
};
