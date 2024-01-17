// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";


// /home/tunist/Blockchain/foundry-smart-contract-lottery-f23/src/Raffle.sol


/**
 * @title A sample Raffle contract
 * @author Matthew Jackson      
 * @notice This contract is for creating a sample Raffle
 * @dev implements Chainlink VRFv2
 */


contract Raffle is VRFConsumerBaseV2 {
    error Raffle__NotEnoughEthToEnter(string message);
    error Raffle__TransferFailed();
    error Raffle__RaffleNotOpen();

    /** Type Declarations */
    enum RaffleState {
        OPEN,       // 0
        CALCULATING // 1
        }

    /** State Variables */
    uint16 private constant REQUEST_CONFIRMATIONS = 3; // number of confirmations required
    uint32 private constant NUM_WORDS = 1; // number of random words to be generated

    uint256 private immutable i_entranceFee; // entrance fee in wei
    uint256 private immutable i_interval; // duration of the lottery in seconds
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator; // address of the VRF coordinator
    bytes32 private immutable i_gasLane; // gas lane
    uint64 private immutable i_subscriptionId; // subscription id
    uint32 private immutable i_callbackGasLimit; // gas limit for the callback function

    uint256 private s_lastTimeStamp; // timestamp to be compared
    address payable[] private s_players;
    address private s_recentWinner;

    RaffleState private s_raffleState;

    /** Events */
    event EnteredRaffle (address indexed player);

    constructor(
        uint256 entranceFee,
        uint256 interval,
        address vrfCoordinator,
        bytes32 gasLane,
        uint64 subscriptionId,
        uint32 callbackGasLimit
        ) VRFConsumerBaseV2(vrfCoordinator) {
            i_entranceFee = entranceFee;
            i_interval = interval;
            s_lastTimeStamp = block.timestamp;
            i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinator);
            i_gasLane = gasLane;
            i_subscriptionId = subscriptionId;
            i_callbackGasLimit = callbackGasLimit;
            s_raffleState = RaffleState.OPEN;
        } 
    
    function enterRaffle() external payable{
        if(msg.value < i_entranceFee) {
            revert Raffle__NotEnoughEthToEnter("Not enough ETH to enter");
        }
        if (s_raffleState != RaffleState.OPEN) {
            revert Raffle__RaffleNotOpen();
        }
        s_players.push(payable(msg.sender));
        emit EnteredRaffle(msg.sender);
    }

    function pickWinner() external {
        // check if enough time has passed
        if ((block.timestamp - s_lastTimeStamp) > i_interval) {
            revert();
        }

        // if enough time has passed, pick a winner using a random number
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_gasLane, // gas lane
            i_subscriptionId, // the deployed subscription contract
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_WORDS
        );
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        uint256 indexOfWinner = randomWords[0] % s_players.length;
        address payable winner = s_players[indexOfWinner];

        s_recentWinner = winner;
        (bool success,) = winner.call{value: address(this).balance}("");
        if (!success) {
            revert Raffle__TransferFailed();
        }
    }

    /** Getter Functions */

    function getEntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }
}