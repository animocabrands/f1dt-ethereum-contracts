// refer to https://docs.google.com/spreadsheets/d/146kqi8xS1fLb8IhJO1wx6qZIVMQSvDacTXcTtUtSO3Y/

// TODO confirm values

// section "Type Drop Rates"
const expectedTypes = {
    Car: {min: 8, max: 12}, // 10%
    Driver: {min: 8, max: 12}, // 10%
    Gear: {min: 35, max: 41}, // 38%
    Part: {min: 35, max: 41}, // 38%
    Tyres: {min: 2, max: 6}, // 4%
};

// section "Aggregated Rarity Drop Rates" for the `expectedRarities`
const crates = {
    Legendary: {
        tier: 0,
        expectedRarities: {
            Apex: {min: 0, max: 0},
            Legendary: {min: 18, max: 24},
            Epic: {min: 3, max: 6},
            Rare: {min: 24, max: 29},
            Common: {min: 46, max: 50},
        },
    },
    Epic: {
        tier: 1,
        expectedRarities: {
            Apex: {min: 0, max: 0},
            Legendary: {min: 0, max: 2},
            Epic: {min: 18, max: 24},
            Rare: {min: 15, max: 20},
            Common: {min: 56, max: 63},
        },
    },
    Rare: {
        tier: 2,
        expectedRarities: {
            Apex: {min: 0, max: 0},
            Legendary: {min: 0, max: 1},
            Epic: {min: 0, max: 3},
            Rare: {min: 47, max: 55},
            Common: {min: 44, max: 51},
        },
    },
    Common: {
        tier: 3,
        expectedRarities: {
            Apex: {min: 0, max: 0},
            Legendary: {min: 0, max: 1},
            Epic: {min: 0, max: 1},
            Rare: {min: 21, max: 27},
            Common: {min: 73, max: 79},
        },
    },
};

module.exports = {
    crates,
    expectedTypes,
};
