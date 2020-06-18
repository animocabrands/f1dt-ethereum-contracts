const { toBytes32Attribute } = require('@animoca/ethereum-contracts-assets_inventory').bytes32Attributes;
const { collections } = require('@animoca/f1dt-core_metadata');

const DeltaTimeInventory = artifacts.require('DeltaTimeInventory');
const DeltaTimeCoreMetadata = artifacts.require('DeltaTimeCoreMetadata');

module.exports = async (deployer, network, accounts) => {

    const inventoryContract = await DeltaTimeInventory.deployed();

    await deployer.deploy(DeltaTimeCoreMetadata, inventoryContract.address);
    const metadataContract = await DeltaTimeCoreMetadata.deployed();

    console.log("Registering as metadata implementer for DeltaTimeInventory");
    await inventoryContract.setInventoryMetadataImplementer(metadataContract.address);

    for (collection of collections.All) {
        console.log(`Creating collection '${collection.name}'`);
        await inventoryContract.createCollection(
            collection.id,
            collection.layout.map(x => toBytes32Attribute(x.name)),
            collection.layout.map(x => x.length),
            collection.layout.map(x => x.index),
        );
    }
}
