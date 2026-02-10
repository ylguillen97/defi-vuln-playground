// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Errors} from "../common/Errors.sol";

/// @title V1_VulnerableVault
/// @notice Intentionally vulnerable ETH vault to demonstrate classic reentrancy.
/// @dev Bug: sends ETH before updating user balance (CEI violation).
contract V1_VulnerableVault {
    mapping(address => uint256) public balanceOf;

    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);

    function deposit() external payable {
        if (msg.value == 0) revert Errors.ZeroAmount();
        balanceOf[msg.sender] += msg.value;
        emit Deposited(msg.sender, msg.value);
    }

    function withdraw(uint256 amount) external {
        uint256 bal = balanceOf[msg.sender];
        if (amount == 0) revert Errors.ZeroAmount();
        if (bal < amount) revert Errors.InsufficientBalance(bal, amount);

        // VULNERABLE: interaction before effects (reentrancy window)
        (bool ok,) = msg.sender.call{value: amount}("");
        if (!ok) revert Errors.EthTransferFailed();

        // Effects happen too late
        balanceOf[msg.sender] = bal - amount;

        emit Withdrawn(msg.sender, amount);
    }

    function totalAssets() external view returns (uint256) {
        return address(this).balance;
    }
}
