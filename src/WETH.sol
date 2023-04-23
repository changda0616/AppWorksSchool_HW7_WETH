// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IWETH9 {
    function deposit() external payable;

    function withdraw(uint256 amount) external;
}

contract WETH is IWETH9 {
    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 amount
    );
    event Deposit(address indexed sender, uint256 amount);

    event Withdraw(address indexed receiver, uint256 amount);

    uint256 public decimals = 18;
    uint256 public totalSupply;

    string public name = "WETH";
    string public symbol = "WETH";
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    function deposit() external payable {
        uint256 amount = msg.value;
        require(amount != 0, "Should deposit ETH");
        totalSupply += amount;
        balanceOf[msg.sender] += amount;
        emit Deposit(msg.sender, amount);
    }

    function withdraw(uint256 amount) external {
        require(balanceOf[msg.sender] >= amount, "Insufficient balance");
        balanceOf[msg.sender] -= amount;
        totalSupply -= amount;
        (bool result, ) = payable(msg.sender).call{value: amount}("");
        // if failed, return the remained gas and revert the status, OpCode -> 0xfd
        require(result, "ETH transfer fail");
        emit Withdraw(msg.sender, amount);
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transfer(
        address receipent,
        uint256 amount
    ) external returns (bool) {
        require(balanceOf[msg.sender] >= amount, "Insufficient balance");
        balanceOf[msg.sender] -= amount;
        balanceOf[receipent] += amount;
        emit Transfer(msg.sender, receipent, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address receipent,
        uint256 amount
    ) external returns (bool) {
        uint256 allowanceAmount = allowance[sender][msg.sender];
        require(balanceOf[sender] >= amount, "Insufficient balance");
        require(allowanceAmount >= amount, "Insufficient allowance");
        balanceOf[sender] -= amount;
        balanceOf[receipent] += amount;
        allowance[sender][msg.sender] -= amount;
        emit Transfer(sender, receipent, amount);
        return true;
    }

    receive() external payable {
        uint256 amount = msg.value;
        require(amount != 0, "Should send ETH");
        totalSupply += amount;
        balanceOf[msg.sender] += amount;
        emit Deposit(msg.sender, amount);
    }

    // Extra
    function mint(uint256 amount) external {
        balanceOf[msg.sender] += amount;
        totalSupply += amount;
        emit Transfer(address(0), msg.sender, amount);
    }

    function burn(uint256 amount) external {
        require(balanceOf[msg.sender] >= amount, "Insufficient balance");
        balanceOf[msg.sender] -= amount;
        totalSupply -= amount;
        emit Transfer(msg.sender, address(0), amount);
    }
}
