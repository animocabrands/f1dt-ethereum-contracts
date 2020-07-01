pragma solidity = 0.5.16;

import "@openzeppelin/contracts/token/ERC20/ERC20Capped.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Detailed.sol";
import "@openzeppelin/contracts/GSN/GSNRecipient.sol";
import "@openzeppelin/contracts/ownership/Ownable.sol";
import "./ICrateOpenEmitter.sol";

// crate token. 0 decimals - crates can't be fractional
contract F1DeltaCrate is ERC20Capped, ERC20Detailed, GSNRecipient, Ownable {
    enum ErrorCodes {
        RESTRICTED_METHOD,
        INSUFFICIENT_BALANCE
    }

    struct AcceptRelayedCallVars {
        bytes4 methodId;
        bytes ef;
    }

    string _uri;
    address _crateOpener;
    uint256 _lotId;
    uint256 public _cratesIssued;

    constructor(
        uint256 lotId, 
        uint256 cap,
        string memory name, 
        string memory symbol,
        string memory uri,
        address crateOpener
    ) ERC20Capped(cap) ERC20Detailed(name, symbol, 0) public {
        require(crateOpener != address(0));

        _uri = uri;
        _crateOpener = crateOpener;
        _lotId = lotId;
    }

    function burn(uint256 amount) public {
        _burn(_msgSender(), amount);
        ICrateOpenEmitter(_crateOpener).openCrate(_msgSender(), _lotId, amount);
    }

    function burnFrom(address account, uint256 amount) public {
        _burnFrom(account, amount);
        ICrateOpenEmitter(_crateOpener).openCrate(account, _lotId, amount);
    }

    function _mint(address account, uint256 amount) internal {
        _cratesIssued = _cratesIssued + amount; // not enough money in the world to cover 2 ^ 256 - 1 increments
        require(_cratesIssued <= cap(), "cratesIssued exceeded cap");
        super._mint(account, amount);
    }

    function tokenURI() public view returns (string memory) {
        return _uri;
    }

    function setURI(string memory uri) public onlyOwner {
        _uri = uri;
    }

    /////////////////////////////////////////// GSNRecipient implementation ///////////////////////////////////
    /**
     * @dev Ensures that only users with enough gas payment token balance can have transactions relayed through the GSN.
     */
    function acceptRelayedCall(
        address /*relay*/,
        address from,
        bytes calldata encodedFunction,
        uint256 /*transactionFee*/,
        uint256 /*gasPrice*/,
        uint256 /*gasLimit*/,
        uint256 /*nonce*/,
        bytes calldata /*approvalData*/,
        uint256 /*maxPossibleCharge*/
    )
        external
        view
        returns (uint256, bytes memory mem)
    {
        // restrict to burn function only
        // load methodId stored in first 4 bytes https://solidity.readthedocs.io/en/v0.5.16/abi-spec.html#function-selector-and-argument-encoding
        // load amount stored in the next 32 bytes https://solidity.readthedocs.io/en/v0.5.16/abi-spec.html#function-selector-and-argument-encoding
        // 32 bytes offset is required to skip array length
        bytes4 methodId;
        uint256 amountParam;
        mem = encodedFunction;
        assembly {
            let dest := add(mem, 32)
            methodId := mload(dest)
            dest := add(dest, 4)
            amountParam := mload(dest)
        }

        // bytes4(keccak256("burn(uint256)")) == 0x42966c68
        if (methodId != 0x42966c68) {
            return _rejectRelayedCall(uint256(ErrorCodes.RESTRICTED_METHOD));
        }

        // Check that user has enough crates to burn
        if (balanceOf(from) < amountParam) {
            return _rejectRelayedCall(uint256(ErrorCodes.INSUFFICIENT_BALANCE));
        }

        return _approveRelayedCall();
    }

    function _preRelayedCall(bytes memory) internal returns (bytes32) {
        // solhint-disable-previous-line no-empty-blocks
    }

    function _postRelayedCall(bytes memory, bool, uint256, bytes32) internal {
        // solhint-disable-previous-line no-empty-blocks
    }

    /**
     * @dev Withdraws the recipient's deposits in `RelayHub`.
     */
    function withdrawDeposits(uint256 amount, address payable payee) external onlyOwner {
        _withdrawDeposits(amount, payee);
    }
}