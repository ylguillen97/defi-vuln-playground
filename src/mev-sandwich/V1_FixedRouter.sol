// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20Mock} from "../common/ERC20Mock.sol";
import {V1_SimpleAMM} from "./V1_SimpleAMM.sol";

/// @notice Fixed: includes amountOutMin + deadline.
contract V1_FixedRouter {
    V1_SimpleAMM public immutable amm;
    ERC20Mock public immutable token0;

    constructor(address amm_) {
        amm = V1_SimpleAMM(amm_);
        token0 = amm.token0();
    }

    function swapExact0For1(uint256 amountIn, uint256 amountOutMin, uint256 deadline)
        external
        returns (uint256 amountOut)
    {
        require(block.timestamp <= deadline, "DEADLINE_EXPIRED");

        require(token0.transferFrom(msg.sender, address(this), amountIn), "TF0");
        require(token0.approve(address(amm), amountIn), "APPROVE");

        amountOut = amm.swapExact0For1(amountIn, msg.sender);
        require(amountOut >= amountOutMin, "SLIPPAGE");
    }
}
