// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/// @title CCIPCrossChainExecutor
/// @notice Chainlink CCIP (Cross-Chain Interoperability Protocol) receiver and execution contract.
contract CCIPCrossChainExecutor {
    // --- Errors ---
    error InvalidRouter();
    error SourceChainNotAllowed(uint64 chainSelector);
    error SenderNotAllowed(address sender);

    // --- Events ---
    event MessageReceived(bytes32 indexed messageId, uint64 indexed sourceChainSelector, address sender, bytes data);

    struct EVMTokenAmount {
        address token;
        uint256 amount;
    }

    struct Any2EVMMessage {
        bytes32 messageId;
        uint64 sourceChainSelector;
        bytes sender;
        bytes data;
        EVMTokenAmount[] destTokenAmounts;
    }

    address public immutable ccipRouter;
    mapping(uint64 => bool) public allowedSourceChains;
    mapping(address => bool) public allowedSenders;

    modifier onlyRouter() {
        if (msg.sender != ccipRouter) revert InvalidRouter();
        _;
    }

    constructor(address _router) {
        ccipRouter = _router;
    }

    function setSourceChainAllowed(uint64 chainSelector, bool allowed) external {
        allowedSourceChains[chainSelector] = allowed;
    }

    function setSenderAllowed(address sender, bool allowed) external {
        allowedSenders[sender] = allowed;
    }

    /// @notice CCIP router entry point when a cross-chain message is received
    function ccipReceive(Any2EVMMessage calldata message) external onlyRouter {
        if (!allowedSourceChains[message.sourceChainSelector]) {
            revert SourceChainNotAllowed(message.sourceChainSelector);
        }

        address sender = abi.decode(message.sender, (address));
        if (!allowedSenders[sender]) {
            revert SenderNotAllowed(sender);
        }

        emit MessageReceived(message.messageId, message.sourceChainSelector, sender, message.data);
    }
}
