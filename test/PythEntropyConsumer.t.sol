// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {PythEntropyConsumer} from "../src/08_Oracles/PythEntropyConsumer.sol";

contract PythEntropyConsumerTest is Test {
    PythEntropyConsumer public consumer;
    uint256 internal publisherKey = 0xBEEF1;
    address internal publisher;

    bytes32 public ethFeedId = keccak256("ETH/USD");

    function setUp() public {
        vm.warp(10_000);
        publisher = vm.addr(publisherKey);
        consumer = new PythEntropyConsumer(publisher);
    }

    function test_UpdateAndQueryPythPrice() public {
        int64 price = 3000_00000000; // $3000
        uint64 conf = 1_00000000;
        int32 expo = -8;
        uint256 publishTime = 9_990;

        bytes32 payloadHash = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32", keccak256(abi.encode(ethFeedId, price, conf, expo, publishTime))
            )
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(publisherKey, payloadHash);

        consumer.updatePrice(ethFeedId, price, conf, expo, publishTime, v, r, s);

        (int64 recordedPrice, uint256 time) = consumer.getPrice(ethFeedId);
        assertEq(recordedPrice, price);
        assertEq(time, publishTime);
    }

    function test_StalePriceReverts() public {
        // Warp past max staleness (60 seconds)
        vm.warp(10_100);

        int64 price = 3000_00000000;
        uint64 conf = 1_00000000;
        int32 expo = -8;
        uint256 oldTime = 9_900; // 200 seconds stale

        bytes32 payloadHash = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32", keccak256(abi.encode(ethFeedId, price, conf, expo, oldTime))
            )
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(publisherKey, payloadHash);

        vm.expectRevert(PythEntropyConsumer.PriceStale.selector);
        consumer.updatePrice(ethFeedId, price, conf, expo, oldTime, v, r, s);
    }
}
