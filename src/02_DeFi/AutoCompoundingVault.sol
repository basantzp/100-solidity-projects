// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/// @title AutoCompoundingVault
/// @notice Yearn-style yield vault that periodically harvests reward tokens and reinvests into principal.
contract AutoCompoundingVault {
    // --- Errors ---
    error ZeroAmount();
    error InsufficientShares();
    error TransferFailed();

    // --- Events ---
    event Deposit(address indexed user, uint256 assets, uint256 shares);
    event Withdraw(address indexed user, uint256 assets, uint256 shares);
    event Harvested(uint256 yieldCompounded);

    // --- State Variables ---
    address public immutable asset;
    uint256 public totalAssets;
    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    constructor(address _asset) {
        asset = _asset;
    }

    function deposit(uint256 amount) external returns (uint256 shares) {
        if (amount == 0) revert ZeroAmount();

        if (totalSupply == 0) {
            shares = amount;
        } else {
            shares = (amount * totalSupply) / totalAssets;
        }

        balanceOf[msg.sender] += shares;
        totalSupply += shares;
        totalAssets += amount;

        _safeTransferFrom(asset, msg.sender, address(this), amount);
        emit Deposit(msg.sender, amount, shares);
    }

    function withdraw(uint256 shares) external returns (uint256 assets) {
        if (shares == 0) revert ZeroAmount();
        if (balanceOf[msg.sender] < shares) revert InsufficientShares();

        assets = (shares * totalAssets) / totalSupply;

        balanceOf[msg.sender] -= shares;
        totalSupply -= shares;
        totalAssets -= assets;

        _safeTransfer(asset, msg.sender, assets);
        emit Withdraw(msg.sender, assets, shares);
    }

    /// @notice Keeper simulation of external yield harvest & reinvestment into the vault
    function harvestSimulatedYield(uint256 yieldAmount) external {
        if (yieldAmount == 0) revert ZeroAmount();
        _safeTransferFrom(asset, msg.sender, address(this), yieldAmount);

        // Principal increases without minting new shares -> share price increases!
        totalAssets += yieldAmount;
        emit Harvested(yieldAmount);
    }

    function getPricePerShare() external view returns (uint256) {
        if (totalSupply == 0) return 1e18;
        return (totalAssets * 1e18) / totalSupply;
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
