// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {UpgradeableBeacon, BeaconProxy} from "../src/06_Upgradeability/BeaconProxy.sol";

contract LogicV1 {
    uint256 public value;

    function setValue(uint256 v) external {
        value = v;
    }

    function version() external pure returns (uint256) {
        return 1;
    }
}

contract LogicV2 {
    uint256 public value;

    function setValue(uint256 v) external {
        value = v;
    }

    function version() external pure returns (uint256) {
        return 2;
    }
}

contract BeaconProxyTest is Test {
    LogicV1 public v1;
    LogicV2 public v2;
    UpgradeableBeacon public beacon;
    BeaconProxy public proxyA;
    BeaconProxy public proxyB;

    function setUp() public {
        v1 = new LogicV1();
        v2 = new LogicV2();

        beacon = new UpgradeableBeacon(address(v1));
        proxyA = new BeaconProxy(address(beacon), "");
        proxyB = new BeaconProxy(address(beacon), "");
    }

    function test_UpgradeBeaconUpgradesEntireFleet() public {
        LogicV1(address(proxyA)).setValue(10);
        LogicV1(address(proxyB)).setValue(20);

        assertEq(LogicV1(address(proxyA)).version(), 1);
        assertEq(LogicV1(address(proxyB)).version(), 1);

        // Upgrade beacon to V2
        beacon.upgradeTo(address(v2));

        // Both proxies immediately execute V2 logic while keeping independent state!
        assertEq(LogicV2(address(proxyA)).version(), 2);
        assertEq(LogicV2(address(proxyB)).version(), 2);
        assertEq(LogicV2(address(proxyA)).value(), 10);
        assertEq(LogicV2(address(proxyB)).value(), 20);
    }
}
