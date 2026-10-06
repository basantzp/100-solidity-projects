// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

interface IBeacon {
    function implementation() external view returns (address);
}

/// @title UpgradeableBeacon
/// @notice Central beacon storing the implementation pointer for a fleet of BeaconProxies.
contract UpgradeableBeacon is IBeacon {
    error Unauthorized();
    error InvalidImplementation();

    event Upgraded(address indexed implementation);

    address public owner;
    address private _implementation;

    modifier onlyOwner() {
        if (msg.sender != owner) revert Unauthorized();
        _;
    }

    constructor(address initialImplementation) {
        if (initialImplementation.code.length == 0) revert InvalidImplementation();
        owner = msg.sender;
        _implementation = initialImplementation;
    }

    function implementation() external view override returns (address) {
        return _implementation;
    }

    function upgradeTo(address newImplementation) external onlyOwner {
        if (newImplementation.code.length == 0) revert InvalidImplementation();
        _implementation = newImplementation;
        emit Upgraded(newImplementation);
    }
}

/// @title BeaconProxy
/// @notice Lightweight proxy delegating calls to the implementation reported by a central Beacon.
contract BeaconProxy {
    address public immutable beacon;

    constructor(address _beacon, bytes memory data) payable {
        beacon = _beacon;
        if (data.length > 0) {
            address impl = IBeacon(_beacon).implementation();
            (bool success,) = impl.delegatecall(data);
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
        address impl = IBeacon(beacon).implementation();
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), impl, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }
}
