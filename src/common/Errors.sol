// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

library Errors {
    error ZeroAmount();
    error InsufficientBalance(uint256 have, uint256 need);
    error EthTransferFailed();
    error Reentrancy();

    // Access control
    error Unauthorized();
}
