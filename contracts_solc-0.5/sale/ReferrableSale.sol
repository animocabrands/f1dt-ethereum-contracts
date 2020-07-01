pragma solidity ^0.5.2;

import "@openzeppelin/contracts/ownership/Ownable.sol";

/**
 * @title ReferrableSale
 * @dev Implements the base elements for a sales referral system.
 * It is supposed to be inherited by a sales contract.
 * The referrals are expressed in percentage * 100, for example 1000 represents 10% and 555 represents 5.55%.
 */
contract ReferrableSale is Ownable {

    event DefaultReferralSet(
        uint256 percentage
    );

    event CustomReferralSet(
        address indexed referrer,
        uint256 percentage
    );

    uint256 public _defaultReferralPercentage;
    mapping (address => uint256) public _customReferralPercentages;

    function setDefaultReferral(uint256 defaultReferralPercentage) public onlyOwner {
        require(defaultReferralPercentage < 10000, "Referral must be less than 100 percent");
        require(defaultReferralPercentage != _defaultReferralPercentage, "New referral must be different from the previous");
        _defaultReferralPercentage = defaultReferralPercentage;
        emit DefaultReferralSet(defaultReferralPercentage);
    }

    function setCustomReferral(address _referrer, uint256 customReferralPercentage) public onlyOwner {
        require(customReferralPercentage < 10000, "Referral must be less than 100 percent");
        require(customReferralPercentage != _customReferralPercentages[_referrer], "New referral must be different from the previous");
        _customReferralPercentages[_referrer] = customReferralPercentage;
        emit CustomReferralSet(_referrer, customReferralPercentage);
    }
}
