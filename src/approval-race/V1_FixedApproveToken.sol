// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract V1_FixedApproveToken {
    string public name = "Fixed Token";
    string public symbol = "FIX";
    uint8 public constant decimals = 18;

    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);

    function mint(address to, uint256 amount) external {
        totalSupply += amount;
        balanceOf[to] += amount;
        emit Transfer(address(0), to, amount);
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        //  mitigation: must reset to 0 before changing to a new non-zero
        uint256 current = allowance[msg.sender][spender];
        if (current != 0 && amount != 0) revert("NONZERO_TO_NONZERO");
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 added) external returns (bool) {
        uint256 current = allowance[msg.sender][spender];
        uint256 next = current + added;
        allowance[msg.sender][spender] = next;
        emit Approval(msg.sender, spender, next);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtracted) external returns (bool) {
        uint256 current = allowance[msg.sender][spender];
        require(current >= subtracted, "UNDERFLOW");
        uint256 next = current - subtracted;
        allowance[msg.sender][spender] = next;
        emit Approval(msg.sender, spender, next);
        return true;
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        uint256 allowed = allowance[from][msg.sender];
        require(allowed >= amount, "ALLOW");
        allowance[from][msg.sender] = allowed - amount;
        _transfer(from, to, amount);
        return true;
    }

    function _transfer(address from, address to, uint256 amount) internal {
        require(balanceOf[from] >= amount, "BAL");
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        emit Transfer(from, to, amount);
    }
}
