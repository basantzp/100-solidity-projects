// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/// @title PeerToPeerLending
/// @notice Isolated, fixed-duration bilateral peer-to-peer lending primitive with collateral escrow.
contract PeerToPeerLending {
    // --- Errors ---
    error ZeroAmount();
    error InvalidState();
    error Unauthorized();
    error LoanNotMatured();
    error TransferFailed();

    // --- Enums & Structs ---
    enum LoanState {
        Requested,
        Active,
        Repaid,
        Defaulted
    }

    struct Loan {
        address borrower;
        address lender;
        address principalToken;
        uint256 principal;
        uint256 interest;
        address collateralToken;
        uint256 collateral;
        uint256 duration;
        uint256 dueDate;
        LoanState state;
    }

    uint256 public nextLoanId;
    mapping(uint256 => Loan) public loans;

    event LoanRequested(uint256 indexed loanId, address indexed borrower, uint256 principal, uint256 collateral);
    event LoanFunded(uint256 indexed loanId, address indexed lender, uint256 dueDate);
    event LoanRepaid(uint256 indexed loanId);
    event CollateralSeized(uint256 indexed loanId, address indexed lender);

    /// @notice Borrower requests loan by escrowing collateral
    function requestLoan(
        address principalToken,
        uint256 principal,
        uint256 interest,
        address collateralToken,
        uint256 collateral,
        uint256 duration
    ) external returns (uint256 loanId) {
        if (principal == 0 || collateral == 0 || duration == 0) revert ZeroAmount();

        _safeTransferFrom(collateralToken, msg.sender, address(this), collateral);

        loanId = nextLoanId++;
        loans[loanId] = Loan({
            borrower: msg.sender,
            lender: address(0),
            principalToken: principalToken,
            principal: principal,
            interest: interest,
            collateralToken: collateralToken,
            collateral: collateral,
            duration: duration,
            dueDate: 0,
            state: LoanState.Requested
        });

        emit LoanRequested(loanId, msg.sender, principal, collateral);
    }

    /// @notice Lender accepts and funds the loan request
    function fundLoan(uint256 loanId) external {
        Loan storage loan = loans[loanId];
        if (loan.state != LoanState.Requested) revert InvalidState();

        loan.lender = msg.sender;
        loan.dueDate = block.timestamp + loan.duration;
        loan.state = LoanState.Active;

        _safeTransferFrom(loan.principalToken, msg.sender, loan.borrower, loan.principal);

        emit LoanFunded(loanId, msg.sender, loan.dueDate);
    }

    /// @notice Borrower repays principal + interest to reclaim collateral
    function repayLoan(uint256 loanId) external {
        Loan storage loan = loans[loanId];
        if (loan.state != LoanState.Active) revert InvalidState();
        if (block.timestamp > loan.dueDate) revert LoanNotMatured();

        loan.state = LoanState.Repaid;
        uint256 totalRepayment = loan.principal + loan.interest;

        _safeTransferFrom(loan.principalToken, msg.sender, loan.lender, totalRepayment);
        _safeTransfer(loan.collateralToken, loan.borrower, loan.collateral);

        emit LoanRepaid(loanId);
    }

    /// @notice Lender seizes collateral if loan is not repaid by dueDate
    function claimDefaultedCollateral(uint256 loanId) external {
        Loan storage loan = loans[loanId];
        if (loan.state != LoanState.Active) revert InvalidState();
        if (block.timestamp <= loan.dueDate) revert LoanNotMatured();
        if (msg.sender != loan.lender) revert Unauthorized();

        loan.state = LoanState.Defaulted;

        _safeTransfer(loan.collateralToken, loan.lender, loan.collateral);

        emit CollateralSeized(loanId, loan.lender);
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
