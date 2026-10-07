// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {FallbackDelegator} from "../src/06_Upgradeability/FallbackDelegator.sol";

contract CounterFacet {
    uint256 public count; // slot 1 in delegator (admin is slot 0)

    function increment() external {
        count += 1;
    }

    function getCount() external view returns (uint256) {
        return count;
    }
}

contract FallbackDelegatorTest is Test {
    FallbackDelegator public delegator;
    CounterFacet public facet;

    function setUp() public {
        delegator = new FallbackDelegator();
        facet = new CounterFacet();

        delegator.setImplementation(bytes4(keccak256("increment()")), address(facet));
        delegator.setImplementation(bytes4(keccak256("getCount()")), address(facet));
    }

    function test_DelegateCallRouting() public {
        (bool s1,) = address(delegator).call(abi.encodeWithSignature("increment()"));
        assertTrue(s1);

        (bool s2, bytes memory data) = address(delegator).call(abi.encodeWithSignature("getCount()"));
        assertTrue(s2);

        uint256 val = abi.decode(data, (uint256));
        assertEq(val, 1);
    }
}
