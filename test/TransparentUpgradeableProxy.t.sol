// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {TransparentUpgradeableProxy} from "../src/06_Upgradeability/TransparentUpgradeableProxy.sol";

contract BoxV1 {
    uint256 public value;

    function setValue(uint256 v) external {
        value = v;
    }

    function version() external pure returns (uint256) {
        return 1;
    }
}

contract BoxV2 {
    uint256 public value;

    function setValue(uint256 v) external {
        value = v;
    }

    function version() external pure returns (uint256) {
        return 2;
    }
}

contract TransparentUpgradeableProxyTest is Test {
    BoxV1 public v1;
    BoxV2 public v2;
    TransparentUpgradeableProxy public proxy;

    address public admin = address(0xAD);
    address public alice = address(0xA11CE);

    function setUp() public {
        v1 = new BoxV1();
        v2 = new BoxV2();

        proxy = new TransparentUpgradeableProxy(address(v1), admin, "");
    }

    function test_UserCallsDelegateToImplementation() public {
        BoxV1 proxiedBox = BoxV1(address(proxy));

        vm.prank(alice);
        proxiedBox.setValue(100);

        assertEq(proxiedBox.value(), 100);
        assertEq(proxiedBox.version(), 1);
    }

    function test_AdminCanUpgradeImplementation() public {
        BoxV1 proxiedBox = BoxV1(address(proxy));

        vm.prank(alice);
        proxiedBox.setValue(100);

        // Admin upgrades to V2
        vm.prank(admin);
        proxy.upgradeTo(address(v2));

        // Implementation upgraded while preserving state
        assertEq(proxiedBox.version(), 2);
        assertEq(proxiedBox.value(), 100);
    }

    function test_AdminDirectCallCannotTriggerImplementationFallback() public {
        BoxV1 proxiedBox = BoxV1(address(proxy));

        // When admin attempts to call implementation function, it reverts with segregation guard
        vm.prank(admin);
        vm.expectRevert("TransparentProxy: admin cannot call fallback");
        proxiedBox.setValue(50);
    }
}
