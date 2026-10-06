// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {CollateralizedDebtPosition} from "../src/02_DeFi/CollateralizedDebtPosition.sol";
import {ERC20Votes} from "../src/01_Tokens/ERC20Votes.sol";

contract CollateralizedDebtPositionTest is Test {
    CollateralizedDebtPosition public cdp;
    ERC20Votes public dai;

    address public alice = address(0xA11CE);
    address public liquidator = address(0xDEAD);

    function setUp() public {
        dai = new ERC20Votes("Dai Stablecoin", "DAI");
        // ETH price = $2,000 USD
        cdp = new CollateralizedDebtPosition(address(dai), 2000e18);

        vm.deal(alice, 10 ether);
        vm.deal(liquidator, 10 ether);
    }

    function test_DepositAndBorrowSafely() public {
        vm.startPrank(alice);
        // Deposit 2 ETH ($4,000 collateral)
        cdp.depositCollateral{value: 2 ether}();

        // Borrow 2,000 DAI (collateral ratio = 4000/2000 = 200% > 150%)
        cdp.borrow(2000e18);
        vm.stopPrank();

        assertEq(dai.balanceOf(alice), 2000e18);
        assertEq(cdp.getHealthRatio(alice), 200);
    }

    function test_BorrowExceedingRatioReverts() public {
        vm.startPrank(alice);
        cdp.depositCollateral{value: 1 ether}(); // $2,000 collateral

        // Trying to borrow 1,500 DAI (ratio = 2000/1500 = 133% < 150%)
        vm.expectRevert(CollateralizedDebtPosition.UnsafeCollateralRatio.selector);
        cdp.borrow(1500e18);
        vm.stopPrank();
    }

    function test_PriceDropEnablesLiquidation() public {
        vm.startPrank(alice);
        cdp.depositCollateral{value: 1 ether}(); // $2,000
        cdp.borrow(1000e18); // 200% ratio
        vm.stopPrank();

        // ETH drops to $1,200 USD (ratio drops to 120% < 130% liquidation trigger)
        cdp.setEthPriceUSD(1200e18);
        assertEq(cdp.getHealthRatio(alice), 120);

        // Liquidator acquires 1000 DAI to liquidate
        dai.mint(liquidator, 1000e18);

        uint256 liquidatorEthBefore = liquidator.balance;

        vm.prank(liquidator);
        cdp.liquidate(alice);

        // Liquidator seized collateral at 10% discount
        assertGt(liquidator.balance, liquidatorEthBefore);
        assertEq(cdp.getHealthRatio(alice), type(uint256).max); // 0 debt left
    }
}
