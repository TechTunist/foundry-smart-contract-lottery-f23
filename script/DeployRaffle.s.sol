// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script} from "lib/forge-std/src/Script.sol";
import {Raffle} from "src/Raffle.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import { CreateSubscription, FundSubscription, AddConsumer } from "script/Interactions.s.sol";


contract DeployRaffle is Script {
    function run() external returns (Raffle, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();
        (
            uint256 entranceFee,
            uint256 interval,
            address vrfCoordinator,
            bytes32 gasLane,
            uint64 subscriptionId,
            uint32 callbackGasLimit,
            address link
        ) = helperConfig.activeNetworkConfig();

        if (subscriptionId == 0) {
            // here we created a subscription
            CreateSubscription createSubscription = new CreateSubscription();
            subscriptionId = createSubscription.createSubscription(vrfCoordinator);

            // now we need to fund the subscription with link
            FundSubscription fundSubscription = new FundSubscription();
            fundSubscription.fundSubscription(vrfCoordinator, subscriptionId, link);

        }

        vm.startBroadcast();
        Raffle raffle = new Raffle(
            entranceFee,
            interval,
            vrfCoordinator,
            gasLane,
            subscriptionId,
            callbackGasLimit
        );
        vm.stopBroadcast();
        
        AddConsumer addConsumer = new AddConsumer();
        addConsumer.addConsumer(address(raffle), vrfCoordinator, subscriptionId);
        

        return (raffle, helperConfig);
    }
}