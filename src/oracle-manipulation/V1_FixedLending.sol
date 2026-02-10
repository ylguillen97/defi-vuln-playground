// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20Mock} from "../common/ERC20Mock.sol";

interface IOracle {
    function spotPriceDebtPerCol() external view returns (uint256);
}

/// @title V1_FixedLending
/// @notice Fixed: collateral valuation comes from an oracle not directly manipulable via AMM swaps.
contract V1_FixedLending {
    ERC20Mock public immutable COL;
    ERC20Mock public immutable DEBT;
    IOracle public immutable ORACLE;

    uint256 public immutable LTV;

    mapping(address => uint256) public collateralOf;
    mapping(address => uint256) public debtOf;

    event Deposited(address indexed user, uint256 colAmount);
    event Borrowed(address indexed user, uint256 debtAmount);

    constructor(address col_, address debt_, address oracle_, uint256 ltv_) {
        require(ltv_ <= 1e18, "LTV");
        COL = ERC20Mock(col_);
        DEBT = ERC20Mock(debt_);
        ORACLE = IOracle(oracle_);
        LTV = ltv_;
    }

    function depositCollateral(uint256 colAmount) external {
        require(colAmount > 0, "ZERO");
        require(COL.transferFrom(msg.sender, address(this), colAmount), "COL TF");
        collateralOf[msg.sender] += colAmount;
        emit Deposited(msg.sender, colAmount);
    }

    function maxBorrowable(address user) public view returns (uint256) {
        uint256 price = ORACLE.spotPriceDebtPerCol(); // stable source
        uint256 valueInDebt = (collateralOf[user] * price) / 1e18;
        return (valueInDebt * LTV) / 1e18;
    }

    function borrow(uint256 debtAmount) external {
        require(debtAmount > 0, "ZERO");
        uint256 maxB = maxBorrowable(msg.sender);
        require(debtOf[msg.sender] + debtAmount <= maxB, "EXCEEDS_MAX");

        debtOf[msg.sender] += debtAmount;
        require(DEBT.transfer(msg.sender, debtAmount), "DEBT T");

        emit Borrowed(msg.sender, debtAmount);
    }
}
