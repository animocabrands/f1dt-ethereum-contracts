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

module.exports = {
    computeSupply,
    validateSupplies,
}
