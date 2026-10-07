// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {FlashbotsSearcherBot} from "../src/08_Oracles/FlashbotsSearcherBot.sol";

contract MockPool {
    function swapStep() external payable {
        // Generates small arbitrage profit by returning ether to caller
        (bool s,) = msg.sender.call{value: msg.value + 0.1 ether}("");
        require(s);
    }
}

contract FlashbotsSearcherBotTest is Test {
    FlashbotsSearcherBot public bot;
    MockPool public pool1;
    MockPool public pool2;
    MockPool public pool3;

    function setUp() public {
        bot = new FlashbotsSearcherBot();
        pool1 = new MockPool();
        pool2 = new MockPool();
        pool3 = new MockPool();

        vm.deal(address(pool1), 10 ether);
        vm.deal(address(pool2), 10 ether);
        vm.deal(address(pool3), 10 ether);
        vm.deal(address(bot), 1 ether);
    }

    function test_TriangularArbitrageExecution() public {
        address[] memory pools = new address[](3);
        pools[0] = address(pool1);
        pools[1] = address(pool2);
        pools[2] = address(pool3);

        bytes[] memory data = new bytes[](3);
        data[0] = abi.encodeWithSignature("swapStep()");
        data[1] = abi.encodeWithSignature("swapStep()");
        data[2] = abi.encodeWithSignature("swapStep()");

        uint256 profit = bot.executeTriangularArbitrage(pools, data, 1 ether, 0.1 ether, 0.05 ether);
        assertGt(profit, 0);
    }
}
