// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/// @title LowLevelDispatcher
/// @notice Ultra-low gas custom Yul function selector dispatcher and jump table.
contract LowLevelDispatcher {
    // Slot 0: stored value
    // Slot 1: contract owner

    // Selectors:
    // getOwner()       = 0x893d20e8
    // getVal()         = 0xe1cb0e52
    // setVal(uint256)  = 0x3d4197f0

    constructor() {
        assembly {
            sstore(1, caller())
        }
    }

    receive() external payable {}

    fallback() external payable {
        assembly {
            let selector := shr(224, calldataload(0))

            // Selector: getVal() -> 0xe1cb0e52
            if eq(selector, 0xe1cb0e52) {
                mstore(0, sload(0))
                return(0, 32)
            }

            // Selector: getOwner() -> 0x893d20e8
            if eq(selector, 0x893d20e8) {
                mstore(0, sload(1))
                return(0, 32)
            }

            // Selector: setVal(uint256) -> 0x3d4197f0
            if eq(selector, 0x3d4197f0) {
                // Ensure sender is owner
                if iszero(eq(caller(), sload(1))) {
                    revert(0, 0)
                }
                let newVal := calldataload(4)
                sstore(0, newVal)
                mstore(0, 1)
                return(0, 32)
            }

            // Unknown selector
            revert(0, 0)
        }
    }
}
