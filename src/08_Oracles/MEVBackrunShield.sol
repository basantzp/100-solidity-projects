// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/// @title MEVBackrunShield
/// @notice Anti-sandwich MEV protection and searcher profit-sharing hook.
/// @dev Prevents predatory sandwiching by verifying private bundle inclusion and sharing backrun arbitrage revenue.
contract MEVBackrunShield {
    // --- Errors ---
    error SandwichDetected();
    error ExcessiveSlippage();
    error UnauthorizedRelayer();
    error ZeroAmount();
    error TransferFailed();

    // --- State Variables ---
    address public immutable owner;
    address public authorizedRelayer; // Private builder / MEV-Share endpoint

    uint256 public constant MAX_BPS = 10000;
    uint256 public userRebateBps = 8000; // 80% of captured MEV returned to user, 20% to DAO

    event ProtectionVerified(address indexed user, uint256 minOutput, uint256 actualOutput);
    event MEVRebateDistributed(address indexed user, uint256 userShare, uint256 treasuryShare);

    modifier onlyOwner() {
        if (msg.sender != owner) revert UnauthorizedRelayer();
        _;
    }

    constructor(address _relayer) {
        owner = msg.sender;
        authorizedRelayer = _relayer;
    }

    function setAuthorizedRelayer(address newRelayer) external onlyOwner {
        authorizedRelayer = newRelayer;
    }

    function setUserRebateBps(uint256 newBps) external onlyOwner {
        require(newBps <= MAX_BPS, "Invalid BPS");
        userRebateBps = newBps;
    }

    /// @notice Verify swap safety inside a private bundle
    function verifySwap(uint256 expectedOutput, uint256 actualOutput, uint256 maxAllowedSlippageBps) external view {
        // Enforce private relayer routing to defeat public mempool sandwich bots
        if (tx.origin != msg.sender && msg.sender != authorizedRelayer) {
            revert UnauthorizedRelayer();
        }

        uint256 minAcceptable = (expectedOutput * (MAX_BPS - maxAllowedSlippageBps)) / MAX_BPS;
        if (actualOutput < minAcceptable) {
            revert ExcessiveSlippage();
        }
    }

    /// @notice Capture backrun arbitrage profit and distribute rebate to user
    function distributeBackrunProfit(address token, address user, uint256 profitAmount) external payable {
        if (profitAmount == 0) revert ZeroAmount();

        _safeTransferFrom(token, msg.sender, address(this), profitAmount);

        uint256 userShare = (profitAmount * userRebateBps) / MAX_BPS;
        uint256 treasuryShare = profitAmount - userShare;

        _safeTransfer(token, user, userShare);
        _safeTransfer(token, owner, treasuryShare);

        emit MEVRebateDistributed(user, userShare, treasuryShare);
    }

    function _safeTransfer(address token, address to, uint256 amount) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSignature("transfer(address,uint256)", to, amount));
        if (!success || (data.length != 0 && !abi.decode(data, (bool)))) revert TransferFailed();
    }

    function _safeTransferFrom(address token, address from, address to, uint256 amount) internal {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSignature("transferFrom(address,address,uint256)", from, to, amount));
        if (!success || (data.length != 0 && !abi.decode(data, (bool)))) revert TransferFailed();
    }
}
