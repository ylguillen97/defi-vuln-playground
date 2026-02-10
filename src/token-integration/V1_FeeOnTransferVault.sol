// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20Mock} from "../common/ERC20Mock.sol";
import {Errors} from "../common/Errors.sol";

/// @title V1_FeeOnTransferVault
/// @notice Vulnerable vault that assumes token transfers are 1:1.
/// @dev BUG: fee-on-transfer tokens cause the vault to receive less than `amount`,
///      but users are credited with the full `amount`, leading to insolvency.
contract V1_FeeOnTransferVault {
    ERC20Mock public immutable TOKEN;

    mapping(address => uint256) public balanceOf;
    uint256 public totalLiabilities;
    uint256 _locked = 1;

    event Deposited(address indexed user, uint256 amountCredited);
    event Withdrawn(address indexed user, uint256 amountDebited);

    modifier nonReentrant() {
        if (_locked != 1) revert Errors.Reentrancy();
        _locked = 2;
        _;
        _locked = 1;
    }

    constructor(address token_) {
        TOKEN = ERC20Mock(token_);
    }

    function deposit(uint256 amount) external {
        if (amount == 0) revert Errors.ZeroAmount();

        // Assumes vault receives exactly `amount`
        balanceOf[msg.sender] += amount;
        totalLiabilities += amount;

        require(TOKEN.transferFrom(msg.sender, address(this), amount), "TF");

        emit Deposited(msg.sender, amount);
    }

    function withdraw(uint256 amount) external  nonReentrant(){
        if (amount == 0) revert Errors.ZeroAmount();

        uint256 bal = balanceOf[msg.sender];
        if (bal < amount) revert Errors.InsufficientBalance(bal, amount);

        balanceOf[msg.sender] = bal - amount;
        totalLiabilities -= amount;

        require(TOKEN.transfer(msg.sender, amount), "T");

        emit Withdrawn(msg.sender, amount);
    }

    function totalAssets() external view returns (uint256) {
        return TOKEN.balanceOf(address(this));
    }
}