// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";

import {ERC20Mock} from "../src/common/ERC20Mock.sol";
import {V1_SimpleAMM} from "../src/mev-sandwich/V1_SimpleAMM.sol";
import {V1_VulnerableRouter} from "../src/mev-sandwich/V1_VulnerableRouter.sol";
import {V1_FixedRouter} from "../src/mev-sandwich/V1_FixedRouter.sol";

contract SandwichTest is Test {
    address internal lp = address(0xBEEF);
    address internal user = address(0xCAFE);
    address internal mev = address(0xB0B0B0);

    ERC20Mock internal t0;
    ERC20Mock internal t1;

    V1_SimpleAMM internal amm;
    V1_VulnerableRouter internal vuln;
    V1_FixedRouter internal fixedR;

    function setUp() public {
        t0 = new ERC20Mock("Token0", "T0");
        t1 = new ERC20Mock("Token1", "T1");

        amm = new V1_SimpleAMM(address(t0), address(t1));
        vuln = new V1_VulnerableRouter(address(amm));
        fixedR = new V1_FixedRouter(address(amm));

        // Liquidity 1000 / 1000
        t0.mint(lp, 2000 ether);
        t1.mint(lp, 2000 ether);

        vm.startPrank(lp);
        t0.approve(address(amm), type(uint256).max);
        t1.approve(address(amm), type(uint256).max);
        amm.addLiquidity(1000 ether, 1000 ether);
        vm.stopPrank();

        // User has 100 T0
        t0.mint(user, 100 ether);

        // MEV has 500 T0 and 500 T1 (can move price)
        t0.mint(mev, 500 ether);
        t1.mint(mev, 500 ether);
    }

    function test_vulnerable_router_user_gets_sandwiched() public {
        uint256 userIn = 50 ether;

        // Quote before attack (what user expects-ish)
        uint256 expectedOut = amm.quote0To1(userIn);

        // MEV front-runs: buys T1 with T0 => worsens price for user (T1 becomes scarcer)
        vm.startPrank(mev);
        t0.approve(address(amm), type(uint256).max);
        amm.swapExact0For1(200 ether, mev);
        vm.stopPrank();

        // User swaps with router (no minOut)
        vm.startPrank(user);
        t0.approve(address(vuln), type(uint256).max);
        uint256 actualOut = vuln.swapExact0For1(userIn);
        vm.stopPrank();

        // actualOut much worse than expectedOut
        assertLt(actualOut, (expectedOut * 80) / 100); // >20% slippage
    }

    function test_fixed_router_reverts_if_sandwiched() public {
        uint256 userIn = 50 ether;
        uint256 expectedOut = amm.quote0To1(userIn);

        // MEV front-run again
        vm.startPrank(mev);
        t0.approve(address(amm), type(uint256).max);
        amm.swapExact0For1(200 ether, mev);
        vm.stopPrank();

        // User sets tight slippage (e.g. 1%)
        uint256 minOut = (expectedOut * 99) / 100;

        vm.startPrank(user);
        t0.approve(address(fixedR), type(uint256).max);
        vm.expectRevert("SLIPPAGE");
        fixedR.swapExact0For1(userIn, minOut, block.timestamp);
        vm.stopPrank();
    }

    function test_fixed_router_reverts_if_deadline_expired() public {
        vm.warp(1000);
        vm.startPrank(user);
        t0.approve(address(fixedR), type(uint256).max);
        vm.expectRevert("DEADLINE_EXPIRED");
        fixedR.swapExact0For1(1 ether, 0, 999);
        vm.stopPrank();
    }
}
