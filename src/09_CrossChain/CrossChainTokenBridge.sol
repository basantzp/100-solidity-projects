// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/// @title CrossChainTokenBridge
/// @notice Lock-and-mint / burn-and-mint cross-chain asset bridge with replay-protected validator attestations.
contract CrossChainTokenBridge {
    // --- Errors ---
    error ZeroAmount();
    error AlreadyProcessed();
    error Unauthorized();
    error TransferFailed();
    error ZeroAddress();

    // --- State Variables ---
    address public immutable token;
    address public validator;
    uint256 public immutable currentChainId;

    mapping(bytes32 => bool) public processedTransfers;

    // --- Events ---
    event TokensLocked(
        address indexed sender, address indexed recipient, uint256 amount, uint256 destinationChainId, uint256 nonce
    );
    event TokensBurned(
        address indexed sender, address indexed recipient, uint256 amount, uint256 destinationChainId, uint256 nonce
    );
    event TokensUnlocked(address indexed recipient, uint256 amount, bytes32 indexed transferId);
    event TokensMinted(address indexed recipient, uint256 amount, bytes32 indexed transferId);

    modifier onlyValidator() {
        if (msg.sender != validator) revert Unauthorized();
        _;
    }

    constructor(address _token, address _validator) {
        if (_token == address(0) || _validator == address(0)) revert ZeroAddress();
        token = _token;
        validator = _validator;
        currentChainId = block.chainid;
    }

    /// @notice Lock local tokens on source chain to bridge out
    function bridgeLock(address recipient, uint256 amount, uint256 destinationChainId, uint256 nonce) external {
        if (amount == 0) revert ZeroAmount();
        if (recipient == address(0)) revert ZeroAddress();

        bytes32 transferId =
            keccak256(abi.encode(msg.sender, recipient, amount, currentChainId, destinationChainId, nonce));
        if (processedTransfers[transferId]) revert AlreadyProcessed();
        processedTransfers[transferId] = true;

        _safeTransferFrom(token, msg.sender, address(this), amount);

        emit TokensLocked(msg.sender, recipient, amount, destinationChainId, nonce);
    }

    /// @notice Validator releases locked tokens on source chain upon incoming burn attestation
    function releaseUnlockedTokens(address recipient, uint256 amount, uint256 sourceChainId, uint256 nonce)
        external
        onlyValidator
    {
        bytes32 transferId = keccak256(abi.encode(recipient, amount, sourceChainId, currentChainId, nonce));
        if (processedTransfers[transferId]) revert AlreadyProcessed();
        processedTransfers[transferId] = true;

        _safeTransfer(token, recipient, amount);

        emit TokensUnlocked(recipient, amount, transferId);
    }

    /// @notice Burn wrapped tokens to bridge back to native chain
    function bridgeBurn(address recipient, uint256 amount, uint256 destinationChainId, uint256 nonce) external {
        if (amount == 0) revert ZeroAmount();
        if (recipient == address(0)) revert ZeroAddress();

        bytes32 transferId =
            keccak256(abi.encode(msg.sender, recipient, amount, currentChainId, destinationChainId, nonce));
        if (processedTransfers[transferId]) revert AlreadyProcessed();
        processedTransfers[transferId] = true;

        _burn(msg.sender, amount);

        emit TokensBurned(msg.sender, recipient, amount, destinationChainId, nonce);
    }

    /// @notice Validator mints wrapped tokens upon incoming lock attestation
    function mintBridgedTokens(address recipient, uint256 amount, uint256 sourceChainId, uint256 nonce)
        external
        onlyValidator
    {
        bytes32 transferId = keccak256(abi.encode(recipient, amount, sourceChainId, currentChainId, nonce));
        if (processedTransfers[transferId]) revert AlreadyProcessed();
        processedTransfers[transferId] = true;

        _mint(recipient, amount);

        emit TokensMinted(recipient, amount, transferId);
    }

    function _safeTransfer(address _t, address to, uint256 amount) internal {
        (bool success, bytes memory data) = _t.call(abi.encodeWithSignature("transfer(address,uint256)", to, amount));
        if (!success || (data.length != 0 && !abi.decode(data, (bool)))) revert TransferFailed();
    }

    function _safeTransferFrom(address _t, address from, address to, uint256 amount) internal {
        (bool success, bytes memory data) =
            _t.call(abi.encodeWithSignature("transferFrom(address,address,uint256)", from, to, amount));
        if (!success || (data.length != 0 && !abi.decode(data, (bool)))) revert TransferFailed();
    }

    function _mint(address to, uint256 amount) internal {
        (bool success,) = token.call(abi.encodeWithSignature("mint(address,uint256)", to, amount));
        if (!success) revert TransferFailed();
    }

    function _burn(address from, uint256 amount) internal {
        (bool success,) = token.call(abi.encodeWithSignature("burn(address,uint256)", from, amount));
        if (!success) revert TransferFailed();
    }
}
