// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/// @notice ERC-4337 UserOperation representation
struct UserOperation {
    address sender;
    uint256 nonce;
    bytes initCode;
    bytes callData;
    uint256 callGasLimit;
    uint256 verificationGasLimit;
    uint256 preVerificationGas;
    uint256 maxFeePerGas;
    uint256 maxPriorityFeePerGas;
    bytes paymasterAndData;
    bytes signature;
}

/// @title ModularSmartAccount
/// @notice ERC-4337 compliant smart contract wallet with signature validation and execution.
contract ModularSmartAccount {
    // --- Errors ---
    error OnlyEntryPoint();
    error OnlyOwnerOrEntryPoint();
    error ExecutionFailed();
    error ZeroAddress();

    // --- Constants ---
    uint256 internal constant SIG_VALIDATION_SUCCESS = 0;
    uint256 internal constant SIG_VALIDATION_FAILED = 1;

    // --- State Variables ---
    address public immutable entryPoint;
    address public owner;

    event Executed(address indexed target, uint256 value, bytes data);

    modifier onlyEntryPoint() {
        if (msg.sender != entryPoint) revert OnlyEntryPoint();
        _;
    }

    modifier onlyOwnerOrEntryPoint() {
        if (msg.sender != owner && msg.sender != entryPoint) revert OnlyOwnerOrEntryPoint();
        _;
    }

    constructor(address _entryPoint, address _owner) payable {
        if (_entryPoint == address(0) || _owner == address(0)) revert ZeroAddress();
        entryPoint = _entryPoint;
        owner = _owner;
    }

    receive() external payable {}

    /// @notice ERC-4337 validation entrypoint
    function validateUserOp(UserOperation calldata userOp, bytes32 userOpHash, uint256 missingAccountFunds)
        external
        onlyEntryPoint
        returns (uint256 validationData)
    {
        address signer = _recoverSigner(userOpHash, userOp.signature);
        if (signer != owner) {
            return SIG_VALIDATION_FAILED;
        }

        if (missingAccountFunds > 0) {
            (bool success,) = payable(entryPoint).call{value: missingAccountFunds}("");
            require(success, "Prefund failed");
        }

        return SIG_VALIDATION_SUCCESS;
    }

    /// @notice Execution dispatched via EntryPoint or owner directly
    function execute(address dest, uint256 value, bytes calldata func)
        external
        onlyOwnerOrEntryPoint
        returns (bytes memory result)
    {
        bool success;
        (success, result) = dest.call{value: value}(func);
        if (!success) revert ExecutionFailed();

        emit Executed(dest, value, func);
    }

    function _recoverSigner(bytes32 hash, bytes calldata signature) internal pure returns (address) {
        if (signature.length != 65) return address(0);

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            r := calldataload(signature.offset)
            s := calldataload(add(signature.offset, 32))
            v := byte(0, calldataload(add(signature.offset, 64)))
        }

        // Malleability guard
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return address(0);
        }

        bytes32 ethHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
        return ecrecover(ethHash, v, r, s);
    }
}
