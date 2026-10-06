// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/// @title RageQuitTreasury
/// @notice Moloch DAO inspired minority protection mechanism enabling members to burn shares and redeem treasury assets.
contract RageQuitTreasury {
    // --- Errors ---
    error ZeroShares();
    error InsufficientShares();
    error TransferFailed();
    error Unauthorized();

    // --- State Variables ---
    address public immutable treasuryToken;
    uint256 public totalShares;

    mapping(address => uint256) public shares;

    event SharesIssued(address indexed member, uint256 sharesMinted);
    event RageQuit(address indexed member, uint256 sharesBurned, uint256 payoutReceived);

    constructor(address _treasuryToken) {
        treasuryToken = _treasuryToken;
    }

    /// @notice Member joins DAO by contributing to treasury and receiving shares
    function join(uint256 amount) external {
        if (amount == 0) revert ZeroShares();

        _safeTransferFrom(treasuryToken, msg.sender, address(this), amount);

        shares[msg.sender] += amount;
        totalShares += amount;

        emit SharesIssued(msg.sender, amount);
    }

    /// @notice Ragequit: burn shares to withdraw fair proportional slice of total treasury
    function rageQuit(uint256 sharesToBurn) external returns (uint256 payout) {
        if (sharesToBurn == 0) revert ZeroShares();
        if (shares[msg.sender] < sharesToBurn) revert InsufficientShares();

        uint256 currentBalance = _getBalance(treasuryToken);
        payout = (sharesToBurn * currentBalance) / totalShares;

        shares[msg.sender] -= sharesToBurn;
        totalShares -= sharesToBurn;

        _safeTransfer(treasuryToken, msg.sender, payout);

        emit RageQuit(msg.sender, sharesToBurn, payout);
    }

    function _getBalance(address token) internal view returns (uint256) {
        (bool success, bytes memory data) =
            token.staticcall(abi.encodeWithSignature("balanceOf(address)", address(this)));
        if (!success) revert TransferFailed();
        return abi.decode(data, (uint256));
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
