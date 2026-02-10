// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20Mock} from "../common/ERC20Mock.sol";

/// @notice Constant product AMM (x*y=k), no fees for simplicity.
contract V1_SimpleAMM {
    ERC20Mock public immutable token0;
    ERC20Mock public immutable token1;

    uint256 public r0;
    uint256 public r1;

    constructor(address t0, address t1) {
        token0 = ERC20Mock(t0);
        token1 = ERC20Mock(t1);
    }

    function addLiquidity(uint256 a0, uint256 a1) external {
        require(a0 > 0 && a1 > 0, "ZERO");
        require(token0.transferFrom(msg.sender, address(this), a0), "TF0");
        require(token1.transferFrom(msg.sender, address(this), a1), "TF1");
        r0 += a0;
        r1 += a1;
    }

    /// @notice quote token1 out for token0 in (swap token0 -> token1)
    function quote0To1(uint256 amountIn) public view returns (uint256 amountOut) {
        uint256 k = r0 * r1;
        uint256 newR0 = r0 + amountIn;
        uint256 newR1 = k / newR0;
        amountOut = r1 - newR1;
    }

    function swapExact0For1(uint256 amountIn, address to) external returns (uint256 amountOut) {
        require(token0.transferFrom(msg.sender, address(this), amountIn), "TF0");
        amountOut = quote0To1(amountIn);

        r0 += amountIn;
        r1 -= amountOut;

        require(token1.transfer(to, amountOut), "T1");
    }

    /// @notice quote token0 out for token1 in (swap token1 -> token0)
    function quote1To0(uint256 amountIn) public view returns (uint256 amountOut) {
        uint256 k = r0 * r1;
        uint256 newR1 = r1 + amountIn;
        uint256 newR0 = k / newR1;
        amountOut = r0 - newR0;
    }

    function swapExact1For0(uint256 amountIn, address to) external returns (uint256 amountOut) {
        require(token1.transferFrom(msg.sender, address(this), amountIn), "TF1");
        amountOut = quote1To0(amountIn);

        r1 += amountIn;
        r0 -= amountOut;

        require(token0.transfer(to, amountOut), "T0");
    }
}