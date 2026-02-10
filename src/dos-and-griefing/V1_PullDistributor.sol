// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Errors} from "../common/Errors.sol";

/// @title V1_PullDistributor
/// @notice Fixed: records entitlements; users withdraw (pull payments).
contract V1_PullDistributor {
    address public owner;
    mapping(address => uint256) public claimable;

    event Entitled(address indexed user, uint256 amount);
    event Claimed(address indexed user, uint256 amount);

    constructor() {
        owner = msg.sender;
    }

    receive() external payable {}

    function setEntitlements(address[] calldata recipients, uint256 amountEach) external {
        if (msg.sender != owner) revert Errors.Unauthorized();
        if (amountEach == 0) revert Errors.ZeroAmount();

        uint256 total = recipients.length * amountEach;
        require(address(this).balance >= total, "INSUFFICIENT_ETH");

        for (uint256 i = 0; i < recipients.length; i++) {
            claimable[recipients[i]] += amountEach;
            emit Entitled(recipients[i], amountEach);
        }
    }

    function claim() external {
        uint256 amount = claimable[msg.sender];
        if (amount == 0) revert Errors.ZeroAmount();

        // Effects first
        claimable[msg.sender] = 0;

        // Interaction last
        (bool ok,) = payable(msg.sender).call{value: amount}("");
        require(ok, "PAYMENT_FAILED");

        emit Claimed(msg.sender, amount);
    }
}
