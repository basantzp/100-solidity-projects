// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {UserOperation} from "./ModularSmartAccount.sol";

/// @title VerifyingPaymaster
/// @notice ERC-4337 gas sponsorship paymaster verifying off-chain backend signatures to sponsor transaction fees.
contract VerifyingPaymaster {
    // --- Errors ---
    error OnlyEntryPoint();
    error Unauthorized();
    error InvalidPaymasterDataLength();
    error SignatureExpired();
    error SignatureNotValidYet();
    error InvalidSignature();
    error TransferFailed();

    // --- State Variables ---
    address public immutable entryPoint;
    address public verifyingSigner;
    address public owner;

    modifier onlyEntryPoint() {
        if (msg.sender != entryPoint) revert OnlyEntryPoint();
        _;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) revert Unauthorized();
        _;
    }

    constructor(address _entryPoint, address _verifyingSigner) {
        entryPoint = _entryPoint;
        verifyingSigner = _verifyingSigner;
        owner = msg.sender;
    }

    receive() external payable {}

    function setVerifyingSigner(address newSigner) external onlyOwner {
        verifyingSigner = newSigner;
    }

    /// @notice Validate paymaster sponsorship in ERC-4337 workflow
    function validatePaymasterUserOp(UserOperation calldata userOp, bytes32 userOpHash, uint256 maxCost)
        external
        view
        onlyEntryPoint
        returns (bytes memory context, uint256 validationData)
    {
        // userOp.paymasterAndData format:
        // [0..20: paymaster address] [20..26: validUntil (6 bytes)] [26..32: validAfter (6 bytes)] [32..97: signature (65 bytes)]
        if (userOp.paymasterAndData.length < 97) revert InvalidPaymasterDataLength();

        uint48 validUntil = uint48(bytes6(userOp.paymasterAndData[20:26]));
        uint48 validAfter = uint48(bytes6(userOp.paymasterAndData[26:32]));
        bytes calldata sig = userOp.paymasterAndData[32:97];

        bytes32 hash = getHash(userOpHash, validUntil, validAfter);
        address recovered = _recover(hash, sig);

        if (recovered != verifyingSigner) {
            return ("", 1); // SIG_VALIDATION_FAILED
        }

        // Return packed validationData: [validUntil (48 bits)] [validAfter (48 bits)] [0 (success)]
        validationData = (uint256(validUntil) << 160) | (uint256(validAfter) << 208);
        context = abi.encode(userOp.sender, maxCost);
    }

    function getHash(bytes32 userOpHash, uint48 validUntil, uint48 validAfter) public view returns (bytes32) {
        return keccak256(abi.encode(userOpHash, validUntil, validAfter, block.chainid, address(this)));
    }

    function _recover(bytes32 hash, bytes calldata signature) internal pure returns (address) {
        if (signature.length != 65) return address(0);

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            r := calldataload(signature.offset)
            s := calldataload(add(signature.offset, 32))
            v := byte(0, calldataload(add(signature.offset, 64)))
        }

        bytes32 ethHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
        return ecrecover(ethHash, v, r, s);
    }
}
