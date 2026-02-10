// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";


import {V1_VulnerableVault} from "../src/reentrancy/V1_VulnerableVault.sol";
import {V1_FixedVault} from "../src/reentrancy/V1_FixedVault.sol";
import {V1_Attacker} from "../src/reentrancy/V1_Attacker.sol";

contract ReentrancyTest is Test {
    V1_VulnerableVault internal vuln;
    V1_FixedVault internal fixedVault;

    address internal alice = address(0xA11CE);
    address internal bob   = address(0xB0B);

    function setUp() public {
        vuln = new V1_VulnerableVault();
        fixedVault = new V1_FixedVault();

        // Seed vaults with ETH from honest users so there's something to drain.
        vm.deal(alice, 20 ether);
        vm.deal(bob, 20 ether);

        vm.prank(alice);
        vuln.deposit{value: 10 ether}();

        vm.prank(bob);
        vuln.deposit{value: 10 ether}();

        vm.prank(alice);
        fixedVault.deposit{value: 10 ether}();

        vm.prank(bob);
        fixedVault.deposit{value: 10 ether}();
    }

    function test_exploit_drains_vulnerable_vault() public {
        // Attacker deposits 1 ether and withdraws in 1 ether chunks.
        uint256 chunk = 1 ether;
        V1_Attacker attacker = new V1_Attacker(address(vuln), chunk);

        vm.deal(address(attacker), 1 ether);

        uint256 vaultBefore = address(vuln).balance;
        assertEq(vaultBefore, 20 ether);

        // Start attack
        vm.prank(attacker.OWNER());
        attacker.attack{value: 1 ether}();

        uint256 vaultAfter = address(vuln).balance;

        // Attacker should have drained almost all vault balance (minus any rounding effects; here exact).
        assertLt(vaultAfter, 5 ether); // strong signal; should be 0 in this setup
        assertGt(address(attacker).balance, 15 ether);

        // Honest users' accounting is now broken relative to assets.
        assertEq(vuln.balanceOf(alice), 10 ether);
        assertEq(vuln.balanceOf(bob), 10 ether);
        // Yet vault has little ETH left -> insolvency.
    }

    function test_fix_prevents_reentrancy() public {
        uint256 chunk = 1 ether;
        V1_Attacker attacker = new V1_Attacker(address(fixedVault), chunk);

        vm.deal(address(attacker), 1 ether);

        uint256 vaultBefore = address(fixedVault).balance;
        assertEq(vaultBefore, 20 ether);

        // Attack should fail because fixedVault is nonReentrant and updates state before call.
        vm.prank(attacker.OWNER());
        vm.expectRevert(); // revert selector depends on where it fails (guard / insufficient / etc.)
        attacker.attack{value: 1 ether}();

        // Vault remains solvent.
        uint256 vaultAfter = address(fixedVault).balance;
        assertEq(vaultAfter, 20 ether);

        // Attacker shouldn't profit.
        assertLe(address(attacker).balance, 1 ether);
    }
}