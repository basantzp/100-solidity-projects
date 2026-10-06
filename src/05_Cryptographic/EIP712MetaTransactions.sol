// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/// @title EIP712MetaTransactions
/// @notice EIP-712 structured data meta-transaction forwarder enabling gasless user interactions.
contract EIP712MetaTransactions {
    // --- Errors ---
    error InvalidSignature();
    error InvalidNonce();
    error ForwardCallFailed();

    // --- Structs ---
    struct ForwardRequest {
        address from;
        address to;
        uint256 value;
        uint256 gas;
        uint256 nonce;
        bytes data;
    }

    // --- Constants ---
    bytes32 public constant TYPE_HASH =
        keccak256("ForwardRequest(address from,address to,uint256 value,uint256 gas,uint256 nonce,bytes data)");

    // --- State Variables ---
    bytes32 public immutable DOMAIN_SEPARATOR;
    mapping(address => uint256) public nonces;

    event MetaTransactionExecuted(address indexed from, address indexed to, uint256 indexed nonce);

    constructor(string memory name, string memory version) {
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(name)),
                keccak256(bytes(version)),
                block.chainid,
                address(this)
            )
        );
    }

    /// @notice Verify structured EIP-712 signature for a ForwardRequest
    function verify(ForwardRequest calldata req, bytes calldata signature) public view returns (bool) {
        bytes32 structHash =
            keccak256(abi.encode(TYPE_HASH, req.from, req.to, req.value, req.gas, req.nonce, keccak256(req.data)));

        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, structHash));
        address signer = _recover(digest, signature);

        return signer == req.from;
    }

    /// @notice Execute meta-transaction forwarded by a relayer
    function execute(ForwardRequest calldata req, bytes calldata signature)
        external
        payable
        returns (bool success, bytes memory returnData)
    {
        if (req.nonce != nonces[req.from]) revert InvalidNonce();
        if (!verify(req, signature)) revert InvalidSignature();

        nonces[req.from] += 1;

        // Append req.from to calldata for ERC-2771 context resolution
        bytes memory callPayload = abi.encodePacked(req.data, req.from);

        (success, returnData) = req.to.call{gas: req.gas, value: req.value}(callPayload);
        if (!success) revert ForwardCallFailed();

        emit MetaTransactionExecuted(req.from, req.to, req.nonce);
    }

    function _recover(bytes32 digest, bytes calldata signature) internal pure returns (address) {
        if (signature.length != 65) return address(0);

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            r := calldataload(signature.offset)
            s := calldataload(add(signature.offset, 32))
            v := byte(0, calldataload(add(signature.offset, 64)))
        }

        // Enforce malleability safety: s <= secp256k1n / 2
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return address(0);
        }

        if (v != 27 && v != 28) return address(0);

        return ecrecover(digest, v, r, s);
    }
}
