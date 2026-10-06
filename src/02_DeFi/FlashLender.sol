// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20Permit} from "../01_Tokens/ERC20Permit.sol";

interface IERC3156FlashBorrower {
    function onFlashLoan(address initiator, address token, uint256 amount, uint256 fee, bytes calldata data)
        external
        returns (bytes32);
}

/// @title FlashLender
/// @notice ERC-3156 compliant uncollateralized flash loan provider
contract FlashLender {
    bytes32 public constant CALLBACK_SUCCESS = keccak256("ERC3156FlashBorrower.onFlashLoan");

    error UnsupportedToken(address token);
    error ExceedsMaxLoan(uint256 amount, uint256 maxLoan);
    error CallbackFailed();
    error RepaymentFailed();

    // Fee basis points: 9 bips (0.09%)
    uint256 public constant FEE_BPS = 9;
    mapping(address => bool) public supportedTokens;

    constructor(address[] memory _tokens) {
        for (uint256 i = 0; i < _tokens.length; i++) {
            supportedTokens[_tokens[i]] = true;
        }
    }

    function maxFlashLoan(address token) external view returns (uint256) {
        if (!supportedTokens[token]) return 0;
        return _balanceOf(token);
    }

    function flashFee(address token, uint256 amount) public view returns (uint256) {
        if (!supportedTokens[token]) revert UnsupportedToken(token);
        return (amount * FEE_BPS) / 10000;
    }

    function flashLoan(IERC3156FlashBorrower receiver, address token, uint256 amount, bytes calldata data)
        external
        returns (bool)
    {
        if (!supportedTokens[token]) revert UnsupportedToken(token);
        uint256 currentBalance = _balanceOf(token);
        if (amount > currentBalance) revert ExceedsMaxLoan(amount, currentBalance);

        uint256 fee = flashFee(token, amount);

        // 1. Transfer loan amount to receiver
        _safeTransfer(token, address(receiver), amount);

        // 2. Invoke borrower callback
        if (receiver.onFlashLoan(msg.sender, token, amount, fee, data) != CALLBACK_SUCCESS) {
            revert CallbackFailed();
        }

        // 3. Pull principal + fee from receiver
        _safeTransferFrom(token, address(receiver), address(this), amount + fee);

        return true;
    }

    function _safeTransfer(address token, address to, uint256 value) private {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(ERC20Permit.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "Transfer failed");
    }

    function _safeTransferFrom(address token, address from, address to, uint256 value) private {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(ERC20Permit.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferFrom failed");
    }

    function _balanceOf(address token) private view returns (uint256) {
        (bool success, bytes memory data) =
            token.staticcall(abi.encodeWithSignature("balanceOf(address)", address(this)));
        require(success && data.length >= 32, "balanceOf failed");
        return abi.decode(data, (uint256));
    }
}
