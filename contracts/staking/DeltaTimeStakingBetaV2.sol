// SPDX-License-Identifier: MIT

pragma solidity 0.6.8;

import "@openzeppelin/contracts/introspection/IERC165.sol";
import "@animoca/ethereum-contracts-nft_staking/contracts/staking/NftStaking.sol";
import "@animoca/ethereum-contracts-assets_inventory/contracts/metadata/IInventoryMetadata.sol";
import "@animoca/ethereum-contracts-assets_inventory/contracts/metadata/CoreMetadataDelegator.sol";

contract DeltaTimeStakingBetaV2 is NftStaking, CoreMetadataDelegator {
    mapping(uint256 => uint64) public weightsByRarity;

    constructor(
        uint32 cycleLengthInSeconds_,
        uint16 periodLengthInCycles_,
        address inventoryContract,
        address revvContract,
        uint256[] memory rarities,
        uint64[] memory weights
    ) public NftStaking(cycleLengthInSeconds_, periodLengthInCycles_, inventoryContract, revvContract) {
        require(rarities.length == weights.length, "REVV: wrong arguments");
        require(
            IERC165(inventoryContract).supportsInterface(type(CoreMetadataDelegator).interfaceId),
            "DeltaTimeStaking: inventory is not a metadata delegator"
        );

        _setInventoryMetadataImplementer(ICoreMetadataDelegator(inventoryContract).coreMetadataImplementer());

        for (uint256 i = 0; i < rarities.length; ++i) {
            weightsByRarity[rarities[i]] = weights[i];
        }
    }

    function _validateAndGetNftWeight(uint256 nftId) internal virtual override view returns (uint64) {
        bytes32[] memory names = new bytes32[](2);
        names[0] = "type";
        names[1] = "rarity";
        uint256[] memory attributeValues = ICoreMetadata(coreMetadataImplementer).getAttributes(nftId, names);
        require(attributeValues[0] == 1, "DeltaTimeStaking: only cars can be staked");
        return weightsByRarity[attributeValues[1]];
    }
}
