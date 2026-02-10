// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";

import {V1_PushDistributor} from "../src/dos-and-griefing/V1_PushDistributor.sol";
import {V1_PullDistributor} from "../src/dos-and-griefing/V1_PullDistributor.sol";
import {V1_Griefer} from "../src/dos-and-griefing/V1_Griefer.sol";

contract PushPaymentsDoSTest is Test {
    address internal alice = address(0xA11CE);
    address internal bob = address(0xB0B);

    function setUp() public {
        vm.deal(alice, 0);
        vm.deal(bob, 0);
    }

    function test_exploit_push_distribution_reverts_if_one_recipient_reverts() public {
        V1_PushDistributor dist = new V1_PushDistributor();
        V1_Griefer griefer = new V1_Griefer();

        vm.deal(address(dist), 3 ether);

        address[] memory recipients = new address[](3);
        recipients[0] = alice;
        recipients[1] = address(griefer);
        recipients[2] = bob;

        vm.expectRevert("PAYMENT_FAILED");
        dist.distribute(recipients, 1 ether);

        assertEq(alice.balance, 0);
        assertEq(bob.balance, 0);
        assertEq(address(dist).balance, 3 ether);
    }

    function test_fix_pull_payments_allows_honest_users_to_claim_even_with_griefer() public {
        V1_PullDistributor dist = new V1_PullDistributor();
        V1_Griefer griefer = new V1_Griefer();

        vm.deal(address(dist), 3 ether);

        address[] memory recipients = new address[](3);
        recipients[0] = alice;
        recipients[1] = address(griefer);
        recipients[2] = bob;

        dist.setEntitlements(recipients, 1 ether);

        vm.prank(alice);
        dist.claim();
        assertEq(alice.balance, 1 ether);

        vm.prank(bob);
        dist.claim();
        assertEq(bob.balance, 1 ether);

        vm.prank(address(griefer));
        vm.expectRevert("PAYMENT_FAILED");
        dist.claim();

        assertEq(address(dist).balance, 1 ether);
    }
}
