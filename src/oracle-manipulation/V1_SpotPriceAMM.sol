// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20Mock} from "../common/ERC20Mock.sol";

/// @title V1_SpotPriceAMM
/// @notice Minimal constant-product AMM used as a manipulable spot-price oracle.
/// @dev Price = reserveDebt / reserveCol (scaled 1e18).
contract V1_SpotPriceAMM {
    ERC20Mock public immutable COL;
    ERC20Mock public immutable DEBT;

    uint256 public reserveCol;
    uint256 public reserveDebt;

    event LiquidityAdded(uint256 colIn, uint256 debtIn);
    event Swapped(address indexed trader, address indexed tokenIn, uint256 amountIn, uint256 amountOut);

    constructor(address col_, address debt_) {
        COL = ERC20Mock(col_);
        DEBT = ERC20Mock(debt_);
    }

    function addLiquidity(uint256 colIn, uint256 debtIn) external {
        require(colIn > 0 && debtIn > 0, "ZERO");
        require(COL.transferFrom(msg.sender, address(this), colIn), "COL TF");
        require(DEBT.transferFrom(msg.sender, address(this), debtIn), "DEBT TF");

        reserveCol += colIn;
        reserveDebt += debtIn;

        emit LiquidityAdded(colIn, debtIn);
    }

    /// @notice Spot price: how many DEBT for 1 COL (1e18 scaled)
    function spotPriceDebtPerCol() external view returns (uint256) {
        require(reserveCol > 0, "NO_LIQ");
        return (reserveDebt * 1e18) / reserveCol;
    }

    /// @notice Swap exact DEBT in for COL out (no fee for simplicity).
    function swapExactDebtForCol(uint256 debtIn, uint256 minColOut) external returns (uint256 colOut) {
        require(debtIn > 0, "ZERO");
        require(DEBT.transferFrom(msg.sender, address(this), debtIn), "DEBT TF");

        // x*y=k
        uint256 x = reserveCol;
        uint256 y = reserveDebt;
        uint256 k = x * y;

        uint256 newY = y + debtIn;
        uint256 newX = k / newY;
        colOut = x - newX;

        require(colOut >= minColOut, "SLIPPAGE");
        require(colOut <= reserveCol, "INSUFFICIENT");

        reserveDebt = newY;
        reserveCol = newX;

        require(COL.transfer(msg.sender, colOut), "COL T");

        emit Swapped(msg.sender, address(DEBT), debtIn, colOut);
    }

    /// @notice Swap exact COL in for DEBT out (no fee for simplicity).
    function swapExactColForDebt(uint256 colIn, uint256 minDebtOut) external returns (uint256 debtOut) {
        require(colIn > 0, "ZERO");
        require(COL.transferFrom(msg.sender, address(this), colIn), "COL TF");

        uint256 x = reserveCol;
        uint256 y = reserveDebt;
        uint256 k = x * y;

        uint256 newX = x + colIn;
        uint256 newY = k / newX;
        debtOut = y - newY;

        require(debtOut >= minDebtOut, "SLIPPAGE");
        require(debtOut <= reserveDebt, "INSUFFICIENT");

        reserveCol = newX;
        reserveDebt = newY;

        require(DEBT.transfer(msg.sender, debtOut), "DEBT T");

        emit Swapped(msg.sender, address(COL), colIn, debtOut);
    }
}
