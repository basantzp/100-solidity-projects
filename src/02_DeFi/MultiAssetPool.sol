// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/// @title MultiAssetPool
/// @notice Balancer-style multi-token constant-weighted-product liquidity pool.
contract MultiAssetPool {
    // --- Errors ---
    error ArrayLengthMismatch();
    error InvalidWeights();
    error ZeroAmount();
    error InsufficientLiquidity();
    error InsufficientOutput();
    error TransferFailed();
    error TokenNotFound();

    // --- Events ---
    event LiquidityAdded(address indexed provider, uint256[] amounts, uint256 sharesMinted);
    event LiquidityRemoved(address indexed provider, uint256[] amounts, uint256 sharesBurned);
    event Swap(
        address indexed trader, address indexed tokenIn, address indexed tokenOut, uint256 amountIn, uint256 amountOut
    );

    // --- State Variables ---
    address[] public tokens;
    uint256[] public normalizedWeights; // Bps (sum = 10_000)
    mapping(address => uint256) public balances;
    mapping(address => uint256) public tokenIndex;

    uint256 public constant BPS = 10_000;
    uint256 public constant SWAP_FEE_BPS = 30; // 0.3%

    uint256 public totalShares;
    mapping(address => uint256) public sharesOf;

    constructor(address[] memory _tokens, uint256[] memory _weights) {
        if (_tokens.length != _weights.length || _tokens.length < 2) revert ArrayLengthMismatch();

        uint256 totalWeight = 0;
        for (uint256 i = 0; i < _weights.length; i++) {
            totalWeight += _weights[i];
            tokens.push(_tokens[i]);
            normalizedWeights.push(_weights[i]);
            tokenIndex[_tokens[i]] = i;
        }

        if (totalWeight != BPS) revert InvalidWeights();
    }

    function getTokensCount() external view returns (uint256) {
        return tokens.length;
    }

    /// @notice Adds liquidity proportionally across all constituent assets
    function addLiquidity(uint256[] calldata amounts, uint256 minShares) external returns (uint256 sharesMinted) {
        if (amounts.length != tokens.length) revert ArrayLengthMismatch();

        if (totalShares == 0) {
            uint256 seedProduct = 1;
            for (uint256 i = 0; i < tokens.length; i++) {
                if (amounts[i] == 0) revert ZeroAmount();
                seedProduct *= amounts[i];
                balances[tokens[i]] += amounts[i];
                _safeTransferFrom(tokens[i], msg.sender, address(this), amounts[i]);
            }
            sharesMinted = 100_000 ether; // Base initial shares
        } else {
            // Proportional deposit relative to first token
            uint256 baseRatio = (amounts[0] * 1e18) / balances[tokens[0]];
            sharesMinted = (baseRatio * totalShares) / 1e18;

            for (uint256 i = 0; i < tokens.length; i++) {
                if (amounts[i] == 0) revert ZeroAmount();
                balances[tokens[i]] += amounts[i];
                _safeTransferFrom(tokens[i], msg.sender, address(this), amounts[i]);
            }
        }

        if (sharesMinted < minShares) revert InsufficientOutput();

        sharesOf[msg.sender] += sharesMinted;
        totalShares += sharesMinted;

        emit LiquidityAdded(msg.sender, amounts, sharesMinted);
    }

    /// @notice Withdraws liquidity proportionally across all constituent assets
    function removeLiquidity(uint256 shares, uint256[] calldata minAmountsOut)
        external
        returns (uint256[] memory amountsOut)
    {
        if (shares == 0 || sharesOf[msg.sender] < shares) revert InsufficientLiquidity();
        if (minAmountsOut.length != tokens.length) revert ArrayLengthMismatch();

        amountsOut = new uint256[](tokens.length);

        sharesOf[msg.sender] -= shares;
        totalShares -= shares;

        for (uint256 i = 0; i < tokens.length; i++) {
            uint256 tokenAmount = (balances[tokens[i]] * shares) / (totalShares + shares);
            if (tokenAmount < minAmountsOut[i]) revert InsufficientOutput();

            balances[tokens[i]] -= tokenAmount;
            amountsOut[i] = tokenAmount;
            _safeTransfer(tokens[i], msg.sender, tokenAmount);
        }

        emit LiquidityRemoved(msg.sender, amountsOut, shares);
    }

    /// @notice Swaps tokenIn for tokenOut using constant-weight ratio formula
    function swap(address tokenIn, address tokenOut, uint256 amountIn, uint256 minAmountOut)
        external
        returns (uint256 amountOut)
    {
        if (amountIn == 0) revert ZeroAmount();
        if (tokenIn == tokenOut) revert TokenNotFound();

        uint256 bIn = balances[tokenIn];
        uint256 bOut = balances[tokenOut];
        if (bIn == 0 || bOut == 0) revert InsufficientLiquidity();

        uint256 idxIn = tokenIndex[tokenIn];
        uint256 idxOut = tokenIndex[tokenOut];
        uint256 wIn = normalizedWeights[idxIn];
        uint256 wOut = normalizedWeights[idxOut];

        uint256 netIn = (amountIn * (BPS - SWAP_FEE_BPS)) / BPS;

        // Balancer out-given-in: amountOut = bOut * (1 - (bIn / (bIn + netIn))^(wIn / wOut))
        // Linearized / constant-product generalized approximation:
        amountOut = (bOut * netIn * wIn) / ((bIn * wOut) + (netIn * wIn));

        if (amountOut < minAmountOut || amountOut >= bOut) revert InsufficientOutput();

        balances[tokenIn] += amountIn;
        balances[tokenOut] -= amountOut;

        _safeTransferFrom(tokenIn, msg.sender, address(this), amountIn);
        _safeTransfer(tokenOut, msg.sender, amountOut);

        emit Swap(msg.sender, tokenIn, tokenOut, amountIn, amountOut);
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
