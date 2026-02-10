// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Errors} from "../common/Errors.sol";

/// @title V1_FixedInitializer
/// @notice Fixed: initialize() can only be called once.
/// @dev This is the minimal "initializer" guard pattern.
/// In production, use audited libs (OpenZeppelin Initializable) and ensure proxies are initialized atomically.
contract V1_FixedInitializer {
    address public owner;
    bool public initialized;

    event Initialized(address indexed owner);
    event Swept(address indexed to, uint256 amount);

    receive() external payable {}

    function initialize(address owner_) external {
        // FIX: can only be called once
        require(!initialized, "ALREADY_INITIALIZED");
        require(owner_ != address(0), "OWNER_ZERO");

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
