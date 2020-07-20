// SPDX-License-Identifier: MIT

pragma solidity ^0.6.6;

import "@animoca/ethereum-contracts-assets_inventory/contracts/metadata/InventoryMetadata.sol";

contract DeltaTimeCoreMetadata is InventoryMetadata {
    uint256 private constant _nfMaskLength = 32;

    modifier onlyDelegator() {
        require(msg.sender == inventoryMetadataDelegator, "InventoryMetadata: delegator only");
        _;
    }

    constructor(address delegator) public InventoryMetadata(_nfMaskLength, delegator) {
        _setAttribute(_defaultNonFungibleLayout, "type", 8, 240);
        _setAttribute(_defaultNonFungibleLayout, "subType", 8, 232);
        _setAttribute(_defaultNonFungibleLayout, "season", 8, 224);
    }

    function setLayout(
        uint256 collectionId,
        bytes32[] memory names,
        uint256[] memory lengths,
        uint256[] memory indices
    ) public onlyDelegator {
        _setLayout(collectionId, names, lengths, indices);
    }
}
