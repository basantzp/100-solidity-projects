// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/// @title StableSwapAMM
/// @notice 2-token Curve Stableswap invariant AMM with amplification coefficient (A).
/// @dev Implements Newton-Raphson approximation for invariant D and output y.
contract StableSwapAMM {
    // --- Errors ---
    error ZeroAmount();
    error InvariantConvergenceFailed();
    error InsufficientOutput();
    error TransferFailed();

    // --- State Variables ---
    address public immutable token0;
    address public immutable token1;

    uint256 public immutable A; // Amplification coefficient
    uint256 public reserve0;
    uint256 public reserve1;
    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    event AddLiquidity(address indexed provider, uint256 amount0, uint256 amount1, uint256 shares);
    event RemoveLiquidity(address indexed provider, uint256 amount0, uint256 amount1, uint256 shares);
    event TokenExchange(address indexed buyer, uint256 sold0, uint256 bought1);

    constructor(address _token0, address _token1, uint256 _A) {
        token0 = _token0;
        token1 = _token1;
        A = _A;
    }

    /// @notice Compute the StableSwap invariant D given reserves (x, y)
    /// @dev Invariant for n=2: 4A(x + y) + D = 4AD + D^3 / (4xy)
    function getD(uint256 x, uint256 y) public view returns (uint256) {
        if (x == 0 && y == 0) return 0;

        uint256 sum = x + y;
        uint256 D = sum;
        uint256 Ann = A * 4;

        for (uint256 i = 0; i < 255; i++) {
            // D_P = D * D * D / (4 * x * y)
            uint256 D_P = (((D * D) / (4 * x)) * D) / y;
            uint256 prevD = D;

            // Numerator: (Ann * sum + 2 * D_P) * D
            // Denominator: (Ann - 1) * D + 3 * D_P
            uint256 num = (Ann * sum + 2 * D_P) * D;
            uint256 den = (Ann - 1) * D + 3 * D_P;
            D = num / den;

            if (D > prevD ? D - prevD <= 1 : prevD - D <= 1) {
                return D;
            }
        }
        revert InvariantConvergenceFailed();
    }

    /// @notice Compute reserve y given new reserve x and target invariant D
    function getY(uint256 x, uint256 D) public view returns (uint256) {
        uint256 Ann = A * 4;
        // c = D^3 / (4 * Ann * x)
        uint256 c = (((D * D) / (4 * x)) * D) / Ann;
        // b = x + D / Ann
        uint256 b = x + D / Ann;
        uint256 y = D;

        for (uint256 i = 0; i < 255; i++) {
            uint256 prevY = y;
            // y = (y^2 + c) / (2y + b - D)
            y = (y * y + c) / (2 * y + b - D);

            if (y > prevY ? y - prevY <= 1 : prevY - y <= 1) {
                return y;
            }
        }
        revert InvariantConvergenceFailed();
    }

    /// @notice Deposit balanced or unbalanced reserves into the pool
    function addLiquidity(uint256 amount0, uint256 amount1, uint256 minShares) external returns (uint256 shares) {
        if (amount0 == 0 && amount1 == 0) revert ZeroAmount();

        uint256 _reserve0 = reserve0;
        uint256 _reserve1 = reserve1;

        if (totalSupply == 0) {
            shares = getD(amount0, amount1);
            reserve0 = amount0;
            reserve1 = amount1;
        } else {
            uint256 d0 = getD(_reserve0, _reserve1);
            uint256 d1 = getD(_reserve0 + amount0, _reserve1 + amount1);
            shares = (totalSupply * (d1 - d0)) / d0;

            reserve0 = _reserve0 + amount0;
            reserve1 = _reserve1 + amount1;
        }

        if (shares < minShares) revert InsufficientOutput();

        balanceOf[msg.sender] += shares;
        totalSupply += shares;

        if (amount0 > 0) _safeTransferFrom(token0, msg.sender, address(this), amount0);
        if (amount1 > 0) _safeTransferFrom(token1, msg.sender, address(this), amount1);

        emit AddLiquidity(msg.sender, amount0, amount1, shares);
    }

    /// @notice Swap token0 for token1 using the Stableswap invariant
    function swap0For1(uint256 amount0In, uint256 minAmount1Out) external returns (uint256 amount1Out) {
        if (amount0In == 0) revert ZeroAmount();

        uint256 x = reserve0 + amount0In;
        uint256 D = getD(reserve0, reserve1);
        uint256 y = getY(x, D);

        amount1Out = reserve1 - y;
        if (amount1Out < minAmount1Out) revert InsufficientOutput();

        reserve0 = x;
        reserve1 = y;

        _safeTransferFrom(token0, msg.sender, address(this), amount0In);
        _safeTransfer(token1, msg.sender, amount1Out);

        emit TokenExchange(msg.sender, amount0In, amount1Out);
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
