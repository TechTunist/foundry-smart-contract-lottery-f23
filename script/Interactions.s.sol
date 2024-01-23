//SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script} from "lib/forge-std/src/Script.sol";

contract CreateSubscription is Script {
    function run() external returns (uint64) {
        vm.startBroadcast();
        uint64 subscriptionId = 0;
        vm.stopBroadcast();

        return subscriptionId;
    }
}