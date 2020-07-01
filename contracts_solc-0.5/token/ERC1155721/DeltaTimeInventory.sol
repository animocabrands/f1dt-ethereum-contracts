pragma solidity = 0.5.16;

import "./PausableInventory.sol";
import "./../../metatx/ERC20Fees.sol";
import "@openzeppelin/contracts/access/roles/MinterRole.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./../../library/Bytes.sol";

/**
 * @title F1 Delta Time Inventory Contract
 */
contract DeltaTimeInventory is PausableInventory, ERC20Fees, MinterRole {

    event FungibleCollection(address indexed id);
    event NonFungibleCollection(address indexed id);

    bool private _ipfsMigrated;

    string private _uriPrefix = "https://nft.f1deltatime.com/json/";
    string private _ipfsUriPrefix = "/ipfs/bafkrei";

    // Mapping Mapping from ID to URI
    mapping(uint256 => bytes32) private _uris;

    /**
     * @dev Constructor
     * @dev 32 DeltaTimeInventory collection type length
     */
    constructor(address gasTokenAddress, address payoutWallet
    ) public PausableInventory(32) ERC20Fees(gasTokenAddress, payoutWallet)  {
        _ipfsMigrated = false;
    }

    /**
     * @dev This function creates the collection id.
     * @param collectionId collection without fungible/non-fungible identifier
     * @return uint256 collectionId to create
     */
    function createCollection(uint256 collectionId, bytes32 byteUri) onlyMinter external {
        require(_ipfsMigrated? uint256(byteUri) > 0: uint256(byteUri) == 0);
        require(!isNFT(collectionId));
        _setURI(collectionId, byteUri);
    }

/////////////////////////////////////////// Mint ///////////////////////////////////////
    /**
     * @dev Public function to mint a batch of new tokens
     * Reverts if some the given token IDs already exist
     * @param to address[] List of addresses that will own the minted tokens
     * @param ids uint256[] List of ids of the tokens to be minted
     * @param uris bytes32[] Concatenated metadata URIs of nfts to be minted
     * @param values uint256[] List of quantities of ft to be minted
     */
    function batchMint(address[] memory to, uint256[] memory ids, bytes32[] memory uris, uint256[] memory values, bool safe) public onlyMinter {
        require(ids.length == to.length &&
            ids.length == uris.length &&
            ids.length == values.length);

        for (uint i = 0; i < ids.length; i++) {
            if (isNFT(ids[i]) && values[i] == 1) {
                _mintNonFungible(to[i], ids[i], uris[i], safe);
            } else if (isFungible(ids[i]) && uint256(uris[i]) == 0) {
                _mintFungible(to[i], ids[i], values[i]);
            } else {
                revert();
            }
        }
    }

    /**
     * @dev Public function to mint one non fungible token id
     * Reverts if the given token ID is not non fungible token id
     * @param to address recipient that will own the minted tokens
     * @param tokenId uint256 ID of the token to be minted
     * @param byteUri bytes32 Concatenated metadata URI of nft to be minted
     */
    function mintNonFungible(address to, uint256 tokenId, bytes32 byteUri, bool safe) external onlyMinter {
        require(isNFT(tokenId)); // solium-disable-line error-reason
        _mintNonFungible(to, tokenId, byteUri, safe);
    }

    /**
     * @dev Internal function to mint one non fungible token
     * Reverts if the given token ID already exist
     * @param to address recipient that will own the minted tokens
     * @param id uint256 ID of the token to be minted
     * @param byteUri bytes32 Concatenated metadata URI of nft to be minted
     */
    function _mintNonFungible(address to, uint256 id, bytes32 byteUri, bool safe) internal {
        require(to != address(0x0));
        require(!exists(id));

        uint256 collection = id & NF_COLLECTION_MASK;

        _owners[id] = to;
        _nftBalances[to] = SafeMath.add(_nftBalances[to], 1);
        _balances[collection][to] = SafeMath.add(_balances[collection][to], 1);

        emit Transfer(address(0x0), to, id);
        emit TransferSingle(_msgSender(), address(0x0), to, id, 1);

        _setURI(id, byteUri);

        if (safe) {
            require( // solium-disable-line error-reason
                _checkERC1155AndCallSafeTransfer(_msgSender(), address(0x0), to, id, 1, "", false, false), "failCheck"
            );
        }
    }

    /**
     * @dev Public function to mint fungible token
     * Reverts if the given ID is not fungible collection ID
     * @param to address recipient that will own the minted tokens
     * @param collection uint256 ID of the fungible collection to be minted
     * @param value uint256 amount to mint
     */
    function mintFungible(address to, uint256 collection, uint256 value) external onlyMinter {
        require(isFungible(collection));
        _mintFungible(to, collection, value);
    }

    /**
     * @dev Internal function to mint fungible token
     * Reverts if the given ID is not exsit
     * @param to address recipient that will own the minted tokens
     * @param collection uint256 ID of the fungible collection to be minted
     * @param value uint256 amount to mint
     */
    function _mintFungible(address to, uint256 collection, uint256 value) internal {
        require(to != address(0x0));
        require(value > 0);

        _balances[collection][to] = SafeMath.add(_balances[collection][to], value);

        emit TransferSingle(_msgSender(), address(0x0), to, collection, value);

        require( // solium-disable-line error-reason
            _checkERC1155AndCallSafeTransfer(_msgSender(), address(0x0), to, collection, value, "", false, false), "failCheck"
        );
    }

/////////////////////////////////////////// TokenURI////////////////////////////////////

    /**
     * @dev Public function to update the metadata URI prefix
     * @param uriPrefix string the new URI prefix
     */
    function setUriPrefix(string calldata uriPrefix) external onlyOwner {
        _uriPrefix = uriPrefix;
    }

    /**
     * @dev Public function to update the metadata IPFS URI prefix
     * @param ipfsUriPrefix string the new IPFS URI prefix
     */
    function setIPFSUriPrefix(string calldata ipfsUriPrefix) external onlyOwner {
        _ipfsUriPrefix = ipfsUriPrefix;
    }

    /**
     * @dev Public function to set the URI for a given ID
     * Reverts if the ID does not exist or metadata has migrated to IPFS
     * @param id uint256 ID to set its URI
     * @param byteUri bytes32 URI to assign
     */
    function setURI(uint256 id, bytes32 byteUri) external onlyMinter {
        require(!_ipfsMigrated && uint256(byteUri) > 0);
        require(exists(id));

        _setURI(id, byteUri);
    }

    /**
     * @dev Internal function to set the URI for a given ID
     * Reverts if the ID does not exist
     * @param id uint256 ID to set its URI
     * @param byteUri bytes32 URI to assign
     */
    function _setURI(uint256 id, bytes32 byteUri) internal {
        if (uint256(byteUri) > 0) {
            _uris[id] = byteUri;
            emit URI(_fullUriFromHash(byteUri), id);
        } else {
            emit URI(_fullUriFromId(id), id);
        }
    }

    /**
     * @dev Internal function to convert bytes32 hash to full uri string
     * @param byteUri bytes32 URI to convert
     * @return string URI convert from given hash
     */
    function _fullUriFromHash(bytes32 byteUri) private view returns(string memory) {
        return string(abi.encodePacked(_ipfsUriPrefix, Bytes.hash2base32(byteUri)));
    }

    /**
     * @dev Internal function to convert id to full uri string
     * @param id uint256 ID to convert
     * @return string URI convert from given ID
     */
    function _fullUriFromId(uint256 id) private view returns(string memory) {
        return string(abi.encodePacked(abi.encodePacked(_uriPrefix, Bytes.uint2str(id))));
    }

/////////////////////////////////////////// IPFS migration ///////////////////////////////////

    /**
     * @dev Sets IPFS migration flag true
     */
    function migrateToIPFS() public onlyMinter {
        _ipfsMigrated = true;
    }

/////////////////////////////////////////// ERC1155MetadataURI ///////////////////////////////////

    /**
     * @dev Returns an URI for a given ID
     * @param id uint256 ID of the tokenId / collectionId to query
     * @return string URI of given ID
     */
    function uri(uint256 id) public view returns(string memory) {
        if (uint256(_uris[id]) == 0) {
            return _fullUriFromId(id);
        }

        return _fullUriFromHash(_uris[id]);
    }

/////////////////////////////////////////// ERC721Metadata ///////////////////////////////////

    /**
     * @dev Gets the token name
     * @return string representing the token name
     */
    function name() external view returns(string memory) {
        return "F1® Delta Time Inventory";
    }

    /**
     * @dev Gets the token symbol
     * @return string representing the token symbol
     */
    function symbol() external view returns(string memory) {
        return "F1DTI";
    }

    /**
     * @dev Returns an URI for a given token ID
     * Throws if the token ID does not exist. May return an empty string.
     * @param tokenId uint256 ID of the token to query
     * @return string URI of given token ID
     */
    function tokenURI(uint256 tokenId) external view returns (string memory) {
        require(exists(tokenId));
        return uri(tokenId);
    }
}