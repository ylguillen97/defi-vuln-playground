// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";

import {V1_TxOriginAuth} from "../src/access-control/V1_TxOriginAuth.sol";
import {V1_FixedAuth} from "../src/access-control/V1_FixedAuth.sol";
import {V1_PhishingAttacker} from "../src/access-control/V1_PhishingAttacker.sol";
import {Errors} from "../src/common/Errors.sol";

contract TxOriginTest is Test {
    address internal owner = address(0x1234);
    address internal thief = address(0x1337);

    function setUp() public {
        vm.deal(owner, 10 ether);
        vm.deal(thief, 0);
    }

    function test_exploit_tx_origin_wallet_drains_to_thief() public {
        vm.startPrank(owner, owner);
        V1_TxOriginAuth wallet = new V1_TxOriginAuth(owner);

        (bool ok, ) = address(wallet).call{value: 5 ether}("");
        assertTrue(ok);
        assertEq(address(wallet).balance, 5 ether);

        V1_PhishingAttacker phish = new V1_PhishingAttacker(address(wallet), thief);

        phish.trick();
        vm.stopPrank();

        assertEq(address(wallet).balance, 0);
        assertEq(thief.balance, 5 ether);
    }


    function test_fix_msg_sender_auth_blocks_phishing() public {
        // Deploy fixed wallet
        vm.prank(owner);
        V1_FixedAuth wallet = new V1_FixedAuth(owner);

        // Fund wallet
        vm.prank(owner);
        (bool ok, ) = address(wallet).call{value: 5 ether}("");
        assertTrue(ok);
        assertEq(address(wallet).balance, 5 ether);

        // Phishing contract tries the same trick
        V1_PhishingAttacker phish = new V1_PhishingAttacker(address(wallet), thief);

        // Owner calls phishing contract, but wallet checks msg.sender,
        // so the call originates from phish => Unauthorized
        vm.prank(owner);
        vm.expectRevert(Errors.Unauthorized.selector);
        phish.trick();

        // Funds remain safe
        assertEq(address(wallet).balance, 5 ether);
        assertEq(thief.balance, 0);
    }
}