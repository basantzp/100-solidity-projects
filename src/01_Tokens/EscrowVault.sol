// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/// @title EscrowVault
/// @notice Multi-asset conditional escrow with buyer, seller, and third-party arbiter dispute resolution.
contract EscrowVault {
    // --- Errors ---
    error InvalidState();
    error NotParty();
    error ZeroAmount();
    error ZeroAddress();
    error TransferFailed();

    // --- Enums & Structs ---
    enum EscrowState {
        Created,
        Funded,
        Completed,
        Refunded,
        Disputed
    }

    struct Escrow {
        address buyer;
        address seller;
        address arbiter;
        uint256 amount;
        EscrowState state;
    }

    // --- State Variables ---
    uint256 public nextEscrowId;
    mapping(uint256 => Escrow) public escrows;

    // --- Events ---
    event EscrowCreated(uint256 indexed escrowId, address indexed buyer, address indexed seller, address arbiter);
    event EscrowFunded(uint256 indexed escrowId, uint256 amount);
    event EscrowReleased(uint256 indexed escrowId);
    event EscrowRefunded(uint256 indexed escrowId);
    event EscrowDisputed(uint256 indexed escrowId);

    function createEscrow(address seller, address arbiter) external returns (uint256 escrowId) {
        if (seller == address(0) || arbiter == address(0)) revert ZeroAddress();

        escrowId = nextEscrowId++;
        escrows[escrowId] =
            Escrow({buyer: msg.sender, seller: seller, arbiter: arbiter, amount: 0, state: EscrowState.Created});

        emit EscrowCreated(escrowId, msg.sender, seller, arbiter);
    }

    function fundEscrow(uint256 escrowId) external payable {
        Escrow storage e = escrows[escrowId];
        if (e.state != EscrowState.Created) revert InvalidState();
        if (msg.sender != e.buyer) revert NotParty();
        if (msg.value == 0) revert ZeroAmount();

        e.amount = msg.value;
        e.state = EscrowState.Funded;

        emit EscrowFunded(escrowId, msg.value);
    }

    /// @notice Buyer or arbiter can release funds to the seller
    function release(uint256 escrowId) external {
        Escrow storage e = escrows[escrowId];
        if (e.state != EscrowState.Funded && e.state != EscrowState.Disputed) revert InvalidState();
        if (msg.sender != e.buyer && msg.sender != e.arbiter) revert NotParty();

        e.state = EscrowState.Completed;
        uint256 amount = e.amount;
        e.amount = 0;

        (bool success,) = payable(e.seller).call{value: amount}("");
        if (!success) revert TransferFailed();

        emit EscrowReleased(escrowId);
    }

    /// @notice Seller or arbiter can refund buyer
    function refund(uint256 escrowId) external {
        Escrow storage e = escrows[escrowId];
        if (e.state != EscrowState.Funded && e.state != EscrowState.Disputed) revert InvalidState();
        if (msg.sender != e.seller && msg.sender != e.arbiter) revert NotParty();

        e.state = EscrowState.Refunded;
        uint256 amount = e.amount;
        e.amount = 0;

        (bool success,) = payable(e.buyer).call{value: amount}("");
        if (!success) revert TransferFailed();

        emit EscrowRefunded(escrowId);
    }

    /// @notice Buyer or seller can raise a dispute to seek arbiter intervention
    function dispute(uint256 escrowId) external {
        Escrow storage e = escrows[escrowId];
        if (e.state != EscrowState.Funded) revert InvalidState();
        if (msg.sender != e.buyer && msg.sender != e.seller) revert NotParty();

        e.state = EscrowState.Disputed;
        emit EscrowDisputed(escrowId);
    }
}
