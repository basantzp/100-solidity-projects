// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

interface IAggregatorV3 {
    function decimals() external view returns (uint8);
    function latestRoundData()
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}

/// @title ChainlinkFallbackOracle
/// @notice Resilient Chainlink price feed consumer with heartbeat validation, bounds checking, and secondary fallback.
contract ChainlinkFallbackOracle {
    // --- Errors ---
    error InvalidPrice();
    error OracleFeedStale();
    error NoViableOracle();
    error ZeroAddress();

    // --- State Variables ---
    IAggregatorV3 public immutable primaryFeed;
    IAggregatorV3 public immutable fallbackFeed;
    uint256 public immutable maxStaleness; // in seconds (e.g. 3600s = 1 hour)
    int256 public immutable minValidPrice;
    int256 public immutable maxValidPrice;

    event PriceResolved(int256 price, bool usedFallback);

    constructor(address _primary, address _fallback, uint256 _maxStaleness, int256 _minPrice, int256 _maxPrice) {
        if (_primary == address(0)) revert ZeroAddress();
        primaryFeed = IAggregatorV3(_primary);
        fallbackFeed = IAggregatorV3(_fallback);
        maxStaleness = _maxStaleness;
        minValidPrice = _minPrice;
        maxValidPrice = _maxPrice;
    }

    /// @notice Get validated price from primary feed, failing over to fallback if primary is stale or invalid
    function getLatestPrice() external returns (int256 price, uint8 decimals) {
        bool primaryValid;
        (price, primaryValid) = _tryReadFeed(primaryFeed);

        if (primaryValid) {
            decimals = primaryFeed.decimals();
            emit PriceResolved(price, false);
            return (price, decimals);
        }

        if (address(fallbackFeed) != address(0)) {
            bool fallbackValid;
            (price, fallbackValid) = _tryReadFeed(fallbackFeed);
            if (fallbackValid) {
                decimals = fallbackFeed.decimals();
                emit PriceResolved(price, true);
                return (price, decimals);
            }
        }

        revert NoViableOracle();
    }

    function _tryReadFeed(IAggregatorV3 feed) internal view returns (int256 price, bool valid) {
        try feed.latestRoundData() returns (
            uint80 roundId, int256 answer, uint256, uint256 updatedAt, uint80 answeredInRound
        ) {
            if (answer <= 0) return (0, false);
            if (answer < minValidPrice || answer > maxValidPrice) return (0, false);
            if (updatedAt == 0 || block.timestamp - updatedAt > maxStaleness) return (0, false);
            if (answeredInRound < roundId) return (0, false);

            return (answer, true);
        } catch {
            return (0, false);
        }
    }
}
