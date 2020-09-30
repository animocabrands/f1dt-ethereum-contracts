pragma solidity = 0.5.16;

import "@openzeppelin/contracts/ownership/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/GSN/GSNRecipient.sol";

contract SimpleSale is Ownable, GSNRecipient {
    using SafeMath for uint256;

    enum ErrorCodes {
        RESTRICTED_METHOD,
        INSUFFICIENT_BALANCE
    }

    struct Price {
        uint256 ethPrice;
        uint256 erc20Price;
    }

    event Purchased(
        string purchaseId,
        address paymentToken,
        uint256 price,
        uint256 quantity,
        address destination,
        address operator
    );

    event PriceUpdated(
        string purchaseId,
        uint256 ethPrice,
        uint256 erc20Price
    );

    address public ETH_ADDRESS = address(0x00eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee);

    address public _erc20Token;
    address payable public _payoutWallet;

    mapping(string => Price) public _prices; //  purchaseId => price in tokens

    constructor(address payable payoutWallet, address erc20Token) public {
        setPayoutWallet(payoutWallet);
        _erc20Token = erc20Token;
    }

    function setPayoutWallet(address payable payoutWallet) public onlyOwner {
        require(payoutWallet != address(0));
        require(payoutWallet != address(this));
        _payoutWallet = payoutWallet;
    }

    function setErc20Token(address erc20Token) public onlyOwner {
        _erc20Token = erc20Token;
    }
    
    function setPrice(string memory purchaseId, uint256 ethPrice, uint256 erc20TokenPrice) public onlyOwner {
        _prices[purchaseId] = Price(ethPrice, erc20TokenPrice);
        emit PriceUpdated(purchaseId, ethPrice, erc20TokenPrice);
    }

    function purchaseFor(
        address destination,
        string memory purchaseId,
        uint256 quantity,
        address paymentToken
    ) public payable {
        require(quantity > 0, "Quantity can't be 0");
        require(paymentToken == ETH_ADDRESS || paymentToken == _erc20Token, "Unsupported payment token");

        address payable sender = _msgSender();

        Price memory price = _prices[purchaseId];

        if (paymentToken == ETH_ADDRESS) {
            require(price.ethPrice != 0, "purchaseId not found");
            uint totalPrice = price.ethPrice.mul(quantity);
            require(msg.value >= totalPrice, "Insufficient ETH");
            _payoutWallet.transfer(totalPrice);

            uint256 change = msg.value.sub(totalPrice);
            if (change > 0) {
                sender.transfer(change);
            }
            emit Purchased(purchaseId, paymentToken, price.ethPrice, quantity, destination, sender);
        } else {
            require(_erc20Token != address(0), "ERC20 payment not supported");
            require(price.erc20Price != 0, "Price not found");
            uint totalPrice = price.erc20Price.mul(quantity);
            require(ERC20(_erc20Token).transferFrom(sender, _payoutWallet, totalPrice));
            emit Purchased(purchaseId, paymentToken, price.erc20Price, quantity, destination, sender);
        }
    }

    /////////////////////////////////////////// GSNRecipient implementation ///////////////////////////////////
    /**
     * @dev Ensures that only users with enough gas payment token balance can have transactions relayed through the GSN.
     */
    function acceptRelayedCall(
        address /*relay*/,
        address /*from*/,
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
        address recipient;
        string memory purchaseId;
        uint256 quantity;
        address paymentToken;
        mem = encodedFunction;
        assembly {
            let dest := add(mem, 32)
            methodId := mload(dest)
            dest := add(dest, 4)
            recipient := mload(dest)
            dest := add(dest, 32)
            purchaseId := mload(dest)
            dest := add(dest, 32)
            quantity := mload(dest)
            dest := add(dest, 32)
            paymentToken := mload(dest)
        }

        // bytes4(keccak256("purchaseFor(address,string,uint256,address)")) == 0xwwwwww
        // if (methodId != 0xwwwwww) {
            // return _rejectRelayedCall(uint256(ErrorCodes.RESTRICTED_METHOD));
        // }

        // Check that user has enough balance
        // if (balanceOf(from) < amountParam) {
        //     return _rejectRelayedCall(uint256(ErrorCodes.INSUFFICIENT_BALANCE));
        // }

        //TODO restrict to purchaseFor() and add validation checks

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
