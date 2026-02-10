// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Errors} from "../common/Errors.sol";

/// @title V1_PushDistributor
/// @notice Vulnerable: pushes ETH to recipients in a loop.
/// @dev BUG: if any recipient reverts, the whole distribution reverts (DoS).
contract V1_PushDistributor {
    address public owner;

    event Distributed(uint256 total, uint256 recipients);

    constructor() {
        owner = msg.sender;
    }

    receive() external payable {}

    function distribute(address[] calldata recipients, uint256 amountEach) external {
        if (msg.sender != owner) revert Errors.Unauthorized();
        if (amountEach == 0) revert Errors.ZeroAmount();

        uint256 total = recipients.length * amountEach;
        require(address(this).balance >= total, "INSUFFICIENT_ETH");

        for (uint256 i = 0; i < recipients.length; i++) {
            // If any recipient reverts, the entire tx reverts => DoS.
            (bool ok,) = payable(recipients[i]).call{value: amountEach}("");
            require(ok, "PAYMENT_FAILED");
        }

        emit Distributed(total, recipients.length);
    }
}
