// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/// @title VerifiableRandomFunction
/// @notice On-chain VRF consumer and verification coordinator for tamper-proof randomness.
contract VerifiableRandomFunction {
    // --- Errors ---
    error RequestAlreadyFulfilled();
    error RequestNotFound();
    error InvalidProofSignature();
    error UnauthorizedCoordinator();

    // --- Events ---
    event RandomnessRequested(uint256 indexed requestId, address indexed caller, uint256 seed);
    event RandomnessFulfilled(uint256 indexed requestId, uint256 randomWord);

    struct RandomnessRequest {
        address requester;
        uint256 seed;
        uint256 blockNumber;
        bool fulfilled;
        uint256 randomWord;
    }

    address public immutable coordinatorSigner;
    uint256 public nextRequestId = 1;

    mapping(uint256 => RandomnessRequest) public requests;

    constructor(address _coordinatorSigner) {
        coordinatorSigner = _coordinatorSigner;
    }

    /// @notice Requests verifiable random word
    function requestRandomness(uint256 seed) external returns (uint256 requestId) {
        requestId = nextRequestId++;
        requests[requestId] = RandomnessRequest({
            requester: msg.sender, seed: seed, blockNumber: block.number, fulfilled: false, randomWord: 0
        });

        emit RandomnessRequested(requestId, msg.sender, seed);
    }

    /// @notice Coordinator fulfills the randomness request with signed randomness proof
    function fulfillRandomness(uint256 requestId, uint256 randomWord, uint8 v, bytes32 r, bytes32 s) external {
        RandomnessRequest storage req = requests[requestId];
        if (req.requester == address(0)) revert RequestNotFound();
        if (req.fulfilled) revert RequestAlreadyFulfilled();

        // Verify ECDSA proof of randomness generation over (requestId, seed, randomWord)
        bytes32 proofHash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", keccak256(abi.encode(requestId, req.seed, randomWord)))
        );

        address recovered = ecrecover(proofHash, v, r, s);
        if (recovered != coordinatorSigner) revert InvalidProofSignature();

        req.fulfilled = true;
        req.randomWord = randomWord;

        emit RandomnessFulfilled(requestId, randomWord);
    }

    function getRandomWord(uint256 requestId) external view returns (uint256) {
        RandomnessRequest storage req = requests[requestId];
        if (!req.fulfilled) revert RequestNotFound();
        return req.randomWord;
    }
}
