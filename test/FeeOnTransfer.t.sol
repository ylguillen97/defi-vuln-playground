// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";

import {ERC20FeeOnTransferMock} from "../src/token-integration/ERC20FeeOnTransferMock.sol";
import {V1_FeeOnTransferVault} from "../src/token-integration/V1_FeeOnTransferVault.sol";
import {V1_FixedFeeOnTransferVault} from "../src/token-integration/V1_FixedFeeOnTransferVault.sol";

contract FeeOnTransferTest is Test {
    address internal alice = address(0xA11CE);
    address internal bob = address(0xB0B);

    ERC20FeeOnTransferMock internal token;

    function setUp() public {
        // 10% fee
        token = new ERC20FeeOnTransferMock("Fee Token", "FEE", 1000);

        token.mint(alice, 1_000 ether);
        token.mint(bob, 1_000 ether);
    }

    function test_exploit_vault_becomes_insolvent() public {
        V1_FeeOnTransferVault vault = new V1_FeeOnTransferVault(address(token));

        vm.startPrank(alice);
        token.approve(address(vault), type(uint256).max);
        vault.deposit(100 ether); // vault receives 90, alice credited 100
        vm.stopPrank();

        vm.startPrank(bob);
        token.approve(address(vault), type(uint256).max);
        vault.deposit(100 ether); // vault receives 90, bob credited 100
        vm.stopPrank();

        // Vault has only 180, but owes 200
        assertEq(token.balanceOf(address(vault)), 180 ether);
        assertEq(vault.totalLiabilities(), 200 ether);

        // Alice withdraws first (succeeds, vault has enough for this transfer)
        vm.prank(alice);
        vault.withdraw(100 ether);

        // Now vault balance is 80 (it transferred 100 out; fee burned on transfer reduces what alice receives)
        assertEq(token.balanceOf(address(vault)), 80 ether);

        // Bob tries to withdraw his "100" but vault doesn't have it -> transfer reverts with BAL
        vm.prank(bob);
        vm.expectRevert(bytes("BAL"));
        vault.withdraw(100 ether);
    }

    function test_fix_credits_received_amount_and_remains_solvent() public {
        V1_FixedFeeOnTransferVault vault = new V1_FixedFeeOnTransferVault(address(token));

        vm.startPrank(alice);
        token.approve(address(vault), type(uint256).max);
        vault.deposit(100 ether); // vault receives 90, alice credited 90
        vm.stopPrank();

        vm.startPrank(bob);
        token.approve(address(vault), type(uint256).max);
        vault.deposit(100 ether); // vault receives 90, bob credited 90
        vm.stopPrank();

        assertEq(token.balanceOf(address(vault)), 180 ether);
        assertEq(vault.totalLiabilities(), 180 ether);

        vm.prank(alice);
        vault.withdraw(90 ether);

        vm.prank(bob);
        vault.withdraw(90 ether);

        assertEq(token.balanceOf(address(vault)), 0);
        assertEq(vault.totalLiabilities(), 0);
    }
}
