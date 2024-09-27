// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// internal & private view & pure functions
// external & public view & pure functions

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

/**
 * @title A Sample Raffle Contract
 * @author Suhas
 * @notice This is a contract to create a Sample Raffle
 * @dev Implements Chainlink VRFv2.5
 */

contract Raffle is VRFConsumerBaseV2Plus {
    /* Errors */
    error Raffle__SendMoreToEnterRaffle();
    error Raffle__TransferToWinnerFailed();
    error Raffle__RaffleNotOpen();
    error Raffle__StillTimeLeftToAnnounceWinner();
    error Raffle__UpKeepNotNeeded(
        uint256 balance,
        uint256 playersLength,
        uint256 raffleState
    );

    /** Type Decalrations */

    enum RaffleStatus {
        OPEN,
        CALCULATING
    }

    /** State Variables */
    uint32 private constant MAX_WORDS = 1;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;

    uint256 private immutable i_entranceFee;
    uint256 private immutable i_inteval;
    bytes32 private immutable i_keyHash;
    uint256 private immutable i_subscriptionID;
    uint32 private immutable i_gasLimit;

    uint256 private s_lastTimeStamp;
    address payable[] private s_players;
    address private s_recentWinner;
    RaffleStatus private s_raffleStatus;

    /**Events */
    event RaffleEntered(address indexed player);
    event PickedWinner(address indexed winner);

    constructor(
        uint256 entranceFee,
        uint256 _interval,
        address vrfCoordinator,
        uint256 subcriptionID,
        bytes32 keyhash,
        uint32 gasLimit
    ) VRFConsumerBaseV2Plus(vrfCoordinator) {
        i_entranceFee = entranceFee;
        i_inteval = _interval;
        i_keyHash = keyhash;
        i_gasLimit = gasLimit;
        i_subscriptionID = subcriptionID;

        s_lastTimeStamp = block.timestamp;
        s_raffleStatus = RaffleStatus.OPEN;
    }

    /**
     * @dev This is the function that the Chainlink Keeper nodes call
     * they look for `upkeepNeeded` to return True.
     * the following should be true for this to return true:
     * 1. The time interval has passed between raffle runs.
     * 2. The lottery is open.
     * 3. The contract has ETH.
     * 4. There are players registered.
     * 5. Implicity, your subscription is funded with LINK.
     */

    function checkUpkeep(
        bytes memory /* checkData */
    ) public view returns (bool upkeepNeeded, bytes memory /* performData */) {
        bool isOpen = s_raffleStatus == RaffleStatus.OPEN;
        bool timePassed = (block.timestamp - s_lastTimeStamp) >= i_inteval;
        bool hasBalance = address(this).balance >= 0;
        bool hasPlayers = s_players.length > 0;
        upkeepNeeded = isOpen && timePassed && hasBalance && hasPlayers;
        return (upkeepNeeded, "");
    }

    function enterRaffle() external payable {
        require(msg.value >= i_entranceFee, Raffle__SendMoreToEnterRaffle());
        require(s_raffleStatus == RaffleStatus.OPEN, Raffle__RaffleNotOpen());

        s_players.push(payable(msg.sender));
        emit RaffleEntered(msg.sender);
    }

    //get random number
    //use random number to pick winner
    // Automate the Raffle
    function performUpkeep(bytes calldata /*performData */) external {
        (bool upkeepNeeded, ) = checkUpkeep("");
        if (!upkeepNeeded) {
            revert Raffle__UpKeepNotNeeded(
                address(this).balance,
                s_players.length,
                uint256(s_raffleStatus)
            );
        }

        require(
            block.timestamp - s_lastTimeStamp > i_inteval,
            Raffle__StillTimeLeftToAnnounceWinner()
        );
        s_raffleStatus = RaffleStatus.CALCULATING;

        VRFV2PlusClient.RandomWordsRequest memory request = VRFV2PlusClient
            .RandomWordsRequest({
                keyHash: i_keyHash,
                subId: i_subscriptionID,
                requestConfirmations: REQUEST_CONFIRMATIONS,
                callbackGasLimit: i_gasLimit,
                numWords: MAX_WORDS,
                extraArgs: VRFV2PlusClient._argsToBytes(
                    VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
                )
            });

        s_vrfCoordinator.requestRandomWords(request);
    }

    function fulfillRandomWords(
        uint256 /*requestId*/,
        uint256[] calldata randomWords
    ) internal override {
        uint256 indexOfPlayer = randomWords[0] % s_players.length;
        address payable recentWinner = s_players[indexOfPlayer];
        s_recentWinner = recentWinner;
        s_raffleStatus = RaffleStatus.OPEN;
        s_players = new address payable[](0);
        s_lastTimeStamp = block.timestamp;
        emit PickedWinner(s_recentWinner);
        //Transfer To the winner
        (bool success, ) = recentWinner.call{value: address(this).balance}("");
        require(success, Raffle__TransferToWinnerFailed());
    }

    /**
     * Getter Functions
     */

    function getEntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }
}
