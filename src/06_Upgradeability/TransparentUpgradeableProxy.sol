// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/// @title TransparentUpgradeableProxy
/// @notice OpenZeppelin-standard Transparent Upgradeable Proxy with strict admin/user selector clash segregation.
contract TransparentUpgradeableProxy {
    // bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1)
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    // bytes32(uint256(keccak256("eip1967.proxy.admin")) - 1)
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    event Upgraded(address indexed implementation);
    event AdminChanged(address previousAdmin, address newAdmin);

    modifier ifAdmin() {
        if (msg.sender == _getAdmin()) {
            _;
        } else {
            _fallback();
        }
    }

    constructor(address logic, address admin, bytes memory data) payable {
        _setAdmin(admin);
        _setImplementation(logic);
        if (data.length > 0) {
            (bool success,) = logic.delegatecall(data);
            require(success, "Initialization failed");
        }
    }

    // --- Admin Functions ---

    function upgradeTo(address newImplementation) external ifAdmin {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    function changeAdmin(address newAdmin) external ifAdmin {
        require(newAdmin != address(0), "Zero admin");
        address prev = _getAdmin();
        _setAdmin(newAdmin);
        emit AdminChanged(prev, newAdmin);
    }

    function getImplementation() external ifAdmin returns (address) {
        return _getImplementation();
    }

    function getAdmin() external ifAdmin returns (address) {
        return _getAdmin();
    }

    // --- Fallback & Delegation ---

    fallback() external payable {
        _fallback();
    }

    receive() external payable {
        _fallback();
    }

    function _fallback() internal {
        require(msg.sender != _getAdmin(), "TransparentProxy: admin cannot call fallback");
        address impl = _getImplementation();
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), impl, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    function _getImplementation() internal view returns (address impl) {
        assembly {
            impl := sload(_IMPLEMENTATION_SLOT)
        }
    }

    function _setImplementation(address newImplementation) internal {
        require(newImplementation.code.length > 0, "Invalid implementation");
        assembly {
            sstore(_IMPLEMENTATION_SLOT, newImplementation)
        }
    }

    function _getAdmin() internal view returns (address adm) {
        assembly {
            adm := sload(_ADMIN_SLOT)
        }
    }

    function _setAdmin(address newAdmin) internal {
        assembly {
            sstore(_ADMIN_SLOT, newAdmin)
        }
    }
}
