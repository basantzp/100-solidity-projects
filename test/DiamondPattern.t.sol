// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {DiamondPattern} from "../src/06_Upgradeability/DiamondPattern.sol";

// Storage layout shared by Diamond facets
library DiamondStorage {
    struct AppStorage {
        uint256 valueA;
        string messageB;
    }

    bytes32 constant POSITION = keccak256("diamond.app.storage");

    function appStorage() internal pure returns (AppStorage storage ds) {
        bytes32 position = POSITION;
        assembly {
            ds.slot := position
        }
    }
}

contract FacetA {
    function setValueA(uint256 v) external {
        DiamondStorage.appStorage().valueA = v;
    }

    function getValueA() external view returns (uint256) {
        return DiamondStorage.appStorage().valueA;
    }
}

contract FacetB {
    function setMessageB(string calldata m) external {
        DiamondStorage.appStorage().messageB = m;
    }

    function getMessageB() external view returns (string memory) {
        return DiamondStorage.appStorage().messageB;
    }
}

contract DiamondPatternTest is Test {
    DiamondPattern public diamond;
    FacetA public facetA;
    FacetB public facetB;

    address public owner = address(this);

    function setUp() public {
        diamond = new DiamondPattern(owner);
        facetA = new FacetA();
        facetB = new FacetB();

        // Build Diamond cuts
        DiamondPattern.FacetCut[] memory cuts = new DiamondPattern.FacetCut[](2);

        bytes4[] memory selectorsA = new bytes4[](2);
        selectorsA[0] = FacetA.setValueA.selector;
        selectorsA[1] = FacetA.getValueA.selector;

        cuts[0] = DiamondPattern.FacetCut({
            facetAddress: address(facetA), action: DiamondPattern.FacetCutAction.Add, functionSelectors: selectorsA
        });

        bytes4[] memory selectorsB = new bytes4[](2);
        selectorsB[0] = FacetB.setMessageB.selector;
        selectorsB[1] = FacetB.getMessageB.selector;

        cuts[1] = DiamondPattern.FacetCut({
            facetAddress: address(facetB), action: DiamondPattern.FacetCutAction.Add, functionSelectors: selectorsB
        });

        diamond.diamondCut(cuts);
    }

    function test_MultiFacetRouting() public {
        // Call FacetA through diamond
        FacetA(address(diamond)).setValueA(777);
        assertEq(FacetA(address(diamond)).getValueA(), 777);

        // Call FacetB through diamond
        FacetB(address(diamond)).setMessageB("Hello Diamond");
        assertEq(FacetB(address(diamond)).getMessageB(), "Hello Diamond");
    }

    function test_RemoveFacetSelector() public {
        DiamondPattern.FacetCut[] memory cuts = new DiamondPattern.FacetCut[](1);

        bytes4[] memory selectors = new bytes4[](1);
        selectors[0] = FacetA.setValueA.selector;

        cuts[0] = DiamondPattern.FacetCut({
            facetAddress: address(0), action: DiamondPattern.FacetCutAction.Remove, functionSelectors: selectors
        });

        diamond.diamondCut(cuts);

        vm.expectRevert(DiamondPattern.FunctionDoesNotExist.selector);
        FacetA(address(diamond)).setValueA(123);
    }
}
