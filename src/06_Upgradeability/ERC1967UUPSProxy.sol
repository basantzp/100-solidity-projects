// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/// @title ERC1967UUPSProxy
/// @notice Universal Upgradeable Proxy Standard (UUPS) adhering to ERC-1967 storage slots.
/// @dev In UUPS, upgrade authorization logic resides within the implementation rather than the proxy.
contract ERC1967UUPSProxy {
    // bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1)
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    constructor(address logic, bytes memory data) payable {
        _setImplementation(logic);
        if (data.length > 0) {
            (bool success,) = logic.delegatecall(data);
            require(success, "Initialization failed");
        }
    }

    fallback() external payable {
        _fallback();
    }

    receive() external payable {
        _fallback();
    }

    function _fallback() internal {
        assembly {
            let impl := sload(_IMPLEMENTATION_SLOT)
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), impl, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    function _setImplementation(address newImplementation) private {
        assembly {
            sstore(_IMPLEMENTATION_SLOT, newImplementation)
        }
    }
}

/// @notice Abstract base for UUPS implementations
abstract contract UUPSUpgradeable {
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    error Unauthorized();
    error InvalidImplementation();

    event Upgraded(address indexed implementation);

    function upgradeTo(address newImplementation) external {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCall(newImplementation, "");
    }

    function upgradeToAndCall(address newImplementation, bytes memory data) external payable {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCall(newImplementation, data);
    }

    function _upgradeToAndCall(address newImplementation, bytes memory data) internal {
        if (newImplementation.code.length == 0) revert InvalidImplementation();

        assembly {
            sstore(_IMPLEMENTATION_SLOT, newImplementation)
        }

        emit Upgraded(newImplementation);

        if (data.length > 0) {
            (bool success,) = newImplementation.delegatecall(data);
            require(success, "Upgrade call failed");
        }
    }

    function _authorizeUpgrade(address newImplementation) internal virtual;
}
