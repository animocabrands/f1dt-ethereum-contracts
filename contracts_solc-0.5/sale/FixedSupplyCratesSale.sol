pragma solidity = 0.5.16;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Capped.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/lifecycle/Pausable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/math/Math.sol";

import "./ReferrableSale.sol";
import "./F1DeltaCrate.sol";
import "./KyberAdapter.sol";
import "./ICrateOpenEmitter.sol";

contract FixedSupplyCratesSale is ReferrableSale, Pausable, KyberAdapter, ICrateOpenEmitter {
    using SafeMath for uint256;

    struct Lot {
        F1DeltaCrate crateToken;
        uint256 price; // in stable coin
    }

    struct PurchaseForVars {
        Lot lot;
        uint256 discount;
        uint256 price;
        uint256 referralReward;
        uint256 tokensSent;
        uint256 tokensReceived;
    }

    event Purchased (
        address indexed owner,
        address operator,
        uint256 indexed lotId,
        uint256 indexed quantity,
        uint256 pricePaid,
        address tokenAddress,
        uint256 tokensSent,
        uint256 tokensReceived,
        uint256 discountApplied,
        address referrer,
        uint256 referralRewarded
    );

    event LotCreated (
        uint256 lotId,
        uint256 supply,
        uint256 price,
        string uri,
        ERC20 crateToken
    );

    event LotPriceUpdated (
        uint256 lotId,
        uint256 price
    );

    event CrateOpened(address indexed from, uint256 lotId, uint256 amount);

    uint256 private constant PERCENT_PRECISION = 10000;
    uint256 private constant MULTI_PURCHASE_DISCOUNT_STEP = 5;

    ERC20 public _stableCoinAddress;
    address payable public _payoutWallet;

    mapping (uint256 => Lot) public _lots; // lotId => lot
    mapping (uint256 => mapping (address => address)) public _referrersByLot; // lotId => (buyer => referrer)
    mapping (address => mapping(uint256 => uint256)) public _cratesPurchased; // owner => (lot id => quantity)

    uint256 public _initialDiscountPercentage;
    uint256 public _initialDiscountPeriod;
    uint256 public _startedAt;
    uint256 public _multiPurchaseDiscount;

    modifier whenStarted() {
        require(_startedAt != 0);
        _;
    }

    modifier whenNotStarted() {
        require(_startedAt == 0);
        _;
    }

    constructor(
        address payable payoutWallet, 
        address kyberProxy, 
        ERC20 stableCoinAddress
    ) KyberAdapter(kyberProxy) public {
        require(payoutWallet != address(0));
        require(stableCoinAddress != ERC20(address(0)));
        setPayoutWallet(payoutWallet); 

        _stableCoinAddress = stableCoinAddress;
        pause();
    }

    function setPayoutWallet(address payable payoutWallet) public onlyOwner {
        require(payoutWallet != address(uint160(address(this))));
        _payoutWallet = payoutWallet;
    }

    function start(
        uint256 initialDiscountPercentage, 
        uint256 initialDiscountPeriod, 
        uint256 multiPurchaseDiscount
    ) 
    public 
    onlyOwner 
    whenNotStarted
    {
        require(initialDiscountPercentage < PERCENT_PRECISION);
        require(multiPurchaseDiscount < PERCENT_PRECISION);

        _initialDiscountPercentage = initialDiscountPercentage;
        _initialDiscountPeriod = initialDiscountPeriod;
        _multiPurchaseDiscount = multiPurchaseDiscount;
        
        // solium-disable-next-line security/no-block-members
        _startedAt = now;
        unpause();
    }

    function initialDiscountActive() public view returns (bool) {
        if (_initialDiscountPeriod == 0 || _initialDiscountPercentage == 0 || _startedAt == 0) {
            // No discount set or sale not started
            return false;
        }

        // solium-disable-next-line security/no-block-members
        uint256 elapsed = (now - _startedAt);
        return elapsed < _initialDiscountPeriod;
    }

    // owner can provide crate contract address which is compatible with F1DeltaCrate interface 
    // Make sure that crate contract has FixedSupplyCratesSale contract as minter.
    // if crate contract isn't provided sales contract will create simple F1DeltaCrate on it's own
    function createLot(
        uint256 lotId,
        uint256 supply,
        uint256 price,
        string memory name,
        string memory symbol,
        string memory uri,
        F1DeltaCrate crateToken
    ) 
        public 
        onlyOwner 
    {
        require(price != 0 && supply != 0);
        require(_lots[lotId].price == 0);
        
        Lot memory lot;
        lot.price = price;
        if (crateToken == F1DeltaCrate(address(0))) {
            lot.crateToken = new F1DeltaCrate(lotId, supply, name, symbol, uri, address(this));
            lot.crateToken.transferOwnership(owner());
            lot.crateToken.addMinter(owner());
        } else {
            lot.crateToken = crateToken;
        }
        
        _lots[lotId] = lot;

        emit LotCreated(lotId, supply, price, uri, ERC20(address(lot.crateToken)));
    }

    function updateLotPrice(uint256 lotId, uint128 price) external onlyOwner whenPaused {
        require(price != 0);
        require(_lots[lotId].price != 0);
        require(_lots[lotId].price != price);

        _lots[lotId].price = price;

        emit LotPriceUpdated(lotId, price);
    }

    function _nthPurchaseDiscount(uint lotPrice, uint quantity, uint cratesPurchased) private view returns(uint) {
        uint discountsApplied = cratesPurchased / MULTI_PURCHASE_DISCOUNT_STEP;
        uint discountsToApply = (cratesPurchased + quantity) / MULTI_PURCHASE_DISCOUNT_STEP - discountsApplied;

        return lotPrice.mul(discountsToApply).mul(_multiPurchaseDiscount).div(PERCENT_PRECISION);
    }

    function _getPriceWithDiscounts(Lot memory lot, uint quantity, uint cratesPurchased) private view returns(uint price, uint discount) {
        price = lot.price.mul(quantity);
        // Discounts are additive

        // apply early bird discount
        if (initialDiscountActive()) {
            discount = price.mul(_initialDiscountPercentage).div(PERCENT_PRECISION);
        }

        // apply multi purchase discount if any
        discount += _nthPurchaseDiscount(lot.price, quantity, cratesPurchased);
        price = price.sub(discount);
    }

    function purchaseFor(
        address payable destination,
        uint256 lotId,
        ERC20Capped tokenAddress,
        uint256 quantity,
        uint256 maxTokenAmount,
        uint256 minConversionRate,
        address payable referrer
    )
        external 
        payable
        whenNotPaused 
        whenStarted
    {
        require (quantity > 0);
        require (referrer != destination && referrer != msg.sender); //Inefficient

        // hack to fit as many variables on stack as required.
        PurchaseForVars memory vars;

        vars.lot = _lots[lotId];
        require(vars.lot.price != 0);

        (vars.price, vars.discount) = _getPriceWithDiscounts(vars.lot, quantity, _cratesPurchased[destination][lotId]);

        (vars.tokensSent, vars.tokensReceived) = _swapTokenAndHandleChange(
            tokenAddress,
            maxTokenAmount,
            _stableCoinAddress,
            vars.price,
            minConversionRate,
            msg.sender,
            address(uint160(address(this)))
        );
        
        // Check if received enough tokens.
        require(vars.tokensReceived >= vars.price);
        
        if (referrer != address(0)) {
            bool sendReferral = true;
            if (_customReferralPercentages[referrer] == 0) {
                // not a VIP
                if (_referrersByLot[lotId][destination] == referrer) { 
                    // buyer already used a referrer for this item before
                    sendReferral = false;
                }
            }
            
            if (sendReferral) {
                vars.referralReward = vars.tokensReceived
                    .mul(Math.max(_customReferralPercentages[referrer], _defaultReferralPercentage))
                    .div(PERCENT_PRECISION);

                if (vars.referralReward > 0) {
                    _referrersByLot[lotId][destination] = referrer;
                    // send stable coin as reward
                    require(_stableCoinAddress.transfer(referrer, vars.referralReward));
                }
            }
        }

        vars.tokensReceived = vars.tokensReceived.sub(vars.referralReward);

        require(vars.lot.crateToken.mint(destination, quantity)); 
        require(_stableCoinAddress.transfer(_payoutWallet, vars.tokensReceived));
        _cratesPurchased[destination][lotId] += quantity;

        emit Purchased(
            destination,
            msg.sender,
            lotId,
            quantity,
            vars.price,
            address(tokenAddress),
            vars.tokensSent,
            vars.tokensReceived,
            vars.discount,
            referrer,
            vars.referralReward
        );
    }

    function getPrice(
        uint256 lotId,
        uint256 quantity,
        ERC20 tokenAddress,
        address destination
    )
    external
    view
    returns (
        uint256 minConversionRate,
        uint256 lotPrice,
        uint256 lotPriceWithoutDiscount
    )
    {
        // convert Stable Coin -> Target Token (ETH is included)
        lotPriceWithoutDiscount = _lots[lotId].price.mul(quantity);
        (uint totalPrice, ) = _getPriceWithDiscounts(_lots[lotId], quantity, _cratesPurchased[destination][lotId]);

        (, uint tokenAmount) = _convertToken(_stableCoinAddress, totalPrice, tokenAddress);
        (, minConversionRate) = kyber.getExpectedRate(tokenAddress, _stableCoinAddress, tokenAmount);
        lotPrice = ceilingDiv(totalPrice.mul(10**36), minConversionRate);
        lotPrice = _fixTokenDecimals(_stableCoinAddress, tokenAddress, lotPrice, true);

        lotPriceWithoutDiscount = ceilingDiv(lotPriceWithoutDiscount.mul(10**36), minConversionRate);
        lotPriceWithoutDiscount = _fixTokenDecimals(_stableCoinAddress, tokenAddress, lotPriceWithoutDiscount, true);
    }

    function openCrate(address from, uint256 lotId, uint256 amount) external {
        require(address(_lots[lotId].crateToken) == msg.sender);
        for (uint256 i = 0; i < amount; i++ ) {
            emit CrateOpened(from, lotId, 1);
        }
    }

    // /**
    //  * @dev Withdraws the recipient's deposits in `RelayHub`.
    //  */
    // function withdrawDepositsForLot(uint256 lotId, uint256 amount, address payable payee) external onlyOwner {
    //     lots[lotId].crateToken.withdrawDeposits(amount, payee);
    // }
}