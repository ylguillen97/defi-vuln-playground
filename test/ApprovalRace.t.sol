// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";

import {V1_ApproveRaceToken} from "../src/approval-race/V1_ApproveRaceToken.sol";
import {V1_FixedApproveToken} from "../src/approval-race/V1_FixedApproveToken.sol";
import {V1_Spender} from "../src/approval-race/V1_Spender.sol";

contract ApprovalRaceTest is Test {
    address internal alice = address(0xA11CE);
    address internal thief = address(0x1337);

    function test_exploit_approval_race_allows_double_spend_of_allowance() public {
        V1_ApproveRaceToken token = new V1_ApproveRaceToken();
        V1_Spender spender = new V1_Spender(address(token), thief);

        token.mint(alice, 200 ether);

        // Alice sets initial allowance X=100
        vm.prank(alice);
        token.approve(address(spender), 100 ether);

        // Alice intends to change allowance to Y=50 using approve(50)
        // In the mempool, spender front-runs and spends 100 first...
        vm.prank(address(spender));
        spender.drain(alice, 100 ether);

        // ...then Alice's approve(50) is mined afterwards
        vm.prank(alice);
        token.approve(address(spender), 50 ether);

        // Spender can now spend the new 50 too => total spent = 150
        vm.prank(address(spender));
        spender.drain(alice, 50 ether);

        assertEq(token.balanceOf(thief), 150 ether);
        assertEq(token.balanceOf(alice), 50 ether);
    }

    function test_fix_requires_zero_reset_or_use_increaseAllowance() public {
        V1_FixedApproveToken token = new V1_FixedApproveToken();
        V1_Spender spender = new V1_Spender(address(token), thief);

        token.mint(alice, 200 ether);

        vm.prank(alice);
        token.approve(address(spender), 100 ether);

        // front-run spends only part, leaving allowance non-zero
        vm.prank(address(spender));
        spender.drain(alice, 60 ether); // allowance now 40

        vm.prank(alice);
        vm.expectRevert("NONZERO_TO_NONZERO");
        token.approve(address(spender), 50 ether);

        vm.prank(alice);
        token.approve(address(spender), 0);

        vm.prank(alice);
        token.approve(address(spender), 50 ether);

        vm.prank(address(spender));
        spender.drain(alice, 50 ether);

        assertEq(token.balanceOf(thief), 110 ether);
        assertEq(token.balanceOf(alice), 90 ether);
    }

}
