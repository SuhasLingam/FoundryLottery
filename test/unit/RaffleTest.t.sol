// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test, console} from "lib/forge-std/src/Test.sol";
import {Raffle} from "src/Raffle.sol";
import {DeployRaffle} from "script/DeployRaffle.s.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";

contract RaffleContractTesting is Test {
    Raffle public raffle;
    HelperConfig public helperConfig;

    uint256 entranceFee;
    uint256 interval;
    address vrfCoordinator;
    uint256 subcriptionID;
    bytes32 keyhash;
    uint32 gasLimit;

    address public PLAYER = makeAddr("player");
    uint256 public constant STARTING_PLAYER_BALANCE = 10 ether;

    event RaffleEntered(address indexed player);
    event PickedWinner(address indexed winner);

    function setUp() external {
        DeployRaffle deployer = new DeployRaffle();
        (raffle, helperConfig) = deployer.deployContract();
        vm.deal(PLAYER, STARTING_PLAYER_BALANCE);
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
        entranceFee = config.entranceFee;
        interval = config.interval;
        vrfCoordinator = config.vrfCoordinator;
        subcriptionID = config.subcriptionID;
        keyhash = config.keyhash;
        gasLimit = config.gasLimit;
    }

    function testEnterRaffle() public view {
        assert(uint256(raffle.getRaffleStatus()) == 0);
    }

    function testGetIntervalTime() public view {
        assert(uint256(raffle.getEntranceFee()) == 0.01 ether);
    }

    function testMsgValueIsGreaterThanOrEqualToEntraceFee() public {
        vm.prank(PLAYER);
        vm.expectRevert(Raffle.Raffle__SendMoreToEnterRaffle.selector);
        raffle.enterRaffle();
    }

    function testRaffleRecordsPlayersWhenTheyEnter() public {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        address playerAddressInArray = raffle.getPlayer(0);
        assert(playerAddressInArray == PLAYER);
    }

    function testRaffleEventEmmited() public {
        vm.prank(PLAYER);
        vm.expectEmit(true, false, false, false);
        emit RaffleEntered(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
    }

    function testDontAllowPlayersEnterRaffleWhileCalculating() public {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: 2 ether}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number);
        raffle.performUpkeep("");

        // try to enter

        vm.expectRevert(Raffle.Raffle__RaffleNotOpen.selector);
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
    }

    /**
     * CheckUpKeep tests
     */
    function testCheckUpKeepReturnsFalseIfLessBalance() public {
        vm.prank(PLAYER);
        vm.warp(block.timestamp + interval + 1);
        (bool upkeepNeeded,) = raffle.checkUpkeep("");
        assert(!upkeepNeeded);
    }

    function testCheckUpKeepReturnsFalseIfRaffleNotOpen() public {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        raffle.performUpkeep("");

        (bool upkeepNeeded,) = raffle.checkUpkeep("");
        assert(!upkeepNeeded);
    }

    function testCheckUpKeepReturnsFalseIfEnoughTimeHasPassed() public {
        vm.prank(PLAYER);
        vm.warp(block.timestamp + interval - 1);
        (bool upkeepNeeded,) = raffle.checkUpkeep("");
        assert(!upkeepNeeded);
    }

    function testCheckUpKeepReturnsFalseIfNoEnoughPlayers() public {
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number);

        (bool upkeepNeeded,) = raffle.checkUpkeep("");
        assert(!upkeepNeeded);
    }

    function testCheckUpKeepIfTrueIfUpkeepneededisTrue() public {
        vm.prank(PLAYER);
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number);
        raffle.enterRaffle{value: entranceFee}();
        (bool upkeepNeeded,) = raffle.checkUpkeep("");
        assert(upkeepNeeded);
    }

    /**
     * PerformUpkeep tests
     */
    function testPerformUpkeepReturnsTrueOnlyIfCheckUpkeepIsTrue() public {
        vm.prank(PLAYER);
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number);
        raffle.enterRaffle{value: entranceFee}();

        raffle.performUpkeep("");
    }

    function testPerformUpkeepRevertsIfUpkeepNeededIsFalse() public {
        uint256 balance = 0;
        uint256 totalPlayers = 0;
        Raffle.RaffleStatus rStatus = raffle.getRaffleStatus();

        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        balance = balance + entranceFee;
        totalPlayers = 1;

        //Expect Revert if the Revert has return values
        vm.expectRevert(abi.encodeWithSelector(Raffle.Raffle__UpKeepNotNeeded.selector, balance, totalPlayers, rStatus));
        raffle.performUpkeep("");
    }

    function testPerformUpkeepRevertsIfTimeLeftForResults() public {
        vm.prank(PLAYER);
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number);
        raffle.enterRaffle{value: entranceFee}();

        
        
    }
}
