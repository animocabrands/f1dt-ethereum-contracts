pragma solidity = 0.5.16;

import "@openzeppelin/contracts/access/Roles.sol";

interface ICrateOpenEmitter {
    function openCrate(address from, uint256 lotId, uint256 amount) external;
}    