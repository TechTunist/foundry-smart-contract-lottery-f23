// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;


/**
 * @title A sample Raffle contract
 * @author Matthew Jackson      
 * @notice This contract is for creating a sample Raffle
 * @dev implements Chainlink VRFv2
 */


contract Raffle {
    error Raffle__NotEnoughEthToEnter(string message);

    uint256 private constant REQUEST_CONFIRMATIONS = 3; // number of confirmations required

    uint256 private immutable i_entranceFee; // entrance fee in wei
    uint256 private immutable i_interval; // duration of the lottery in seconds
    address private immutable i_vrfCoordinator; // address of the VRF coordinator
    bytes32 private immutable i_gasLane; // gas lane
    uint64 private immutable i_subscriptionId; // subscription id

    uint256 private s_lastTimeStamp; // timestamp to be compared

    address payable[] private s_players;

    /** Events */
    event EnteredRaffle (address indexed player);

    constructor(
        uint256 entranceFee,
        uint256 interval,
        address vrfCoordinator,
        bytes32 gasLane,
        uint64 subscriptionId
        ) {
            i_entranceFee = entranceFee;
            i_interval = interval;
            s_lastTimeStamp = block.timestamp;
            i_vrfCoordinator = vrfCoordinator;
            i_gasLane = gasLane;
            i_subscriptionId = subscriptionId;
        } 
    
    function enterRaffle() external payable{
        if(msg.value < i_entranceFee) {
            revert Raffle__NotEnoughEthToEnter("Not enough ETH to enter");
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
            REQUEST_CONFIRMATIONS, // 
            callbackGasLimit,
            numWords
        );
    }

    /** Getter Functions */

    function getEntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }
}