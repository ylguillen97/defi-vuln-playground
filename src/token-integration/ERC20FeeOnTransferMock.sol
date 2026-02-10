// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20Mock} from "../common/ERC20Mock.sol";

/// @notice ERC20 mock with fee-on-transfer (fee is burned).
/// @dev Fee is in basis points (bps). 1000 bps = 10%.
contract ERC20FeeOnTransferMock is ERC20Mock {
    uint256 public immutable FEE_BPS;

    constructor(string memory name_, string memory symbol_, uint256 feeBps_) ERC20Mock(name_, symbol_) {
        require(feeBps_ <= 2000, "fee too high"); // keep it sane
        FEE_BPS = feeBps_;
    }

    function _transfer(address from, address to, uint256 amount) internal override {
        require(balanceOf[from] >= amount, "BAL");

        uint256 fee = (amount * FEE_BPS) / 10_000;
        uint256 received = amount - fee;

        balanceOf[from] -= amount;
        balanceOf[to] += received;

        // burn fee
        if (fee > 0) {
            totalSupply -= fee;
            emit Transfer(from, address(0), fee);
        }

        emit Transfer(from, to, received);
    }
}
