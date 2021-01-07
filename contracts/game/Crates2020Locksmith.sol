// SPDX-License-Identifier: MIT

pragma solidity ^0.6.8;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/cryptography/ECDSA.sol";
import "@animoca/ethereum-contracts-erc20_base/contracts/token/ERC20/IERC20.sol";
import "./Crates2020.sol";

contract Crates2020Locksmith is Crates2020 {
    using ECDSA for bytes32;

    // account => crateTier => nonce
    mapping(address => mapping(uint256 => uint256)) public nonces;

    address public signerKey;

    constructor(
        IF1DTInventory INVENTORY_,
        IF1DTBurnableCrateKey COMMON_CRATE_,
        IF1DTBurnableCrateKey RARE_CRATE_,
        IF1DTBurnableCrateKey EPIC_CRATE_,
        IF1DTBurnableCrateKey LEGENDARY_CRATE_,
        uint256 counter_
    ) public Crates2020(INVENTORY_, COMMON_CRATE_, RARE_CRATE_, EPIC_CRATE_, LEGENDARY_CRATE_, counter_) {}

    function setSignerKey(address signerKey_) external onlyOwner {
        signerKey = signerKey_;
    }

    /**
     * Burn some keys in order to mint 2020 season crates.
     * @dev reverts if `crateTier` is not supported.
     * @dev reverts if `quantity` is zero or more than 5.
     * @dev reverts if `signerKey` has not been set.
     * @dev reverts if `sig` is not verified to be a signature as described below.
     * @dev Reverts if the transfer of the crate key to this contract fails (missing approval or insufficient balance).
     * @dev Reverts if this contract is not owner of the `crateTier`-related contract.
     * @dev Reverts if this contract is not minter of the DeltaTimeInventory contract.
     * @param crateTier The tier identifier for the crates to open.
     * @param quantity The number of keys to burn / crates to open.
     * @param sig The signature for keccak256(abi.encode(sender, crateTier, nonce))
     *  signed by the private key paired to the public key `signerKey`, where:
     *  - `sender` is the msg.sender,
     *  - `crateTier` is the tier of crate to open,
     *  - `nonce` is the currently tracked nonce, accessed via `nonces(sender, crateTier)`.
     */
    function insertKeys(uint256 crateTier, uint256 quantity, bytes calldata sig) external {
        require(crateTier <= Crates2020RNGLib.CRATE_TIER_COMMON, "Locksmith: wrong crate tier");
        require(quantity <= 5, "Locksmith: above max quantity");

        address signerKey_ = signerKey;
        require(signerKey_ != address(0), "Locksmith: signer key not set");

        address sender = _msgSender();
        uint256 nonce = nonces[sender][crateTier];
        bytes32 hash_ = keccak256(abi.encode(sender, crateTier, nonce));
        require(hash_.toEthSignedMessageHash().recover(sig) == signerKey_, "Locksmith: invalid signature");

        uint256 seed = uint256(keccak256(sig));
        _openCrates(crateTier, quantity, seed);

        nonces[sender][crateTier] = nonce + 1;
    }
}
