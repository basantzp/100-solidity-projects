// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {ERC1967UUPSProxy, UUPSUpgradeable} from "../src/06_Upgradeability/ERC1967UUPSProxy.sol";

contract CounterV1 is UUPSUpgradeable {
    address public owner;
    uint256 public count;

    function initialize(address _owner) external {
        require(owner == address(0), "Already initialized");
        owner = _owner;
    }

    function increment() external {
        count += 1;
    }

    function _authorizeUpgrade(address) internal view override {
        if (msg.sender != owner) revert Unauthorized();
    }
}

contract CounterV2 is UUPSUpgradeable {
    address public owner;
    uint256 public count;

    function increment() external {
        count += 1;
    }

    function multiply(uint256 factor) external {
        count *= factor;
    }

    function _authorizeUpgrade(address) internal view override {
        if (msg.sender != owner) revert Unauthorized();
    }
}

contract ERC1967UUPSProxyTest is Test {
    CounterV1 public v1;
    CounterV2 public v2;
    ERC1967UUPSProxy public proxy;

    address public owner = address(this);
    address public attacker = address(0xDEAD);

    function setUp() public {
        v1 = new CounterV1();
        v2 = new CounterV2();

        bytes memory initData = abi.encodeWithSelector(CounterV1.initialize.selector, owner);
        proxy = new ERC1967UUPSProxy(address(v1), initData);
    }

    function test_UUPSProxyUpgradeFlow() public {
        CounterV1 proxyV1 = CounterV1(address(proxy));

        assertEq(proxyV1.owner(), owner);
        assertEq(proxyV1.count(), 0);

        proxyV1.increment();
        assertEq(proxyV1.count(), 1);

        // Upgrade to V2
        proxyV1.upgradeTo(address(v2));

        // State is preserved!
        CounterV2 proxyV2 = CounterV2(address(proxy));
        assertEq(proxyV2.count(), 1);

        // New V2 function works
        proxyV2.multiply(5);
        assertEq(proxyV2.count(), 5);
    }

    function test_RevertIf_UnauthorizedUpgrade() public {
        CounterV1 proxyV1 = CounterV1(address(proxy));

        vm.prank(attacker);
        vm.expectRevert(UUPSUpgradeable.Unauthorized.selector);
        proxyV1.upgradeTo(address(v2));
    }
}
