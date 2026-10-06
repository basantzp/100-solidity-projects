// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {ChainlinkFallbackOracle, IAggregatorV3} from "../src/08_Oracles/ChainlinkFallbackOracle.sol";

contract MockAggregator is IAggregatorV3 {
    uint8 public decimals = 8;
    int256 public answer;
    uint256 public updatedAt;
    uint80 public roundId = 1;

    function setPrice(int256 _price, uint256 _updatedAt) external {
        answer = _price;
        updatedAt = _updatedAt;
    }

    function latestRoundData() external view returns (uint80, int256, uint256, uint256, uint80) {
        return (roundId, answer, updatedAt, updatedAt, roundId);
    }
}

contract ChainlinkFallbackOracleTest is Test {
    MockAggregator public primary;
    MockAggregator public fallbackFeed;
    ChainlinkFallbackOracle public oracle;

    function setUp() public {
        vm.warp(10000); // Advance past genesis to avoid timestamp underflow

        primary = new MockAggregator();
        fallbackFeed = new MockAggregator();

        // 1 hour max staleness, min price $100, max price $100,000 (scaled by 1e8)
        oracle = new ChainlinkFallbackOracle(address(primary), address(fallbackFeed), 3600, 100e8, 100_000e8);
    }

    function test_ReadsPrimaryWhenFresh() public {
        primary.setPrice(2500e8, block.timestamp);
        fallbackFeed.setPrice(2490e8, block.timestamp);

        (int256 price, uint8 dec) = oracle.getLatestPrice();
        assertEq(price, 2500e8);
        assertEq(dec, 8);
    }

    function test_FailsOverToFallbackWhenPrimaryStale() public {
        // Primary updated 2 hours ago (> 1 hour max staleness)
        primary.setPrice(2500e8, block.timestamp - 7200);

        // Fallback is fresh
        fallbackFeed.setPrice(2480e8, block.timestamp);

        (int256 price, uint8 dec) = oracle.getLatestPrice();
        assertEq(price, 2480e8);
        assertEq(dec, 8);
    }

    function test_FailsOverWhenPrimaryHitsExtremeCircuitBreaker() public {
        // Primary reports corrupted price ($10 < $100 min bounds)
        primary.setPrice(10e8, block.timestamp);

        // Fallback reports valid price
        fallbackFeed.setPrice(2500e8, block.timestamp);

        (int256 price,) = oracle.getLatestPrice();
        assertEq(price, 2500e8);
    }
}
