// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Errors} from "../common/Errors.sol";

/// @title V1_FixedVault
/// @notice Fixed ETH vault that prevents reentrancy.
/// @dev Uses Checks-Effects-Interactions + a simple reentrancy guard.
contract V1_FixedVault {
    mapping(address => uint256) public balanceOf;

    uint256 private _locked = 1;

    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);

    modifier nonReentrant() {
        if (_locked != 1) revert Errors.Reentrancy();
        _locked = 2;
        _;
        _locked = 1;
    }

    function deposit() external payable {
        if (msg.value == 0) revert Errors.ZeroAmount();
        balanceOf[msg.sender] += msg.value;
        emit Deposited(msg.sender, msg.value);
    }

    function withdraw(uint256 amount) external nonReentrant {
        uint256 bal = balanceOf[msg.sender];
        if (amount == 0) revert Errors.ZeroAmount();
        if (bal < amount) revert Errors.InsufficientBalance(bal, amount);

        // Effects first
        balanceOf[msg.sender] = bal - amount;

        // Interaction last
        (bool ok,) = msg.sender.call{value: amount}("");
        if (!ok) revert Errors.EthTransferFailed();

        emit Withdrawn(msg.sender, amount);
    }

    function totalAssets() external view returns (uint256) {
        return address(this).balance;
    }
}
