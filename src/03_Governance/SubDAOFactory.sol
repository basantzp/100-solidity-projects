// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/// @title SubDAOTreasury
/// @notice Autonomous sub-treasury controlled by local sub-council but subordinate to parent DAO clawback.
contract SubDAOTreasury {
    // --- Errors ---
    error Unauthorized();
    error TransferFailed();

    // --- Events ---
    event Disbursed(address indexed recipient, uint256 amount);
    event EmergencyClawback(address indexed parentDAO, uint256 amount);

    address public immutable parentDAO;
    address public localCouncil;

    modifier onlyCouncil() {
        if (msg.sender != localCouncil) revert Unauthorized();
        _;
    }

    modifier onlyParent() {
        if (msg.sender != parentDAO) revert Unauthorized();
        _;
    }

    constructor(address _parentDAO, address _localCouncil) {
        parentDAO = _parentDAO;
        localCouncil = _localCouncil;
    }

    receive() external payable {}

    function disburse(address payable recipient, uint256 amount) external onlyCouncil {
        (bool success,) = recipient.call{value: amount}("");
        if (!success) revert TransferFailed();
        emit Disbursed(recipient, amount);
    }

    function emergencyClawback() external onlyParent {
        uint256 balance = address(this).balance;
        (bool success,) = parentDAO.call{value: balance}("");
        if (!success) revert TransferFailed();
        emit EmergencyClawback(parentDAO, balance);
    }
}

/// @title SubDAOFactory
/// @notice Hierarchical factory deploying sub-DAOs with parent DAO oversight.
contract SubDAOFactory {
    event SubDAOCreated(address indexed subDAO, address indexed parentDAO, address indexed localCouncil);

    address public immutable parentDAO;
    address[] public deployedSubDAOs;

    constructor(address _parentDAO) {
        parentDAO = _parentDAO;
    }

    function deploySubDAO(address localCouncil) external returns (address subDAO) {
        SubDAOTreasury instance = new SubDAOTreasury(parentDAO, localCouncil);
        subDAO = address(instance);
        deployedSubDAOs.push(subDAO);

        emit SubDAOCreated(subDAO, parentDAO, localCouncil);
    }

    function getSubDAOsCount() external view returns (uint256) {
        return deployedSubDAOs.length;
    }
}
