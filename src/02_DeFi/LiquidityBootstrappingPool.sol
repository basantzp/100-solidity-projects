// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/// @title LiquidityBootstrappingPool (LBP)
/// @notice Balancer-style dynamic weight-shifting pool for fair-launch token auctions with anti-bot price curves.
contract LiquidityBootstrappingPool {
    // --- Errors ---
    error ZeroAmount();
    error SaleNotActive();
    error SaleAlreadyEnded();
    error InsufficientOutput();
    error TransferFailed();
    error Unauthorized();

    // --- State Variables ---
    address public immutable projectToken;
    address public immutable collateralToken;
    address public immutable owner;

    uint256 public immutable startTime;
    uint256 public immutable endTime;

    uint256 public immutable startWeightProject; // e.g. 90 (90%)
    uint256 public immutable endWeightProject; // e.g. 50 (50%)

    uint256 public reserveProject;
    uint256 public reserveCollateral;

    event Swap(address indexed buyer, uint256 collateralIn, uint256 projectTokenOut);

    constructor(
        address _projectToken,
        address _collateralToken,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _startWeightProject,
        uint256 _endWeightProject,
        uint256 _initialProject,
        uint256 _initialCollateral
    ) {
        owner = msg.sender;
        projectToken = _projectToken;
        collateralToken = _collateralToken;
        startTime = _startTime;
        endTime = _endTime;
        startWeightProject = _startWeightProject;
        endWeightProject = _endWeightProject;
        reserveProject = _initialProject;
        reserveCollateral = _initialCollateral;
    }

    /// @notice Interpolate current project token weight (e.g. descending from 90% to 50%)
    function getWeights() public view returns (uint256 weightProject, uint256 weightCollateral) {
        if (block.timestamp <= startTime) {
            weightProject = startWeightProject;
        } else if (block.timestamp >= endTime) {
            weightProject = endWeightProject;
        } else {
            uint256 elapsed = block.timestamp - startTime;
            uint256 duration = endTime - startTime;
            uint256 delta = startWeightProject - endWeightProject;
            weightProject = startWeightProject - (delta * elapsed) / duration;
        }
        weightCollateral = 100 - weightProject;
    }

    /// @notice Swap collateral for project tokens
    function swapCollateralForProject(uint256 collateralIn, uint256 minProjectOut)
        external
        returns (uint256 projectOut)
    {
        if (block.timestamp < startTime) revert SaleNotActive();
        if (block.timestamp > endTime) revert SaleAlreadyEnded();
        if (collateralIn == 0) revert ZeroAmount();

        (uint256 wProj, uint256 wCol) = getWeights();

        // Dy = y * (1 - (x / (x + Dx))^(wCol / wProj))
        // Linearized approximation for high liquidity:
        // projectOut = (reserveProject * collateralIn * wCol) / (reserveCollateral * wProj + collateralIn * wCol)
        uint256 num = reserveProject * collateralIn * wCol;
        uint256 den = (reserveCollateral * wProj) + (collateralIn * wCol);
        projectOut = num / den;

        if (projectOut < minProjectOut) revert InsufficientOutput();

        reserveCollateral += collateralIn;
        reserveProject -= projectOut;

        _safeTransferFrom(collateralToken, msg.sender, address(this), collateralIn);
        _safeTransfer(projectToken, msg.sender, projectOut);

        emit Swap(msg.sender, collateralIn, projectOut);
    }

    /// @notice Current spot price of project token in units of collateral
    function getSpotPrice() external view returns (uint256) {
        (uint256 wProj, uint256 wCol) = getWeights();
        // Price = (reserveCollateral / wCol) / (reserveProject / wProj)
        return (reserveCollateral * wProj * 1e18) / (reserveProject * wCol);
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
