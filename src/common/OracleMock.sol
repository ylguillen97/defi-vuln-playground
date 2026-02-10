// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @notice Simple fixed-price oracle (Debt per 1 Collateral), 1e18 scaled.
contract OracleMock {
    uint256 public priceDebtPerCol;

    constructor(uint256 initialPrice) {
        priceDebtPerCol = initialPrice;
    }

    function setPrice(uint256 newPrice) external {
        priceDebtPerCol = newPrice;
    }

    function spotPriceDebtPerCol() external view returns (uint256) {
        return priceDebtPerCol;
    }
}