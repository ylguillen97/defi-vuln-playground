// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Errors} from "../common/Errors.sol";

/// @title V1_UnprotectedInitializer
/// @notice Intentionally vulnerable "initializable" contract.
/// @dev BUG: initialize() can be called by anyone at any time.
contract V1_UnprotectedInitializer {
    address public owner;
    bool public initialized;

    event Initialized(address indexed owner);
    event Swept(address indexed to, uint256 amount);

    receive() external payable {}

    function initialize(address owner_) external {
        // VULNERABLE: no "onlyOnce", no access control
        owner = owner_;
        initialized = true;
        emit Initialized(owner_);
    }

    function sweep(address payable to) external {
        if (msg.sender != owner) revert Errors.Unauthorized();
        uint256 amount = address(this).balance;
        (bool ok, ) = to.call{value: amount}("");
        require(ok, "ETH_SEND_FAIL");
        emit Swept(to, amount);
    }
}
