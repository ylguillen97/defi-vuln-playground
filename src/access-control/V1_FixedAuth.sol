// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Errors} from "../common/Errors.sol";

/// @title V1_FixedAuth
/// @notice Fixed: authorizes using msg.sender (not tx.origin).
contract V1_FixedAuth {
    address public immutable OWNER;

    event Executed(address indexed target, uint256 value, bytes data);

    constructor(address owner_) {
        OWNER = owner_;
    }

    receive() external payable {}

    function execute(address target, uint256 value, bytes calldata data) external returns (bytes memory) {
        // Correct: msg.sender-based auth
        if (msg.sender != OWNER) revert Errors.Unauthorized();

        (bool ok, bytes memory ret) = target.call{value: value}(data);
        require(ok, "call failed");

        emit Executed(target, value, data);
        return ret;
    }
}
