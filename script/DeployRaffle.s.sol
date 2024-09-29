// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "../lib/forge-std/src/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {CreateSubscription} from "./Integration.s.sol";

contract DeployRaffle is Script {
    function deployContract() external returns (Raffle, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

        if (config.subcriptionID == 0) {}
        CreateSubscription createSubscription = new CreateSubscription();
        (config.subcriptionID, config.vrfCoordinator) = createSubscription
            .createSubscription(config.vrfCoordinator);

        vm.startBroadcast();
        Raffle raffle = new Raffle(
            config.entranceFee,
            config.interval,
            config.vrfCoordinator,
            config.subcriptionID,
            config.keyhash,
            config.gasLimit
        );
        vm.stopBroadcast();

        return (raffle, helperConfig);
    }
}
