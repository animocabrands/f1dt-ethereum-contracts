const {mappings} = require('@animoca/f1dt-core_metadata');

function computeSupply(tokens) {
    const result = {
        total: tokens.length,
        supplyByType: {},
        supplyBySubType: {
            Gear: {},
            Part: {},
            Tyres: {},
        },
        supplyByTier: {},
        supplyByRarity: {},
    };

    for (const token of tokens) {
        let typeSupply = result.supplyByType[token.type];

        result.supplyByType[token.type] = typeSupply ? typeSupply + 1 : 1;

        if (token.subType != 'None') {
            let subtypeSupply = result.supplyBySubType[token.type][token.subType];
            result.supplyBySubType[token.type][token.subType] = subtypeSupply ? subtypeSupply + 1 : 1;
        }

        let tierSupply = result.supplyByTier[token.rarityTier];
        result.supplyByTier[token.rarityTier] = tierSupply ? tierSupply + 1 : 1;

        // let raritySupply = result.supplyByRarity[token.rarity];
        // result.supplyByRarity[token.rarity] = raritySupply ? raritySupply + 1 : 1;
    }

    return result;
}

function validateSupplies(supplies, expectedSupplies, totalSupply) {
    for (const [key, range] of Object.entries(expectedSupplies)) {
        const percentage = supplies[key] ? (supplies[key] / totalSupply) * 100 : 0;
        console.log(
            `${key}: expected [${range.min}, ${range.max}]%, got ${supplies[key] || 0}/${totalSupply} = ${percentage}%`
        );
        percentage.should.be.gte(range.min);
        percentage.should.be.lte(range.max);
    }
}

function validateSubTypeSupplies(subTypeSupplies, typeTotalSupply) {
    const expectedPercentage = (1 / Object.keys(subTypeSupplies).length) * 100;
    const range = {
        min: Math.max(expectedPercentage - 2),
        max: expectedPercentage + 2,
    };
    for (const [subType, subTypeSupply] of Object.entries(subTypeSupplies)) {
        const percentage = (subTypeSupply / typeTotalSupply) * 100;
        console.log(
            `${subType}: expected [${range.min}, ${range.max}]%, got ${
                subTypeSupply || 0
            }/${typeTotalSupply} = ${percentage}%`
        );
        percentage.should.be.gte(range.min);
        percentage.should.be.lte(range.max);
    }
}

module.exports = {
    computeSupply,
    validateSupplies,
    validateSubTypeSupplies,
};
