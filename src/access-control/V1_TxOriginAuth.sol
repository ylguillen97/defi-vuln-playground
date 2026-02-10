// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Errors} from "../common/Errors.sol";

/// @title V1_TxOriginAuth
/// @notice Intentionally vulnerable: authorizes using tx.origin.
/// @dev BUG: tx.origin can be tricked via phishing contracts.
contract V1_TxOriginAuth {
    address public immutable OWNER;

    event Executed(address indexed target, uint256 value, bytes data);

    constructor(address owner_) {
        OWNER = owner_;
    }

    receive() external payable {}

    function execute(address target, uint256 value, bytes calldata data) external returns (bytes memory) {
        //  VULNERABLE: tx.origin-based auth
        if (tx.origin != OWNER) revert Errors.Unauthorized();

        (bool ok, bytes memory ret) = target.call{value: value}(data);
        require(ok, "call failed");

        emit Executed(target, value, data);
        return ret;
    }
}
