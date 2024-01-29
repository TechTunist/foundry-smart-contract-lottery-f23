//SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import { Script } from "lib/forge-std/src/Script.sol";
import { DeployRaffle } from "script/DeployRaffle.s.sol";
import { Raffle } from "src/Raffle.sol";
import {Test, console} from "lib/forge-std/src/Test.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";

contract RaffleTest is Test {

    /** Events */
    event EnteredRaffle (address indexed player);

    Raffle raffle;
    HelperConfig helperConfig;

    uint256 entranceFee;
    uint256 interval;
    address vrfCoordinator;
    bytes32 gasLane;
    uint64 subscriptionId;
    uint32 callbackGasLimit;
    address link;

    address public PLAYER = makeAddr("player");
    uint256 public constant STARTING_USER_BALANCE = 10 ether;

    function setUp() external {
        DeployRaffle deployer = new DeployRaffle();
        (raffle, helperConfig) = deployer.run();

        (
            entranceFee,
            interval,
            vrfCoordinator,
            gasLane,
            subscriptionId,
            callbackGasLimit,
            link
        ) = helperConfig.activeNetworkConfig();

        console.log("Raffle address: %s", address(raffle));

        vm.deal(PLAYER, STARTING_USER_BALANCE);
    }


    ///////////////////////////////////////
    ///////////   enterRaffle   /////////// 
    ///////////////////////////////////////

    function testRaffleRevertsWhenYouDontPayEnough() public {
        // Arrange
        vm.prank(PLAYER);
        
        // Act / Assert 
        vm.expectRevert(Raffle.Raffle__NotEnoughEthSent.selector);
        raffle.enterRaffle();
    }

    function testRaffleInitialisesInOpenState() public view {
        console.log("Raffle state: %s", uint256(raffle.getRaffleState()));
        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
    }

    function testRaffleAddsPlayerToPlayersArray() public {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        console.log("This many players: %s", uint256(raffle.getPlayersArray().length));
        assert(raffle.getPlayersArray().length > 0);
    }

    function testRaffleRecordsPlayerWhenTheyEnter() public {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        address playerRecorded = raffle.getPlayer();
        assert(playerRecorded == PLAYER);
    }

    function testEmitsEventOnEntry() public {
        vm.prank(PLAYER);
        vm.expectEmit(true, false, false, false, address(raffle));
        emit EnteredRaffle(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
    }

    function testCantEnterWhenRaffleIsCalculating() public {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();

        // move time forward to make the raffle calculate winner and close entry
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        raffle.performUpkeep("");

        vm.expectRevert(Raffle.Raffle__RaffleNotOpen.selector);
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
    }

}