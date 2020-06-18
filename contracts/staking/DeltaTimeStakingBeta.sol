// SPDX-License-Identifier: MIT

pragma solidity 0.6.8;

import "@openzeppelin/contracts/introspection/IERC165.sol";
import "@animoca/ethereum-contracts-nft_staking/contracts/staking/NftStaking.sol";
import "@animoca/ethereum-contracts-assets_inventory/contracts/metadata/IInventoryMetadata.sol";
import "@animoca/ethereum-contracts-assets_inventory/contracts/metadata/CoreMetadataDelegator.sol";

contract DeltaTimeStakingBeta is NftStaking, CoreMetadataDelegator {

    uint32 internal constant _cycleLengthInSeconds = 1 days;
    uint16 internal constant _periodLengthInCycles = 7; // 1 week

    mapping(uint256 => uint64) public weightByTokenAttribute;

    constructor(
        address deltaTimeInventory,
        address dividendToken_
    ) NftStaking(
        _cycleLengthInSeconds,
        _periodLengthInCycles,
        deltaTimeInventory,
        dividendToken_
    ) public {
        require(
            IERC165(deltaTimeInventory).supportsInterface(type(CoreMetadataDelegator).interfaceId),
            "DeltaTimeStaking: inventory is not a metadata delegator"
        );

        _setInventoryMetadataImplementer(
            ICoreMetadataDelegator(deltaTimeInventory).coreMetadataImplementer()
        );
        weightByTokenAttribute[0] = 500;
        weightByTokenAttribute[1] = 100;
        weightByTokenAttribute[2] = 50;
        weightByTokenAttribute[3] = 50;
        weightByTokenAttribute[4] = 10;
        weightByTokenAttribute[5] = 10;
        weightByTokenAttribute[6] = 10;
        weightByTokenAttribute[7] = 1;
        weightByTokenAttribute[8] = 1;
        weightByTokenAttribute[9] = 1;
    }

    function _validateAndGetNftWeight(uint256 nftId) internal virtual override view returns (uint64) {
        bytes32[] memory names = new bytes32[](2);
        names[0] = "type"; names[1] = "rarity";
        uint256[] memory attributeValues = ICoreMetadata(
            coreMetadataImplementer
        ).getAttributes(nftId, names);
        require(attributeValues[0] == 1, "DeltaTimeStaking: only cars can be staked");
        return weightByTokenAttribute[attributeValues[1]];
    }
}
