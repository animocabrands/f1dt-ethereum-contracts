const {toBytes32Attribute} = require('@animoca/ethereum-contracts-assets_inventory').bytes32Attributes;
const {constants, mappings} = require('@animoca/f1dt-core_metadata');

const DeltaTimeInventory = artifacts.require('DeltaTimeInventoryV2');
const DeltaTimeCoreMetadata = artifacts.require('DeltaTimeCoreMetadata');

const decodingLayout = [];
let bitIndex = 0;
for (const layoutElement of constants.TokenBitsLayout) {
    decodingLayout.push({
        name: layoutElement.name,
        length: layoutElement.bits,
        index: bitIndex,
    });
    bitIndex += layoutElement.bits;
}

module.exports = async (deployer, _network, _accounts) => {
    const inventoryContract = await DeltaTimeInventory.deployed();

    await deployer.deploy(DeltaTimeCoreMetadata, inventoryContract.address);
    const metadataContract = await DeltaTimeCoreMetadata.deployed();

    console.log('Registering as metadata implementer for DeltaTimeInventory');
    await inventoryContract.setInventoryMetadataImplementer(metadataContract.address);

    for (const collection of mappings.BySeason['2019'].Collection.All) {
        console.log(`Creating collection '${collection.collection}'`);
        await inventoryContract.createCollection(
            collection.collectionId,
            decodingLayout.map((x) => toBytes32Attribute(x.name)),
            decodingLayout.map((x) => x.length),
            decodingLayout.map((x) => x.index)
        );
    }
};
