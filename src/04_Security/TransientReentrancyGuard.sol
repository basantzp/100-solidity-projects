// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title TransientReentrancyGuard
/// @notice Gas-optimized reentrancy protection using EIP-1153 transient storage (Cancun EVM)
/// @dev Replaces 2,100 gas SSTORE/SLOAD pattern with 100 gas tstore/tload instructions
abstract contract TransientReentrancyGuard {
    error ReentrantCall();

    /// @dev Storage slot for transient reentrancy lock: keccak256("TransientReentrancyGuard.lock")
    bytes32 private constant REENTRANCY_SLOT = 0x8e94f1c9c8e1e7f0b9f9361be8e9d25950e3b6d2678683515456f96603a11985;

    modifier nonReentrant() {
        _enter();
        _;
        _exit();
    }

    function _enter() private {
        assembly {
            // Check if slot currently has value 1
            if tload(REENTRANCY_SLOT) {
                // Revert with ReentrantCall() selector: 0x37ed32e8
                mstore(0x00, 0x37ed32e8)
                revert(0x1c, 0x04)
            }
            // Set lock to 1
            tstore(REENTRANCY_SLOT, 1)
        }
    }

    function _exit() private {
        assembly {
            // Reset lock to 0
            tstore(REENTRANCY_SLOT, 0)
        }
    }
}
