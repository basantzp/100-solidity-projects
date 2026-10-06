// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/// @title PaymentSplitter
/// @notice Deterministic revenue sharing for native ETH and ERC-20 tokens.
/// @dev Implements pull-over-push accounting with proportional shares.
contract PaymentSplitter {
    // --- Errors ---
    error InvalidPayees();
    error NoShares();
    error AccountHasNoShares();
    error PaymentFailed();
    error ZeroAddress();
    error NothingDue();

    // --- Events ---
    event PayeeAdded(address indexed account, uint256 shares);
    event PaymentReleased(address indexed to, uint256 amount);
    event ERC20PaymentReleased(address indexed token, address indexed to, uint256 amount);
    event PaymentReceived(address indexed from, uint256 amount);

    // --- State Variables ---
    uint256 public totalShares;
    uint256 public totalReleased;

    mapping(address => uint256) public shares;
    mapping(address => uint256) public released;
    address[] public payees;

    mapping(address => uint256) public totalReleasedERC20;
    mapping(address => mapping(address => uint256)) public releasedERC20;

    constructor(address[] memory _payees, uint256[] memory _shares) payable {
        if (_payees.length == 0 || _payees.length != _shares.length) revert InvalidPayees();

        for (uint256 i = 0; i < _payees.length; i++) {
            _addPayee(_payees[i], _shares[i]);
        }
    }

    receive() external payable {
        emit PaymentReceived(msg.sender, msg.value);
    }

    function release(address payable account) external {
        if (shares[account] == 0) revert AccountHasNoShares();

        uint256 totalReceived = address(this).balance + totalReleased;
        uint256 payment = _pendingPayment(account, totalReceived, released[account]);

        if (payment == 0) revert NothingDue();

        released[account] += payment;
        totalReleased += payment;

        (bool success,) = account.call{value: payment}("");
        if (!success) revert PaymentFailed();

        emit PaymentReleased(account, payment);
    }

    function releasable(address account) external view returns (uint256) {
        uint256 totalReceived = address(this).balance + totalReleased;
        return _pendingPayment(account, totalReceived, released[account]);
    }

    function _pendingPayment(uint256 totalReceived, uint256 alreadyReleased, uint256 accountShares)
        internal
        view
        returns (uint256)
    {
        return (totalReceived * accountShares) / totalShares - alreadyReleased;
    }

    function _pendingPayment(address account, uint256 totalReceived, uint256 alreadyReleased)
        internal
        view
        returns (uint256)
    {
        return _pendingPayment(totalReceived, alreadyReleased, shares[account]);
    }

    function _addPayee(address account, uint256 accountShares) private {
        if (account == address(0)) revert ZeroAddress();
        if (accountShares == 0) revert NoShares();
        if (shares[account] > 0) revert InvalidPayees();

        payees.push(account);
        shares[account] = accountShares;
        totalShares += accountShares;

        emit PayeeAdded(account, accountShares);
    }
}
