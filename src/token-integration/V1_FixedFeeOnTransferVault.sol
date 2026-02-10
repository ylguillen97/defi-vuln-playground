// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20Mock} from "../common/ERC20Mock.sol";
import {Errors} from "../common/Errors.sol";

/// @title V1_FixedFeeOnTransferVault
/// @notice Fixed vault that credits users by the actual amount received.
contract V1_FixedFeeOnTransferVault {
    ERC20Mock public immutable TOKEN;

    mapping(address => uint256) public balanceOf;
    uint256 public totalLiabilities;
    uint256 _locked = 1;

    event Deposited(address indexed user, uint256 amountReceived);
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

        uint256 beforeBal = TOKEN.balanceOf(address(this));
        require(TOKEN.transferFrom(msg.sender, address(this), amount), "TF");
        uint256 afterBal = TOKEN.balanceOf(address(this));

        uint256 received = afterBal - beforeBal;
        require(received > 0, "RECEIVED_ZERO");

        // Credit what the vault actually received
        balanceOf[msg.sender] += received;
        totalLiabilities += received;

        emit Deposited(msg.sender, received);
    }

    function withdraw(uint256 amount) external nonReentrant(){
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