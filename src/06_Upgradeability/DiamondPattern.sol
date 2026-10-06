// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/// @title DiamondPattern (ERC-2535 Multi-Facet Proxy)
/// @notice Modular multi-facet diamond standard bypassing the 24KB contract size limit with granular selector routing.
contract DiamondPattern {
    // --- Errors ---
    error Unauthorized();
    error FunctionDoesNotExist();
    error FunctionAlreadyExists();
    error InvalidFacetAddress();
    error DelegatecallFailed();

    // --- Enums & Structs ---
    enum FacetCutAction {
        Add,
        Replace,
        Remove
    }

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    // --- Storage ---
    address public owner;
    mapping(bytes4 => address) public facetAddress;

    event DiamondCut(FacetCut[] cuts);

    modifier onlyOwner() {
        if (msg.sender != owner) revert Unauthorized();
        _;
    }

    constructor(address _owner) {
        owner = _owner;
    }

    /// @notice Execute diamond cut: add, replace, or remove facet function selectors
    function diamondCut(FacetCut[] calldata cuts) external onlyOwner {
        for (uint256 i = 0; i < cuts.length; i++) {
            FacetCut calldata cut = cuts[i];
            address facet = cut.facetAddress;
            FacetCutAction action = cut.action;

            if (action == FacetCutAction.Add) {
                if (facet.code.length == 0) revert InvalidFacetAddress();
                for (uint256 s = 0; s < cut.functionSelectors.length; s++) {
                    bytes4 selector = cut.functionSelectors[s];
                    if (facetAddress[selector] != address(0)) revert FunctionAlreadyExists();
                    facetAddress[selector] = facet;
                }
            } else if (action == FacetCutAction.Replace) {
                if (facet.code.length == 0) revert InvalidFacetAddress();
                for (uint256 s = 0; s < cut.functionSelectors.length; s++) {
                    bytes4 selector = cut.functionSelectors[s];
                    if (facetAddress[selector] == address(0)) revert FunctionDoesNotExist();
                    facetAddress[selector] = facet;
                }
            } else if (action == FacetCutAction.Remove) {
                for (uint256 s = 0; s < cut.functionSelectors.length; s++) {
                    bytes4 selector = cut.functionSelectors[s];
                    if (facetAddress[selector] == address(0)) revert FunctionDoesNotExist();
                    delete facetAddress[selector];
                }
            }
        }
        emit DiamondCut(cuts);
    }

    fallback() external payable {
        address facet = facetAddress[msg.sig];
        if (facet == address(0)) revert FunctionDoesNotExist();

        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), facet, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    receive() external payable {}
}
