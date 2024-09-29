// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "../lib/forge-std/src/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

abstract contract CodeConstants {
    /**
     * Mocks variables
     */
    uint96 public MOCK_BASE_FEE = 0.25 ether;
    uint96 public MOCK_GAS_FEE = 1e9;
    int256 public MOCK_WEI_PER_UINT_LINK = 4e15;

    uint256 public constant SEPOLIA_CHAIN_ID = 11155111;
    uint256 public constant LOCAL_CHAIN_ID = 31337;
    uint256 public constant ETH_MAINNET_CHAIN_ID = 1;
}

contract HelperConfig is Script, CodeConstants {
    error HelperConfig__InvalidChainId();

    struct NetworkConfig {
        uint256 entranceFee;
        uint256 interval;
        address vrfCoordinator;
        uint256 subcriptionID;
        bytes32 keyhash;
        uint32 gasLimit;
    }

    NetworkConfig public localNetworkConfig;

    mapping(uint256 chainId => NetworkConfig) public networkConfigs;

    constructor() {
        networkConfigs[SEPOLIA_CHAIN_ID] = getSepoliaEthConfig();
    }

    function getConfigByChainId(
        uint256 chainID
    ) public returns (NetworkConfig memory) {
        if (networkConfigs[chainID].vrfCoordinator != address(0)) {
            return networkConfigs[chainID];
        } else if (chainID == LOCAL_CHAIN_ID) {
            return getOrCreateAnvilEthConfig();
        } else {
            revert HelperConfig__InvalidChainId();
        }
    }

    function getConfig() public returns (NetworkConfig memory) {
        return getConfigByChainId(block.chainid);
    }

    function getSepoliaEthConfig() public pure returns (NetworkConfig memory) {
        return
            NetworkConfig({
                entranceFee: 0.01 ether,
                interval: 60,
                vrfCoordinator: 0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625,
                subcriptionID: 0,
                keyhash: 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c,
                gasLimit: 500000
            });
    }

    // function getMainetEthConfig() public returns (NetworkConfig memory) {
    //     return
    //         NetworkConfig({
    //             entranceFee: 0.01 ether,
    //             interval: 60,
    //             vrfCoordinator: 0x271682DEB8C4E0901D1a1550aD2e64D568E69909,
    //             subcriptionID: 0,
    //             keyhash: 0x9fe0eebf5e446e3c998ec9bb19951541aee00bb90ea201ae456421a2ded86805,
    //             gasLimit: 500000
    //         });
    // }

    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory) {
        if (localNetworkConfig.vrfCoordinator != address(0)) {
            return localNetworkConfig;
        }

        //Deploy mocks
        vm.startBroadcast();
        VRFCoordinatorV2_5Mock vrfCoordinatorV2_5Mock = new VRFCoordinatorV2_5Mock(
                MOCK_BASE_FEE,
                MOCK_GAS_FEE,
                MOCK_WEI_PER_UINT_LINK
            );

        localNetworkConfig = NetworkConfig({
            entranceFee: 0.01 ether,
            interval: 60,
            vrfCoordinator: address(vrfCoordinatorV2_5Mock),
            subcriptionID: 0,
            keyhash: 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c,
            gasLimit: 500000
        });
        vm.stopBroadcast();
        return localNetworkConfig;
    }
}
