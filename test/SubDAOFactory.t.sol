// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {SubDAOFactory, SubDAOTreasury} from "../src/03_Governance/SubDAOFactory.sol";

contract SubDAOFactoryTest is Test {
    SubDAOFactory public factory;

    address payable public parentDAO = payable(address(0x1010));
    address public localCouncil = address(0x2020);
    address payable public contributor = payable(address(0x3030));

    function setUp() public {
        factory = new SubDAOFactory(parentDAO);
    }

    function test_DeploySubDAOAndEmergencyClawback() public {
        address subDAOAddr = factory.deploySubDAO(localCouncil);
        SubDAOTreasury subDAO = SubDAOTreasury(payable(subDAOAddr));

        // Fund SubDAO treasury with 5 ETH
        vm.deal(subDAOAddr, 5 ether);

        // Local council disburses 1 ETH to contributor
        vm.prank(localCouncil);
        subDAO.disburse(contributor, 1 ether);
        assertEq(contributor.balance, 1 ether);
        assertEq(subDAOAddr.balance, 4 ether);

        // Parent DAO executes emergency clawback of remaining 4 ETH
        vm.prank(parentDAO);
        subDAO.emergencyClawback();
        assertEq(subDAOAddr.balance, 0);
        assertEq(parentDAO.balance, 4 ether);
    }
}
