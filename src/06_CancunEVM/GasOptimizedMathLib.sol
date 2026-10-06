// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/// @title GasOptimizedMathLib
/// @notice Ultra gas-optimized Yul assembly fixed-point WAD (1e18) and RAY (1e27) math library.
library GasOptimizedMathLib {
    uint256 internal constant WAD = 1e18;
    uint256 internal constant RAY = 1e27;
    uint256 internal constant HALF_WAD = 0.5e18;
    uint256 internal constant HALF_RAY = 0.5e27;
    uint256 internal constant WAD_RAY_RATIO = 1e9;

    error MathOverflow();
    error DivisionByZero();

    function wadMul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        assembly {
            if iszero(or(iszero(x), eq(div(mul(x, y), x), y))) {
                // Revert on multiplication overflow
                mstore(0x00, 0x8f32d59b) // MathOverflow()
                revert(0x1c, 0x04)
            }
            z := div(add(mul(x, y), HALF_WAD), WAD)
        }
    }

    function wadDiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        assembly {
            if iszero(y) {
                mstore(0x00, 0x35278d12) // DivisionByZero()
                revert(0x1c, 0x04)
            }
            let scaled := mul(x, WAD)
            if iszero(or(iszero(x), eq(div(scaled, x), WAD))) {
                mstore(0x00, 0x8f32d59b)
                revert(0x1c, 0x04)
            }
            z := div(add(scaled, div(y, 2)), y)
        }
    }

    function rayMul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        assembly {
            if iszero(or(iszero(x), eq(div(mul(x, y), x), y))) {
                mstore(0x00, 0x8f32d59b)
                revert(0x1c, 0x04)
            }
            z := div(add(mul(x, y), HALF_RAY), RAY)
        }
    }

    function rayDiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        assembly {
            if iszero(y) {
                mstore(0x00, 0x35278d12)
                revert(0x1c, 0x04)
            }
            let scaled := mul(x, RAY)
            if iszero(or(iszero(x), eq(div(scaled, x), RAY))) {
                mstore(0x00, 0x8f32d59b)
                revert(0x1c, 0x04)
            }
            z := div(add(scaled, div(y, 2)), y)
        }
    }

    function wadToRay(uint256 x) internal pure returns (uint256 z) {
        assembly {
            z := mul(x, WAD_RAY_RATIO)
            if iszero(or(iszero(x), eq(div(z, x), WAD_RAY_RATIO))) {
                mstore(0x00, 0x8f32d59b)
                revert(0x1c, 0x04)
            }
        }
    }

    function rayToWad(uint256 x) internal pure returns (uint256 z) {
        assembly {
            z := div(add(x, 500000000), WAD_RAY_RATIO)
        }
    }
}
