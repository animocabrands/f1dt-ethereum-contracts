// SPDX-License-Identifier: MIT

pragma solidity ^0.6.8;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../metadata/Crates2020RNGLib.sol";

interface IF1DTBurnableCrateKey {
    /**
     * Destroys `amount` of token.
     * @dev Reverts if called by any other than the contract owner.
     * @dev Reverts is `amount` is zero.
     * @param amount Amount of token to burn.
     */
    function burn(uint256 amount) external;

    /**
     * See {IERC20-transferFrom(address,address,uint256)}.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) external;
}

interface IF1DTInventory {
    /**
     * @dev Public function to mint a batch of new tokens
     * Reverts if some the given token IDs already exist
     * @param to address[] List of addresses that will own the minted tokens
     * @param ids uint256[] List of ids of the tokens to be minted
     * @param uris bytes32[] Concatenated metadata URIs of nfts to be minted
     * @param values uint256[] List of quantities of ft to be minted
     */
    function batchMint(address[] calldata to, uint256[] calldata ids, bytes32[] calldata uris, uint256[] calldata values, bool safe) external;
}

contract Crates2020 is Ownable {
    using Crates2020RNGLib for uint256;

    IF1DTInventory immutable public INVENTORY;
    IF1DTBurnableCrateKey immutable public CRATE_KEY_COMMON;
    IF1DTBurnableCrateKey immutable public CRATE_KEY_RARE;
    IF1DTBurnableCrateKey immutable public CRATE_KEY_EPIC;
    IF1DTBurnableCrateKey immutable public CRATE_KEY_LEGENDARY;

    uint256 public counter;

    constructor(
        IF1DTInventory INVENTORY_,
        IF1DTBurnableCrateKey CRATE_KEY_COMMON_,
        IF1DTBurnableCrateKey CRATE_KEY_RARE_,
        IF1DTBurnableCrateKey CRATE_KEY_EPIC_,
        IF1DTBurnableCrateKey CRATE_KEY_LEGENDARY_,
        uint256 counter_
    ) public {
        require(
            address(INVENTORY_) != address(0) &&
            address(CRATE_KEY_COMMON_) != address(0) &&
            address(CRATE_KEY_EPIC_) != address(0) &&
            address(CRATE_KEY_LEGENDARY_) != address(0),
            "Crates: zero address"
        );
        INVENTORY = INVENTORY_;
        CRATE_KEY_COMMON = CRATE_KEY_COMMON_;
        CRATE_KEY_RARE = CRATE_KEY_RARE_;
        CRATE_KEY_EPIC = CRATE_KEY_EPIC_;
        CRATE_KEY_LEGENDARY = CRATE_KEY_LEGENDARY_;
        counter = counter_;
    }

    function transferCrateKeyOwnership(uint256 crateTier, address newOwner) external onlyOwner {
        IF1DTBurnableCrateKey crateKey = _getCrateKey(crateTier);
        crateKey.transferOwnership(newOwner);
    }

    /**
     * Burn some keys in order to mint 2020 season crates.
     * @dev Reverts if `quantity` is zero.
     * @dev Reverts if `crateTier` is not supported.
     * @dev Reverts if the transfer of the crate key to this contract fails (missing approval or insufficient balance).
     * @dev Reverts if this contract is not owner of the `crateTier`-related contract.
     * @dev Reverts if this contract is not minter of the DeltaTimeInventory contract.
     * @param crateTier The tier identifier for the crates to open.
     * @param quantity The number of crates to open.
     * @param seed The seed used for the metadata RNG.
     */
    function _openCrates(uint256 crateTier, uint256 quantity, uint256 seed) internal {
        require(quantity != 0, "Crates: zero quantity");
        IF1DTBurnableCrateKey crateKey = _getCrateKey(crateTier);

        address sender = _msgSender();
        uint256 amount = quantity * 1000000000000000000;

        crateKey.transferFrom(sender, address(this), amount);
        crateKey.burn(amount);

        bytes32[] memory uris = new bytes32[](5);
        uint256[] memory values = new uint256[](5);
        address[] memory to = new address[](5);
        for (uint256 i; i != 5; ++i) {
            values[i] = 1;
            to[i] = sender;
        }

        uint256 counter_ = counter;
        for (uint256 i; i != quantity; ++i) {
            if (i != 0) {
                seed = uint256(keccak256(abi.encode(seed)));
            }
            uint256[] memory tokens = seed.generateCrate(crateTier, counter_);
            INVENTORY.batchMint(to, tokens, uris, values, false);
            counter_ += 5;
        }
        counter = counter_;
    }

    function _getCrateKey(uint256 crateTier) view internal returns (IF1DTBurnableCrateKey) {
        if (crateTier == Crates2020RNGLib.CRATE_TIER_COMMON) {
            return CRATE_KEY_COMMON;
        } else if (crateTier == Crates2020RNGLib.CRATE_TIER_RARE) {
            return CRATE_KEY_RARE;
        } else if (crateTier == Crates2020RNGLib.CRATE_TIER_EPIC) {
            return CRATE_KEY_EPIC;
        } else if (crateTier == Crates2020RNGLib.CRATE_TIER_LEGENDARY) {
            return CRATE_KEY_LEGENDARY;
        } else {
            revert("Crates: wrong crate tier");
        }
    }
}
