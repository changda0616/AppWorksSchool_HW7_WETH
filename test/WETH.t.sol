// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import {WETH} from "../../src/WETH.sol";

// 測項 1: deposit 應該將與 msg.value 相等的 ERC20 token mint 給 user
// 測項 2: deposit 應該將 msg.value 的 ether 轉入合約
// 測項 3: deposit 應該要 emit Deposit event
// 測項 4: withdraw 應該要 burn 掉與 input parameters 一樣的 erc20 token
// 測項 5: withdraw 應該將 burn 掉的 erc20 換成 ether 轉給 user
// 測項 6: withdraw 應該要 emit Withdraw event
// 測項 7: transfer 應該要將 erc20 token 轉給別人
// 測項 8: approve 應該要給他人 allowance
// 測項 9: transferFrom 應該要可以使用他人的 allowance
// 測項 10: transferFrom 後應該要減除用完的 allowance
// 其他可以 test case 可以自己想，看完整程度給分

contract WETHTest is Test {
    WETH instance;
    address user1;
    address user2;

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 amount
    );
    event Deposit(address indexed sender, uint256 amount);
    event Withdraw(address indexed receiver, uint256 amount);

    function setUp() public {
        user1 = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
        user2 = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8;
        instance = new WETH();
        vm.label(user1, "bob");
        vm.label(user2, "alice");
    }

    function testDeposit() public {
        vm.startPrank(user1);
        vm.deal(user1, 1 ether);
        vm.expectEmit(true, false, false, false);
        emit Deposit(user1, 1 ether); // 選項 3
        instance.deposit{value: 1 ether}();
        assertEq(instance.balanceOf(user1), 1 ether); // 選項 1
        assertEq(address(instance).balance, 1 ether); // 選項 2
        assertEq(instance.totalSupply(), 1 ether);
    }

    function testWithdraw() public {
        vm.startPrank(user1);
        deal(address(instance), 1 ether); // 1 Eth to WETH
        deal(address(instance), user1, 1 ether, true); // 1 WETH to user1
        assertEq(user1.balance, 0);
        assertEq(address(instance).balance, 1 ether);
        assertEq(instance.totalSupply(), 1 ether);
        assertEq(instance.balanceOf(user1), 1 ether);
        vm.expectEmit(true, false, false, false);
        emit Withdraw(user1, 1 ether); // 選項 6
        instance.withdraw(1 ether);
        assertEq(instance.totalSupply(), 0); // 選項 4
        assertEq(user1.balance, 1 ether); // 選項 5
    }

    function testTransfer() public {
        vm.startPrank(user1);
        deal(address(instance), user1, 1 ether, true);

        vm.expectEmit(true, true, false, false);
        emit Transfer(user1, user2, 0.4 ether);

        instance.transfer(user2, 0.4 ether);

        assertEq(instance.balanceOf(user1), 0.6 ether);
        assertEq(instance.balanceOf(user2), 0.4 ether); // 選項 7
    }

    function testApprove() public {
        vm.startPrank(user1);
        instance.approve(user2, 100 gwei);
        assertEq(instance.allowance(user1, user2), 100 gwei); // 選項 8
    }

    function testTransferFrom() public {
        vm.startPrank(user1);
        deal(address(instance), user1, 1 ether, true);
        instance.approve(user2, 1 ether);
        assertEq(instance.allowance(user1, user2), 1 ether);

        changePrank(user2);
        vm.expectEmit(true, true, false, false);
        emit Transfer(user1, user2, 1 ether);

        instance.transferFrom(user1, user2, 1 ether);

        assertEq(instance.balanceOf(user2), 1 ether); // 選項 9
        assertEq(instance.allowance(user1, user2), 0 ether); // 選項 10
    }

    // extra
    function testReceive() public {
        vm.startPrank(user1);
        vm.deal(user1, 1 ether);
        vm.expectEmit(true, false, false, false);
        emit Deposit(user1, 1 ether);
        (bool result, ) = address(instance).call{value: 1 ether}("");
        assertEq(result, true);
        assertEq(instance.balanceOf(user1), 1 ether);
        assertEq(address(instance).balance, 1 ether);
    }

    function testDepositZeroAmount() public {
        vm.startPrank(user1);
        vm.expectRevert("Should deposit ETH");
        instance.deposit{value: 0}();
    }

    function testTransferInsufficientBalance() public {
        vm.startPrank(user1);
        // TODO: seems can't this with vm.deal, need to go through the source to figure out
        deal(address(instance), user1, 1 ether, true);
        vm.expectRevert("Insufficient balance");
        instance.transfer(user2, 2 ether);
    }

    function testTransferFromInsufficientAllowance() public {
        vm.startPrank(user1);
        deal(address(instance), user1, 1 ether, true);
        instance.approve(user2, 0.5 ether);
        vm.expectRevert("Insufficient allowance");
        changePrank(user2);
        instance.transferFrom(user1, user2, 0.6 ether);
    }

    function testBurnInsufficientBalance() public {
        vm.startPrank(user1);
        deal(address(instance), 1 ether);
        deal(address(instance), user1, 1 ether, true);
        vm.expectRevert("Insufficient balance");
        instance.burn(2 ether);
    }

    function testWithdrawToContractAccount() public {
        address mockContract = address(1);
        deal(mockContract, 1 ether);
        deal(address(instance), mockContract, 1 ether, true);
        vm.etch(mockContract, "");
        vm.startPrank(mockContract);
        vm.expectRevert("ETH transfer fail");
        instance.withdraw(1 ether);
    }
}

// Test result: ok. 11 passed; 0 failed; finished in 1.37ms
// | src/WETH.sol:WETH contract |                 |       |        |       |         |
// |----------------------------|-----------------|-------|--------|-------|---------|
// | Deployment Cost            | Deployment Size |       |        |       |         |
// | 657442                     | 3439            |       |        |       |         |
// | Function Name              | min             | avg   | median | max   | # calls |
// | allowance                  | 781             | 781   | 781    | 781   | 3       |
// | approve                    | 24523           | 24523 | 24523  | 24523 | 3       |
// | balanceOf                  | 564             | 1082  | 564    | 2564  | 27      |
// | burn                       | 572             | 572   | 572    | 572   | 1       |
// | deposit                    | 327             | 23225 | 23225  | 46124 | 2       |
// | receive                    | 45991           | 45991 | 45991  | 45991 | 1       |
// | totalSupply                | 340             | 923   | 340    | 2340  | 24      |
// | transfer                   | 695             | 12935 | 12935  | 25176 | 2       |
// | transferFrom               | 1089            | 10982 | 10982  | 20876 | 2       |
// | withdraw                   | 6567            | 17098 | 17098  | 27629 | 2       |