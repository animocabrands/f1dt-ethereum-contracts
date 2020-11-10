// SPDX-License-Identifier: MIT

pragma solidity 0.6.8;

import "@openzeppelin/contracts/GSN/Context.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

/// Minimal transfers-only ERC20 interface
interface IERC20Transfers {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

struct ParticipantData {
        uint256 timestamp;
        uint256 amount;
    }

/**
 * @title TimeTrialEliteLeague.
 * Contract which manages the participation status of players to the elite tiers.
 * Entering a tier requires the participant to escrow some ERC20 gaming token, which
 * is given back to the participant when they leave the tier.
 */
contract TimeTrialEliteLeague is Context, Pausable, Ownable {
    using SafeMath for uint256;
    /**
     * Event emitted when a player's particiation in a tier is updated.
     * @param participant The address of the participant.
     * @param tierId The tier identifier.
     * @param deposit Amount escrowed in tier. 0 means non participant.
     */
    event ParticipationUpdated(address participant, bytes32 tierId, uint256 deposit);

    IERC20Transfers public immutable gamingToken;
    uint256 public immutable lockingPeriod;
    mapping(bytes32 => uint256) public tiers; // tierId => minimumAmountToEscrow
    mapping(address => mapping(bytes32 => ParticipantData)) public participants; // participant => tierId => ParticipantData
    /**
     * @dev Reverts if `gamingToken_` is the zero address.
     * @dev Reverts if `lockingPeriod` is zero.
     * @dev Reverts if `tierIds` and `amounts` have different lengths.
     * @dev Reverts if any element of `amounts` is zero.
     * @param gamingToken_ An ERC20-compliant contract address.
     * @param lockingPeriod_ The period that a participant needs to wait for leaving a tier after entering it.
     * @param tierIds The identifiers of each supported tier.
     * @param amounts The amounts of gaming token to escrow for participation, for each one of the `tierIds`.
     */
    constructor(
        IERC20Transfers gamingToken_,
        uint256 lockingPeriod_,
        bytes32[] memory tierIds,
        uint256[] memory amounts
    ) public {
        require(gamingToken_ != IERC20Transfers(0), "Leagues: zero address");
        require(lockingPeriod_ != 0, "Leagues: zero lock");
        gamingToken = gamingToken_;
        lockingPeriod = lockingPeriod_;

        uint256 length = tierIds.length;
        require(length == amounts.length, "Leagues: inconsistent arrays");
        for (uint256 i = 0; i < length; ++i) {
            uint256 amount = amounts[i];
            require(amount != 0, "Leagues: zero amount");
            tiers[tierIds[i]] = amount;
        }
    }

    /**
     * Updates amount staked for participant in tier
     * @dev Reverts if `tierId` does not exist.  
     * @dev Reverts if user is not in tier.     
     * @dev Emits a ParticipationUpdated event.
     * @dev An amount of ERC20 `gamingToken` is transferred from the sender to this contract.
     * @param tierId The identifier of the tier to increase the deposit for.
     * @param amount The amount to deposit.
     */
    function increaseDeposit(bytes32 tierId, uint256 amount) whenNotPaused public {
        address sender = _msgSender();
        require(tiers[tierId] != 0, "Leagues: tier not found");
        ParticipantData memory pd = participants[sender][tierId];
        require(pd.timestamp != 0, "Leagues: non participant");
        uint256 newAmount = amount.add(pd.amount);
        participants[sender][tierId] = ParticipantData(block.timestamp,newAmount);
        require(
            gamingToken.transferFrom(sender, address(this), amount),
            "Leagues: transfer in failed"
        );
        emit ParticipationUpdated(sender, tierId, newAmount);
    }

    /**
     * Enables the participation of a player in a tier. Requires the escrowing of an amount of gaming token.
     * @dev Reverts if `tierId` does not exist.
     * @dev Reverts if 'deposit' is less than minimumAmountToEscrow
     * @dev Reverts if the sender is already participant in the tier.
     * @dev Emits a ParticipationUpdated event.
     * @dev An amount of ERC20 `gamingToken` is transferred from the sender to this contract.
     * @param tierId The identifier of the tier to enter.
     * @param deposit The amount to deposit.
     */
    function enterTier(bytes32 tierId, uint256 deposit) whenNotPaused public {
        address sender = _msgSender();
        uint256 minDeposit = tiers[tierId];
        require(minDeposit != 0, "Leagues: tier not found");
        require(minDeposit <= deposit, "Leagues: insufficient amount");
        require(participants[sender][tierId].timestamp == 0, "Leagues: already participant");
        participants[sender][tierId] = ParticipantData(block.timestamp,deposit);
        require(
            gamingToken.transferFrom(sender, address(this), deposit),
            "Leagues: transfer in failed"
        );
        emit ParticipationUpdated(sender, tierId, deposit);
    }

    /**
     * Disables the participation of a player in a tier. Releases the amount of gaming token escrowed for this tier.
     * @dev Reverts if the sender is not a participant in the tier.
     * @dev Reverts if the tier participation of the sender is still time-locked.
     * @dev Emits a ParticipationUpdated event.
     * @dev An amount of ERC20 `gamingToken` is transferred from this contract to the sender.
     * @param tierId The identifier of the tier to exit.
     */
    function exitTier(bytes32 tierId) public {
        address sender = _msgSender();
        ParticipantData memory pd = participants[sender][tierId];
        require(pd.timestamp != 0, "Leagues: non-participant");
        
        require(block.timestamp - pd.timestamp > lockingPeriod, "Leagues: time-locked");
        participants[sender][tierId] = ParticipantData(0,0);
        emit ParticipationUpdated(sender, tierId, 0);
        require(
            gamingToken.transfer(sender, pd.amount),
            "Leagues: transfer out failed"
        );
    }

    /**
     * Gets the partricipation status of several tiers for a participant.
     * @param participant The participant to check the status of.
     * @param tierIds The tier identifiers to check.
     * @return timestamps The enter timestamp for each of the the `tierIds`. Zero values mean non-participant.
     */
    function participantStatus(address participant, bytes32[] calldata tierIds)
        external
        view
        returns (uint256[] memory timestamps)
    {
        uint256 length = tierIds.length;
        timestamps = new uint256[](length);
        for (uint256 i = 0; i < length; ++i) {
            timestamps[i] = participants[participant][tierIds[i]].timestamp;
        }
    }

     /**
     * Pauses the deposit operations.
     * @dev Reverts if the sender is not the contract owner.
     * @dev Reverts if the contract is paused already.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * Unpauses the deposit operations.
     * @dev Reverts if the sender is not the contract owner.
     * @dev Reverts if the contract is not paused.
     */
    function unpause() external onlyOwner {
        _unpause();
    }

}


