// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {MetamorphicContract} from "../src/06_Upgradeability/MetamorphicContract.sol";

contract SimpleLogic {
    uint256 public count = 42;

    function getCount() external view returns (uint256) {
        return count;
    }
}

contract MetamorphicContractTest is Test {
    MetamorphicContract public factory;

    function setUp() public {
        factory = new MetamorphicContract();
    }

    function test_ComputeAndDeployCREATE2() public {
        bytes memory bytecode = type(SimpleLogic).creationCode;
        bytes32 salt = keccak256("test-salt-1");

        address predicted = factory.computeAddress(salt, bytecode);
        address deployed = factory.deploy(salt, bytecode);

        assertEq(predicted, deployed);
        assertEq(SimpleLogic(deployed).getCount(), 42);
    }
}
