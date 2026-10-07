// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/// @title UpgradeSanitizer
/// @notice Initializer security guard preventing implementation takeover and front-running re-initialization.
abstract contract UpgradeSanitizer {
    // --- Errors ---
    error InvalidInitialization();
    error NotInitializing();

    // --- Events ---
    event Initialized(uint64 version);

    // Storage layout matching OpenZeppelin Initializable layout
    // Bit 0: initializing
    // Bits 1-64: initializedVersion
    uint64 private _initialized;
    bool private _initializing;

    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        uint64 initialVersion = _initialized;

        if (!(isTopLevelCall && initialVersion == 0)) {
            revert InvalidInitialization();
        }

        _initialized = 1;
        _initializing = true;

        _;

        _initializing = false;
        emit Initialized(1);
    }

    modifier reinitializer(uint64 version) {
        if (_initializing || _initialized >= version) {
            revert InvalidInitialization();
        }

        _initialized = version;
        _initializing = true;

        _;

        _initializing = false;
        emit Initialized(version);
    }

    /// @notice Locks the implementation contract to prevent attackers from initializing it directly
    function _disableInitializers() internal virtual {
        if (_initializing) revert InvalidInitialization();
        if (_initialized < type(uint64).max) {
            _initialized = type(uint64).max;
            emit Initialized(type(uint64).max);
        }
    }

    function getInitializedVersion() external view returns (uint64) {
        return _initialized;
    }
}

/// @title MockSanitizedContract
/// @notice Concrete implementation for testing UpgradeSanitizer behavior
contract MockSanitizedContract is UpgradeSanitizer {
    uint256 public value;
    address public admin;

    constructor() {
        _disableInitializers();
    }

    function initialize(uint256 _value, address _admin) external initializer {
        value = _value;
        admin = _admin;
    }

    function upgradeVersion(uint64 newVer, uint256 _newVal) external reinitializer(newVer) {
        value = _newVal;
    }
}
