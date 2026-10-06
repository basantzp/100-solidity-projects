// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20Permit} from "./ERC20Permit.sol";

/// @title ERC4626YieldVault
/// @notice Production implementation of the EIP-4626 Tokenized Vault Standard
/// @dev Implements virtual offset pattern (+1 share, +10**offset assets) to protect against first-depositor inflation attacks
contract ERC4626YieldVault is ERC20Permit {
    /* -------------------------------------------------------------------------- */
    /*                                   EVENTS                                   */
    /* -------------------------------------------------------------------------- */
    event Deposit(address indexed sender, address indexed owner, uint256 assets, uint256 shares);
    event Withdraw(
        address indexed sender, address indexed receiver, address indexed owner, uint256 assets, uint256 shares
    );

    /* -------------------------------------------------------------------------- */
    /*                                   ERRORS                                   */
    /* -------------------------------------------------------------------------- */
    error ZeroAssets();
    error ZeroShares();
    error ExceededMaxDeposit(uint256 assets, uint256 maxAssets);
    error ExceededMaxMint(uint256 shares, uint256 maxShares);
    error ExceededMaxWithdraw(uint256 assets, uint256 maxAssets);
    error ExceededMaxRedeem(uint256 shares, uint256 maxShares);
    error TransferFailed();

    /* -------------------------------------------------------------------------- */
    /*                                    STATE                                   */
    /* -------------------------------------------------------------------------- */
    ERC20Permit public immutable asset;
    uint8 private immutable _underlyingDecimals;

    // Virtual shares and assets offset to prevent inflation attacks
    uint256 private constant VIRTUAL_SHARES = 1e3;
    uint256 private constant VIRTUAL_ASSETS = 1;

    constructor(ERC20Permit _asset, string memory _name, string memory _symbol)
        ERC20Permit(_name, _symbol, _asset.decimals())
    {
        asset = _asset;
        _underlyingDecimals = _asset.decimals();
    }

    /* -------------------------------------------------------------------------- */
    /*                               ACCOUNTING LOGIC                             */
    /* -------------------------------------------------------------------------- */

    function totalAssets() public view virtual returns (uint256) {
        return asset.balanceOf(address(this));
    }

    function convertToShares(uint256 assets) public view virtual returns (uint256) {
        return _convertToShares(assets, false);
    }

    function convertToAssets(uint256 shares) public view virtual returns (uint256) {
        return _convertToAssets(shares, false);
    }

    function _convertToShares(uint256 assets, bool roundUp) internal view virtual returns (uint256) {
        uint256 supply = totalSupply + VIRTUAL_SHARES;
        uint256 total = totalAssets() + VIRTUAL_ASSETS;

        return roundUp ? _mulDivUp(assets, supply, total) : (assets * supply) / total;
    }

    function _convertToAssets(uint256 shares, bool roundUp) internal view virtual returns (uint256) {
        uint256 supply = totalSupply + VIRTUAL_SHARES;
        uint256 total = totalAssets() + VIRTUAL_ASSETS;

        return roundUp ? _mulDivUp(shares, total, supply) : (shares * total) / supply;
    }

    /* -------------------------------------------------------------------------- */
    /*                              DEPOSIT / MINT                                */
    /* -------------------------------------------------------------------------- */

    function maxDeposit(address) public pure virtual returns (uint256) {
        return type(uint256).max;
    }

    function previewDeposit(uint256 assets) public view virtual returns (uint256) {
        return _convertToShares(assets, false);
    }

    function deposit(uint256 assets, address receiver) public virtual returns (uint256 shares) {
        if (assets == 0) revert ZeroAssets();
        shares = previewDeposit(assets);
        if (shares == 0) revert ZeroShares();

        _safeTransferFrom(address(asset), msg.sender, address(this), assets);
        _mint(receiver, shares);

        emit Deposit(msg.sender, receiver, assets, shares);
    }

    function maxMint(address) public pure virtual returns (uint256) {
        return type(uint256).max;
    }

    function previewMint(uint256 shares) public view virtual returns (uint256) {
        return _convertToAssets(shares, true);
    }

    function mint(uint256 shares, address receiver) public virtual returns (uint256 assets) {
        if (shares == 0) revert ZeroShares();
        assets = previewMint(shares);
        if (assets == 0) revert ZeroAssets();

        _safeTransferFrom(address(asset), msg.sender, address(this), assets);
        _mint(receiver, shares);

        emit Deposit(msg.sender, receiver, assets, shares);
    }

    /* -------------------------------------------------------------------------- */
    /*                             WITHDRAW / REDEEM                              */
    /* -------------------------------------------------------------------------- */

    function maxWithdraw(address owner) public view virtual returns (uint256) {
        return _convertToAssets(balanceOf[owner], false);
    }

    function previewWithdraw(uint256 assets) public view virtual returns (uint256) {
        return _convertToShares(assets, true);
    }

    function withdraw(uint256 assets, address receiver, address owner) public virtual returns (uint256 shares) {
        if (assets == 0) revert ZeroAssets();
        shares = previewWithdraw(assets);

        if (msg.sender != owner) {
            uint256 currentAllowance = allowance[owner][msg.sender];
            if (currentAllowance != type(uint256).max) {
                if (currentAllowance < shares) revert InsufficientAllowance(msg.sender, currentAllowance, shares);
                unchecked {
                    allowance[owner][msg.sender] = currentAllowance - shares;
                }
            }
        }

        _burn(owner, shares);
        _safeTransfer(address(asset), receiver, assets);

        emit Withdraw(msg.sender, receiver, owner, assets, shares);
    }

    function maxRedeem(address owner) public view virtual returns (uint256) {
        return balanceOf[owner];
    }

    function previewRedeem(uint256 shares) public view virtual returns (uint256) {
        return _convertToAssets(shares, false);
    }

    function redeem(uint256 shares, address receiver, address owner) public virtual returns (uint256 assets) {
        if (shares == 0) revert ZeroShares();

        if (msg.sender != owner) {
            uint256 currentAllowance = allowance[owner][msg.sender];
            if (currentAllowance != type(uint256).max) {
                if (currentAllowance < shares) revert InsufficientAllowance(msg.sender, currentAllowance, shares);
                unchecked {
                    allowance[owner][msg.sender] = currentAllowance - shares;
                }
            }
        }

        assets = previewRedeem(shares);
        if (assets == 0) revert ZeroAssets();

        _burn(owner, shares);
        _safeTransfer(address(asset), receiver, assets);

        emit Withdraw(msg.sender, receiver, owner, assets, shares);
    }

    /* -------------------------------------------------------------------------- */
    /*                              INTERNAL MATH                                 */
    /* -------------------------------------------------------------------------- */

    function _mulDivUp(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 z) {
        unchecked {
            z = (x * y);
            if (z / x != y && x != 0) revert("MulDiv overflow");
            z = z == 0 ? 0 : (z - 1) / denominator + 1;
        }
    }

    function _safeTransfer(address token, address to, uint256 value) private {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(ERC20Permit.transfer.selector, to, value));
        if (!success || (data.length != 0 && !abi.decode(data, (bool)))) revert TransferFailed();
    }

    function _safeTransferFrom(address token, address from, address to, uint256 value) private {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(ERC20Permit.transferFrom.selector, from, to, value));
        if (!success || (data.length != 0 && !abi.decode(data, (bool)))) revert TransferFailed();
    }
}
