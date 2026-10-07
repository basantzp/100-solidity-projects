// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/// @title LayerZeroMessagingApp
/// @notice Omnichain arbitrary message passing endpoint application (LayerZero OApp standard pattern).
contract LayerZeroMessagingApp {
    // --- Errors ---
    error UnauthorizedEndpoint();
    error InvalidSender();
    error InsufficientFee();

    // --- Events ---
    event MessageSent(uint32 indexed dstEid, bytes32 indexed receiver, bytes message, uint64 nonce);
    event MessageReceived(uint32 indexed srcEid, bytes32 indexed sender, uint64 nonce, bytes payload);

    address public immutable endpoint;
    uint64 public outboundNonce;

    // srcEid => sender => trusted
    mapping(uint32 => mapping(bytes32 => bool)) public trustedRemotes;
    // srcEid => nonce => processed
    mapping(uint32 => mapping(uint64 => bool)) public processedNonces;

    modifier onlyEndpoint() {
        if (msg.sender != endpoint) revert UnauthorizedEndpoint();
        _;
    }

    constructor(address _endpoint) {
        endpoint = _endpoint;
    }

    function setTrustedRemote(uint32 eid, bytes32 remote, bool trusted) external {
        trustedRemotes[eid][remote] = trusted;
    }

    /// @notice Sends an omnichain message across endpoints
    function send(uint32 dstEid, bytes32 receiver, bytes calldata message) external payable returns (uint64 nonce) {
        nonce = ++outboundNonce;
        emit MessageSent(dstEid, receiver, message, nonce);
    }

    /// @notice Endpoint invokes this callback when message arrives
    function lzReceive(uint32 srcEid, bytes32 sender, uint64 nonce, bytes calldata payload) external onlyEndpoint {
        if (!trustedRemotes[srcEid][sender]) revert InvalidSender();
        require(!processedNonces[srcEid][nonce], "Message already processed");

        processedNonces[srcEid][nonce] = true;
        emit MessageReceived(srcEid, sender, nonce, payload);
    }
}
