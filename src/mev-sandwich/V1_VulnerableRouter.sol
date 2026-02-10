// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20Mock} from "../common/ERC20Mock.sol";
import {V1_SimpleAMM} from "./V1_SimpleAMM.sol";

/// @notice Vulnerable: no slippage protection, no deadline.
contract V1_VulnerableRouter {
    V1_SimpleAMM public immutable amm;
    ERC20Mock public immutable token0;
    ERC20Mock public immutable token1;

    constructor(address amm_) {
        amm = V1_SimpleAMM(amm_);
        token0 = amm.token0();
        token1 = amm.token1();
    }

    function swapExact0For1(uint256 amountIn) external returns (uint256 amountOut) {
        // no amountOutMin, no deadline
        require(token0.transferFrom(msg.sender, address(this), amountIn), "TF0");
        require(token0.approve(address(amm), amountIn), "APPROVE");
        amountOut = amm.swapExact0For1(amountIn, msg.sender);
    }
}
