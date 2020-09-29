// SPDX-License-Identifier: MIT

pragma solidity 0.6.8;

import "@openzeppelin/contracts/GSN/Context.sol";

/// Minimal transfers-only ERC20 interface
interface IERC20Transfers {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

/**
 * @title TimeTrialLeagues.
 * Contract which manages the participation status of players to the elite leagues.
 * Entering a league requires the participant to escrow some ERC20 gaming token, which
 * is given back to the participant when they leave the league.
 */
contract TimeTrialLeagues is Context {
    /**
     * Event emitted when ...
     * @param participant address of participant
     * @param leagueId league id
     * @param enabled enabled true or false
     */
    event ParticipationUpdated(address participant, bytes32 leagueId, bool enabled);

    IERC20Transfers public immutable gamingToken;
    uint256 public immutable lockingPeriod;
    mapping(bytes32 => uint256) public leagues; // leagueId => amountToEscrow
    mapping(address => mapping(bytes32 => uint256)) public participants; // participant => leagueId => enteredTimestamp

    /**
     * @dev Reverts if `gamingToken_` is the zero address.
     * @dev Reverts if `lockingPeriod` is zero.
     * @dev Reverts if `leagueIds` and `amounts` have different lengths.
     * @dev Reverts if any element of `amounts` is zero.
     * @param gamingToken_ An ERC20-compliant contract address.
     * @param lockingPeriod_ The period that a participant needs to wait for leaving a league after entering it.
     * @param leagueIds The identifiers of each supported league.
     * @param amounts The amounts of gaming token to escrow for participation, for each one of the `leagueIds`.
     */
    constructor(
        IERC20Transfers gamingToken_,
        uint256 lockingPeriod_,
        bytes32[] memory leagueIds,
        uint256[] memory amounts
    ) public {
        require(gamingToken_ != IERC20Transfers(0), "Leagues: zero address");
        require(lockingPeriod_ != 0, "Leagues: zero lock");
        gamingToken = gamingToken_;
        lockingPeriod = lockingPeriod_;

        uint256 length = leagueIds.length;
        require(length == amounts.length, "Leagues: inconsistent arrays");
        for (uint256 i = 0; i < length; ++i) {
            uint256 amount = amounts[i];
            require(amount != 0, "Leagues: zero amount");
            leagues[leagueIds[i]] = amount;
        }
    }

    /**
     * Enables the participation of a player in a league. Requires the escrowing of an amount of gaming token.
     * @dev Reverts if `leagueId` does not exist.
     * @dev Reverts if the sender is already participant in the league.
     * @dev Emits a ParticipationUpdated event.
     * @dev An amount of ERC20 `gamingToken` is transferred from the sender to this contract.
     * @param leagueId The identifier of the league to enter.
     */
    function enterLeague(bytes32 leagueId) public {
        address sender = _msgSender();
        uint256 amount = leagues[leagueId];
        require(amount != 0, "Leagues: league not found");
        require(participants[sender][leagueId] == 0, "Leagues: already participant");
        participants[sender][leagueId] = block.timestamp;
        require(
            gamingToken.transferFrom(sender, address(this), amount),
            "Leagues: transfer in failed"
        );
        emit ParticipationUpdated(sender, leagueId, true);
    }

    /**
     * Disables the participation of a player in a league. Releases the amount of gaming token escrowed for this league.
     * @dev Reverts if `leagueId` does not exist.
     * @dev Reverts if the sender is not a participant in the league.
     * @dev Reverts if the league participation of the sender if still time-locked.
     * @dev Emits a ParticipationUpdated event.
     * @dev An amount of ERC20 `gamingToken` is transferred from this contract to the sender.
     * @param leagueId The identifier of the league to leave.
     */
    function leaveLeague(bytes32 leagueId) public {
        address sender = _msgSender();
        uint256 amount = leagues[leagueId];
        require(amount != 0, "Leagues: league not found");
        uint256 enterTimestamp = participants[sender][leagueId];
        require(enterTimestamp != 0, "Leagues: non-participant");
        require(block.timestamp - enterTimestamp <= lockingPeriod, "Leagues: time-locked");
        participants[sender][leagueId] = 0;
        emit ParticipationUpdated(sender, leagueId, false);
        require(
            gamingToken.transfer(sender, amount),
            "Leagues: transfer out failed"
        );
    }

    /**
     * Gets the partricipation status of several leagues for a participant.
     * @param participant The participant to check the status of.
     * @param leagueIds The league identifiers to check.
     * @return timestamps the enter timestamp for each of the the `leagueIds`. Zero values mean non-participant.
     */
    function participantStatus(address participant, bytes32[] calldata leagueIds)
        external
        view
        returns (uint256[] memory timestamps)
    {
        uint256 length = leagueIds.length;
        timestamps = new uint256[](length);
        for (uint256 i = 0; i < length; ++i) {
            timestamps[i] = participants[participant][leagueIds[i]];
        }
    }
}


