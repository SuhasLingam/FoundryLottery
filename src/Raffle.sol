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

/**
 * @title A Sample Raffle Contract
 * @author Suhas
 * @notice This is a contract to create a Sample Raffle
 * @dev Implements Chainlink VRFv2.5
 */

contract Raffle {
    /* Errors */
    error Raffle__SendMoreToEnterRaffle();
    error Raffle__StillTimeLeftToAnnounceWinners();

    /** Storage Variables */
    uint256 private immutable i_entranceFee;
    //Raffle End time in Seconds
    uint256 private immutable i_inteval;
    uint256 private s_lastTimeStamp;
    address payable[] private s_players;

    /**Events */
    event RaffleEntered(address indexed player);

    constructor(uint256 entranceFee, uint256 _interval) {
        i_entranceFee = entranceFee;
        i_inteval = _interval;
        s_lastTimeStamp = block.timestamp;
    }

    function enterRaffle() external payable {
        require(msg.value >= i_entranceFee, Raffle__SendMoreToEnterRaffle());
        s_players.push(payable(msg.sender));

        emit RaffleEntered(msg.sender);
    }

    //get random number
    //use random number to pick winner
    // Automate the Raffle
    function pickWinner() external {
        require(
            block.timestamp - s_lastTimeStamp > i_inteval,
            Raffle__StillTimeLeftToAnnounceWinners()
        );

        requestId = s_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: keyHash,
                subId: s_subscriptionId,
                requestConfirmations: requestConfirmations,
                callbackGasLimit: callbackGasLimit,
                numWords: numWords,
                extraArgs: VRFV2PlusClient._argsToBytes(
                    VRFV2PlusClient.ExtraArgsV1({
                        nativePayment: enableNativePayment
                    })
                )
            })
        );
    }

    /**
     * Getter Functions
     */

    function getEntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }
}
