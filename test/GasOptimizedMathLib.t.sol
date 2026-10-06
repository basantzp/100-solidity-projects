// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {GasOptimizedMathLib} from "../src/06_CancunEVM/GasOptimizedMathLib.sol";

contract MathConsumer {
    function wadMul(uint256 x, uint256 y) external pure returns (uint256) {
        return GasOptimizedMathLib.wadMul(x, y);
    }

    function wadDiv(uint256 x, uint256 y) external pure returns (uint256) {
        return GasOptimizedMathLib.wadDiv(x, y);
    }

    function rayMul(uint256 x, uint256 y) external pure returns (uint256) {
        return GasOptimizedMathLib.rayMul(x, y);
    }

    function rayDiv(uint256 x, uint256 y) external pure returns (uint256) {
        return GasOptimizedMathLib.rayDiv(x, y);
    }

    function wadToRay(uint256 x) external pure returns (uint256) {
        return GasOptimizedMathLib.wadToRay(x);
    }

    function rayToWad(uint256 x) external pure returns (uint256) {
        return GasOptimizedMathLib.rayToWad(x);
    }
}

contract GasOptimizedMathLibTest is Test {
    MathConsumer public math;

    function setUp() public {
        math = new MathConsumer();
    }

    function test_WadMulAndDiv() public view {
        // 2 WAD * 3 WAD = 6 WAD
        uint256 product = math.wadMul(2e18, 3e18);
        assertEq(product, 6e18);

        // 6 WAD / 2 WAD = 3 WAD
        uint256 quotient = math.wadDiv(6e18, 2e18);
        assertEq(quotient, 3e18);
    }

    function test_RayMulAndDiv() public view {
        // 4 RAY * 2.5 RAY = 10 RAY
        uint256 product = math.rayMul(4e27, 2.5e27);
        assertEq(product, 10e27);

        // 10 RAY / 4 RAY = 2.5 RAY
        uint256 quotient = math.rayDiv(10e27, 4e27);
        assertEq(quotient, 2.5e27);
    }

    function test_WadToRayAndRayToWad() public view {
        uint256 wadVal = 5e18;
        uint256 rayVal = math.wadToRay(wadVal);
        assertEq(rayVal, 5e27);

        uint256 backToWad = math.rayToWad(rayVal);
        assertEq(backToWad, wadVal);
    }
}
