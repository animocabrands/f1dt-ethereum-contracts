pragma solidity = 0.5.16;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Capped.sol";
import "@openzeppelin/contracts/ownership/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/math/Math.sol";

import "./FixedSupplyCratesSale.sol";

contract AltcoinsPurchaseProxy is Ownable {
    using SafeMath for uint256;

    event PurchasedViaProxy (
        address indexed owner,
        address operator,
        uint256 indexed lotId,
        uint256 indexed quantity,
        uint256 pricePaid,
        address tokenAddress,
        address referrer
    );

    struct PurchaseForVars {
        uint256 altcoinConversionRate;
        uint256 altcoinPrice;
        uint256 altcoinPriceWithoutDiscount;
        uint256 stablecoinConversionRate;
        uint256 stablecoinPrice;
        uint256 stablecoinPriceWithoutDiscount;
    }

    uint256 private constant PERCENT_PRECISION = 10000;
    uint256 private constant MULTI_PURCHASE_DISCOUNT_STEP = 5;

    FixedSupplyCratesSale _saleContract;
    mapping (address => uint256) public _stableCoinRates;

    constructor(FixedSupplyCratesSale saleContract) public {
        require(saleContract != FixedSupplyCratesSale(address(0)));
        _saleContract = saleContract;
    }

    function addAltcoin(address altcoinAddress, uint256 stableCoinRate) external onlyOwner {
        require(altcoinAddress != address(0));
        _stableCoinRates[altcoinAddress] = stableCoinRate;
    }

    function purchaseFor(
        address payable destination,
        uint256 lotId,
        ERC20Capped altcoinAddress,
        uint256 quantity,
        uint256 maxTokenAmount,
        uint256 minConversionRate,
        address payable referrer
    ) external {
        PurchaseForVars memory vars;

        (
            vars.altcoinConversionRate,
            vars.altcoinPrice,
            vars.altcoinPriceWithoutDiscount
        ) = getPrice(lotId, quantity, ERC20(address(altcoinAddress)), destination);

        require(vars.altcoinConversionRate != 0, "Altcoin not supported");
        require(minConversionRate >= vars.altcoinConversionRate, "Min rate too low"); //TODO check it's correct
        require(vars.altcoinPrice <= maxTokenAmount, "Price above max token amount");

        (
            vars.stablecoinConversionRate,
            vars.stablecoinPrice,
            vars.stablecoinPriceWithoutDiscount
        ) = getPrice(lotId, quantity, _saleContract._stableCoinAddress(), destination);

        require(altcoinAddress.transferFrom(msg.sender, _saleContract._payoutWallet(), vars.altcoinPrice), "Altcoin transfer failed");
        require(ERC20(address(_saleContract._stableCoinAddress())).approve(address(_saleContract), vars.stablecoinPrice), "Approval failed");
        _saleContract.purchaseFor(
            destination,
            lotId,
            ERC20Capped(address(_saleContract._stableCoinAddress())),
            quantity,
            vars.stablecoinPrice,
            vars.stablecoinConversionRate,
            referrer
        );

        emit PurchasedViaProxy(
            destination,
            msg.sender,
            lotId,
            quantity,
            vars.altcoinPrice,
            address(altcoinAddress),
            referrer
        );
    }

    function getPrice(
        uint256 lotId,
        uint256 quantity,
        ERC20 tokenAddress,
        address destination
    )
    public
    view
    returns (
        uint256 minConversionRate,
        uint256 lotPrice,
        uint256 lotPriceWithoutDiscount
    )
    {
        minConversionRate = 1000000000000000000;
        (, uint256 singleLotPrice) = _saleContract._lots(lotId);
        lotPriceWithoutDiscount = singleLotPrice.mul(quantity);
        (lotPrice, ) = _getPriceWithDiscounts(singleLotPrice, quantity, _saleContract._cratesPurchased(destination, lotId));
        if (tokenAddress != _saleContract._stableCoinAddress()) {
            minConversionRate = _stableCoinRates[address(tokenAddress)];
            require(minConversionRate != 0, "Altcoin not supported");
            lotPrice = ceilingDiv(lotPrice.mul(10**36), minConversionRate);
            lotPrice = _fixTokenDecimals(_saleContract._stableCoinAddress(), tokenAddress, lotPrice, true);
            lotPriceWithoutDiscount = ceilingDiv(lotPriceWithoutDiscount.mul(10**36), minConversionRate);
            lotPriceWithoutDiscount = _fixTokenDecimals(_saleContract._stableCoinAddress(), tokenAddress, lotPriceWithoutDiscount, true);
        }
    }

    function ceilingDiv(uint256 a, uint256 b) internal pure returns (uint256 c) {
        return a.div(b).add(a.mod(b) > 0 ? 1 : 0);
    }

    function _nthPurchaseDiscount(uint lotPrice, uint quantity, uint cratesPurchased) private view returns(uint) {
        uint discountsApplied = cratesPurchased / MULTI_PURCHASE_DISCOUNT_STEP;
        uint discountsToApply = (cratesPurchased + quantity) / MULTI_PURCHASE_DISCOUNT_STEP - discountsApplied;

        return lotPrice.mul(discountsToApply).mul(_saleContract._multiPurchaseDiscount()).div(PERCENT_PRECISION);
    }

    function _getPriceWithDiscounts(uint256 lotPrice, uint quantity, uint cratesPurchased) private view returns(uint price, uint discount) {
        price = lotPrice.mul(quantity);
        // Discounts are additive

        // apply early bird discount
        if (_saleContract.initialDiscountActive()) {
            discount = price.mul(_saleContract._initialDiscountPercentage()).div(PERCENT_PRECISION);
        }

        // apply multi purchase discount if any
        discount += _nthPurchaseDiscount(lotPrice, quantity, cratesPurchased);
        price = price.sub(discount);
    }

    function _fixTokenDecimals(
        ERC20 _src,
        ERC20 _dest,
        uint256 _unfixedDestAmount,
        bool _ceiling
    )
    internal
    view
    returns (uint256 _destTokenAmount)
    {
        uint256 _unfixedDecimals = ERC20Detailed(address(_src)).decimals() + 18; // Kyber by default returns rates with 18 decimals.
        uint256 _decimals = ERC20Detailed(address(_dest)).decimals();

        if (_unfixedDecimals > _decimals) {
            // Divide token amount by 10^(_unfixedDecimals - _decimals) to reduce decimals.
            if (_ceiling) {
                return ceilingDiv(_unfixedDestAmount, (10 ** (_unfixedDecimals - _decimals)));
            } else {
                return _unfixedDestAmount.div(10 ** (_unfixedDecimals - _decimals));
            }
        } else {
            // Multiply token amount with 10^(_decimals - _unfixedDecimals) to increase decimals.
            return _unfixedDestAmount.mul(10 ** (_decimals - _unfixedDecimals));
        }
    }

    function balance() external view returns(uint256) {
        return ERC20(_saleContract._stableCoinAddress()).balanceOf(address(this));
    }

    function withdraw(address to, uint256 quantity) external onlyOwner {
        if (quantity == 0) { // Withdraw all
            quantity = ERC20(_saleContract._stableCoinAddress()).balanceOf(address(this));
        }
        require(ERC20(_saleContract._stableCoinAddress()).transfer(to, quantity));
    }
}