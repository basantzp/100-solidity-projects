// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/// @title TWAPOracle
/// @notice Manipulation-resistant Time-Weighted Average Price (TWAP) cumulative observation oracle.
/// @dev Accumulates price * time delta to immunize against single-block flash loan exploits.
contract TWAPOracle {
    // --- Errors ---
    error PeriodNotElapsed();
    error InsufficientObservations();
    error ZeroPrice();

    // --- Structs ---
    struct Observation {
        uint32 timestamp;
        uint224 priceCumulative;
    }

    // --- State Variables ---
    uint32 public immutable windowPeriod; // e.g. 1800 seconds (30 minutes)
    Observation[] public observations;

    event PriceUpdated(uint32 timestamp, uint224 currentPrice, uint224 priceCumulative);

    constructor(uint32 _windowPeriod, uint224 initialPrice) {
        if (initialPrice == 0) revert ZeroPrice();
        windowPeriod = _windowPeriod;

        observations.push(Observation({timestamp: uint32(block.timestamp), priceCumulative: 0}));
    }

    /// @notice Update oracle with latest spot price observation
    function update(uint224 spotPrice) external {
        if (spotPrice == 0) revert ZeroPrice();

        Observation memory last = observations[observations.length - 1];
        uint32 timeElapsed = uint32(block.timestamp) - last.timestamp;
        if (timeElapsed == 0) revert PeriodNotElapsed();

        uint224 newCumulative = last.priceCumulative + (spotPrice * timeElapsed);

        observations.push(Observation({timestamp: uint32(block.timestamp), priceCumulative: newCumulative}));

        emit PriceUpdated(uint32(block.timestamp), spotPrice, newCumulative);
    }

    /// @notice Consult TWAP over the specified window period
    function consult() external view returns (uint224 twapPrice) {
        uint256 len = observations.length;
        if (len < 2) revert InsufficientObservations();

        Observation memory latest = observations[len - 1];
        uint32 targetTimestamp = latest.timestamp - windowPeriod;

        // Find the observation closest to targetTimestamp using binary search
        Observation memory oldest = _findEarliestObservation(targetTimestamp);

        uint32 timeDelta = latest.timestamp - oldest.timestamp;
        if (timeDelta == 0) revert PeriodNotElapsed();

        twapPrice = (latest.priceCumulative - oldest.priceCumulative) / timeDelta;
    }

    function _findEarliestObservation(uint32 targetTimestamp) internal view returns (Observation memory) {
        uint256 low = 0;
        uint256 high = observations.length - 1;

        while (low < high) {
            uint256 mid = (low + high) / 2;
            if (observations[mid].timestamp >= targetTimestamp) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }
        return observations[low];
    }
}
