// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/// @title FallbackDelegator
/// @notice Dynamic selector-to-implementation mapping router allowing independent per-function delegatecall upgrades.
contract FallbackDelegator {
    // --- Errors ---
    error Unauthorized();
    error FunctionNotFound();
    error DelegateCallFailed();

    // --- Events ---
    event ImplementationSet(bytes4 indexed selector, address indexed oldImpl, address indexed newImpl);

    address public immutable admin;
    mapping(bytes4 => address) public implementations;

    modifier onlyAdmin() {
        if (msg.sender != admin) revert Unauthorized();
        _;
    }

    constructor() {
        admin = msg.sender;
    }

    function setImplementation(bytes4 selector, address impl) external onlyAdmin {
        address old = implementations[selector];
        implementations[selector] = impl;
        emit ImplementationSet(selector, old, impl);
    }

    fallback() external payable {
        address impl = implementations[msg.sig];
        if (impl == address(0)) revert FunctionNotFound();

        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), impl, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())

            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    receive() external payable {}
}
