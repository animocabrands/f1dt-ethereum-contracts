// SPDX-License-Identifier: MIT

pragma solidity ^0.6.8;

import "@animoca/ethereum-contracts-assets_inventory/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// TODO inherit from SwapSale
contract TrackTickets is ERC721, Ownable {

    string override public constant name = "F1 Delta Time Track 2020 Tickets";
    string override public constant symbol = "F1DT.TT2020";

    constructor() public ERC721() {}

    function safeBatchTransferFrom(address from, address to, uint256[] calldata tokenIds) external {

    }

    function batchBurn(uint256[] calldata tokenIds) external {

    }
}
