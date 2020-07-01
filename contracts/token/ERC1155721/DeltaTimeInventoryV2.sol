// SPDX-License-Identifier: MIT

pragma solidity ^0.6.8;

import "@animoca/ethereum-contracts-core_library/contracts/utils/types/UInt256ToDecimalString.sol";
import "@animoca/ethereum-contracts-core_library/contracts/utils/types/Bytes32ToBase32String.sol";
import "@animoca/ethereum-contracts-core_library/contracts/access/MinterRole.sol";
import "@animoca/ethereum-contracts-erc20_base/contracts/metatx/ERC20Fees.sol";
import "@animoca/ethereum-contracts-assets_inventory/contracts/token/ERC1155721/PausableInventory.sol";
import "@animoca/ethereum-contracts-assets_inventory/contracts/metadata/CoreMetadataDelegator.sol";

interface MetadataLayoutSetter {
    function setLayout(
        uint256 collectionId,
        bytes32[] calldata names,
        uint256[] calldata lengths,
        uint256[] calldata indices
    ) external;
}

contract DeltaTimeInventoryV2 is PausableInventory, ERC20Fees, CoreMetadataDelegator, MinterRole {

    using UInt256ToDecimalString for uint256;
    using Bytes32ToBase32String for bytes32;

    string public override constant name = "F1® Delta Time Inventory";
    string public override constant symbol = "F1DTI";
    string private _uriPrefix = "https://nft.f1deltatime.com/json/";
    uint256 private constant _nfMaskLength = 32;

    constructor(
        address gasTokenAddress,
        address payoutWallet
    ) public PausableInventory(_nfMaskLength) ERC20Fees(gasTokenAddress, payoutWallet) {}

    function setInventoryMetadataImplementer(address implementer) external onlyOwner {
        _setInventoryMetadataImplementer(implementer);
    }

    /**
     * @dev This function creates the collection id.
     * @param collectionId collection identifier
     */
    function createCollection(
        uint256 collectionId,
        bytes32[] calldata names,
        uint256[] calldata lengths,
        uint256[] calldata indices
    ) external onlyMinter
    {
        MetadataLayoutSetter(coreMetadataImplementer).setLayout(
            collectionId,
            names,
            lengths,
            indices
        );
        _createCollection(collectionId);
    }

    /**
     * @dev Public function to mint a batch of new tokens
     * Reverts if some the given token IDs already exist
     * @param to address[] List of addresses that will own the minted tokens
     * @param ids uint256[] List of ids of the tokens to be minted
     * @param values uint256[] List of quantities of ft to be minted
     */
    function batchMint(address to, uint256[] calldata ids, uint256[] calldata values, bool safe) external onlyMinter {
        _batchMint(to, ids, values, "", safe);
    }

    function _uri(uint256 id) internal override view returns (string memory) {
        return string(abi.encodePacked(abi.encodePacked(_uriPrefix, id.toDecimalString())));
    }

    /////////////////////////////////////////// TokenURI////////////////////////////////////

    /**
     * @dev Public function to update the metadata URI prefix
     * @param uriPrefix string the new URI prefix
     */
    function setUriPrefix(string calldata uriPrefix) external onlyOwner {
        _uriPrefix = uriPrefix;
    }

/////////////////////////////////////////// GSN Context ///////////////////////////////////

    function _msgSender() internal virtual override(Context, ERC20Fees) view returns (address payable) {
        return super._msgSender();
    }

    function _msgData() internal virtual override(Context, ERC20Fees) view returns (bytes memory) {
        return super._msgData();
    }
}
