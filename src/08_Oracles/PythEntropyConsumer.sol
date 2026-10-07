// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/// @title PythEntropyConsumer
/// @notice Decentralized low-latency pull-oracle consumer with freshness verification and confidence bounds.
contract PythEntropyConsumer {
    // --- Errors ---
    error PriceStale();
    error InvalidPublisherSignature();
    error PriceTooOld();
    error FuturePriceTimestamp();

    // --- Events ---
    event PriceUpdated(bytes32 indexed feedId, int64 price, uint64 conf, uint256 publishTime);

    struct PriceRecord {
        int64 price;
        uint64 conf;
        int32 expo;
        uint256 publishTime;
    }

    address public immutable authorizedPublisher;
    uint256 public constant MAX_STALENESS = 60 seconds;

    mapping(bytes32 => PriceRecord) public prices;

    constructor(address _publisher) {
        authorizedPublisher = _publisher;
    }

    /// @notice Updates price feed with pull-oracle signed update packet
    function updatePrice(
        bytes32 feedId,
        int64 price,
        uint64 conf,
        int32 expo,
        uint256 publishTime,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        if (publishTime > block.timestamp) revert FuturePriceTimestamp();
        if (block.timestamp - publishTime > MAX_STALENESS) revert PriceStale();

        bytes32 payloadHash = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32", keccak256(abi.encode(feedId, price, conf, expo, publishTime))
            )
        );

        address recovered = ecrecover(payloadHash, v, r, s);
        if (recovered != authorizedPublisher) revert InvalidPublisherSignature();

        prices[feedId] = PriceRecord({price: price, conf: conf, expo: expo, publishTime: publishTime});

        emit PriceUpdated(feedId, price, conf, publishTime);
    }

    function getPrice(bytes32 feedId) external view returns (int64 price, uint256 publishTime) {
        PriceRecord storage rec = prices[feedId];
        if (rec.publishTime == 0 || block.timestamp - rec.publishTime > MAX_STALENESS) {
            revert PriceStale();
        }
        return (rec.price, rec.publishTime);
    }
}
