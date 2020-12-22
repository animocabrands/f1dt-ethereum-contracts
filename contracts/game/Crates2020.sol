// SPDX-License-Identifier: MIT

pragma solidity ^0.6.8;

import "@openzeppelin/contracts/access/Ownable.sol";
// import "@animoca/ethereum-contracts-erc20_base/contracts/token/ERC20/IERC20.sol";
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

    IF1DTInventory immutable public INVENTORY;
    IF1DTBurnableCrateKey immutable public COMMON_CRATE;
    IF1DTBurnableCrateKey immutable public RARE_CRATE;
    IF1DTBurnableCrateKey immutable public EPIC_CRATE;
    IF1DTBurnableCrateKey immutable public LEGENDARY_CRATE;

    uint256 public counter;

    constructor(
        IF1DTInventory INVENTORY_,
        IF1DTBurnableCrateKey COMMON_CRATE_,
        IF1DTBurnableCrateKey RARE_CRATE_,
        IF1DTBurnableCrateKey EPIC_CRATE_,
        IF1DTBurnableCrateKey LEGENDARY_CRATE_
    ) public {
        require(
            address(INVENTORY_) != address(0) &&
            address(COMMON_CRATE_) != address(0) &&
            address(EPIC_CRATE_) != address(0) &&
            address(LEGENDARY_CRATE_) != address(0),
            "Crates: zero address"
        );
        INVENTORY = INVENTORY_;
        COMMON_CRATE = COMMON_CRATE_;
        RARE_CRATE = RARE_CRATE_;
        EPIC_CRATE = EPIC_CRATE_;
        LEGENDARY_CRATE = LEGENDARY_CRATE_;
    }

    /**
     * @dev Reverts if `crateTier` is not supported.
     * @dev Reverts if the transfer of the crate key to this contract fails.
     * @dev Reverts if `crateTier` is not supported
     */
    function _openCrate(uint256 crateTier, uint256 quantity, uint256 seed) internal {
        require(quantity != 0, "Crates: zero quantity");
        require(quantity <= 5, "Crates: above max quantity");
        IF1DTBurnableCrateKey crateKey;
        if (crateTier == Crates2020RNGLib._CRATE_TIER_COMMON) {
            crateKey = COMMON_CRATE;
        } else if (crateTier == Crates2020RNGLib._CRATE_TIER_RARE) {
            crateKey = RARE_CRATE;
        } else if (crateTier == Crates2020RNGLib._CRATE_TIER_EPIC) {
            crateKey = EPIC_CRATE;
        } else if (crateTier == Crates2020RNGLib._CRATE_TIER_LEGENDARY) {
            crateKey = LEGENDARY_CRATE;
        } else {
            revert("Crates: wrong crate tier");
        }

        address sender = _msgSender();
        uint256 amount = quantity * 1000000000000000000;

        crateKey.transferFrom(sender, address(this), amount);
        crateKey.burn(amount);

        bytes32[] memory uris = new bytes32[](5);
        uint256[] memory values = new uint256[](5);
        address[] memory to = new address[](5);
        for (uint256 i; i != 5; ++i) {
            uris[i] = 0x0;
            values[i] = 1;
            to[i] = sender;
        }

        for (uint256 i; i != quantity; ++i) {
            uint256 counter_ = counter;
            uint256[] memory tokens = Crates2020RNGLib.generateCrate(seed, crateTier, counter_);
            INVENTORY.batchMint(to, tokens, uris, values, false);
            counter = counter_ + 5;
            seed = uint256(keccak256(abi.encode(seed)));
        }
    }
}
