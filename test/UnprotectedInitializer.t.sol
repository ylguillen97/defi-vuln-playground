// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";

import {V1_UnprotectedInitializer} from "../src/upgradeability-footguns/V1_UnprotectedInitializer.sol";
import {V1_FixedInitializer} from "../src/upgradeability-footguns/V1_FixedInitializer.sol";
import {V1_AttackerInit} from "../src/upgradeability-footguns/V1_AttackerInit.sol";

contract UnprotectedInitializerTest is Test {
    address internal deployer = address(0x1234);
    address internal victimUser = address(0xBEEF);
    address internal thief = address(0x1337);

    function setUp() public {
        vm.deal(deployer, 10 ether);
        vm.deal(victimUser, 10 ether);
        vm.deal(thief, 0);
    }

    function test_exploit_unprotected_initialize_takeover_and_sweep() public {
        // Deploy vulnerable implementation
        vm.prank(deployer);
        V1_UnprotectedInitializer impl = new V1_UnprotectedInitializer();

        // Someone funds it (this happens a lot: implementation receives ETH/tokens by mistake)
        vm.prank(victimUser);
        (bool ok, ) = address(impl).call{value: 5 ether}("");
        assertTrue(ok);
        assertEq(address(impl).balance, 5 ether);

        // Attacker takes ownership by calling initialize
        V1_AttackerInit attacker = new V1_AttackerInit(address(impl), thief);
        attacker.pwn();

        // Funds are gone
        assertEq(address(impl).balance, 0);
        assertEq(thief.balance, 5 ether);
    }

    function test_fix_initialize_only_once_blocks_takeover() public {
        vm.prank(deployer);
        V1_FixedInitializer impl = new V1_FixedInitializer();

        vm.prank(victimUser);
        (bool ok, ) = address(impl).call{value: 5 ether}("");
        assertTrue(ok);
        assertEq(address(impl).balance, 5 ether);

        // Legit initialization by deployer/owner
        vm.prank(deployer);
        impl.initialize(deployer);

        // Attacker attempts to re-initialize should revert
        V1_AttackerInit attacker = new V1_AttackerInit(address(impl), thief);

        vm.expectRevert(bytes("ALREADY_INITIALIZED"));
        attacker.pwn();

        // Funds remain (not swept)
        assertEq(address(impl).balance, 5 ether);
        assertEq(thief.balance, 0);
    }
}
