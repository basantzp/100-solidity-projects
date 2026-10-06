// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {MinimalProxyFactory} from "../src/06_Upgradeability/MinimalProxyFactory.sol";

contract ImplementationLogic {
    uint256 public value;
    address public owner;

    function initialize(uint256 _value, address _owner) external {
        require(owner == address(0), "Already initialized");
        value = _value;
        owner = _owner;
    }

    function setValue(uint256 _value) external {
        require(msg.sender == owner, "Not owner");
        value = _value;
    }
}

contract MinimalProxyFactoryTest is Test {
    MinimalProxyFactory factory;
    ImplementationLogic implementation;

    address alice = address(0x1);

    function setUp() public {
        factory = new MinimalProxyFactory();
        implementation = new ImplementationLogic();
    }

    function test_CloneInstanceHasIsolatedState() public {
        address clone1 = factory.clone(address(implementation));
        address clone2 = factory.clone(address(implementation));

        assertTrue(clone1 != clone2);

        ImplementationLogic(clone1).initialize(100, alice);
        ImplementationLogic(clone2).initialize(200, address(this));

        assertEq(ImplementationLogic(clone1).value(), 100);
        assertEq(ImplementationLogic(clone2).value(), 200);
        assertEq(ImplementationLogic(clone1).owner(), alice);
        assertEq(ImplementationLogic(clone2).owner(), address(this));

        // Original implementation remains uninitialized
        assertEq(implementation.value(), 0);
        assertEq(implementation.owner(), address(0));
    }

    function test_DeterministicCloneMatchesPredictedAddress() public {
        bytes32 salt = bytes32(uint256(12345));
        address predicted = factory.predictDeterministicAddress(address(implementation), salt, address(factory));

        address deployed = factory.cloneDeterministic(address(implementation), salt);
        assertEq(deployed, predicted);
    }
}
