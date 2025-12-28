// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/Wallet.sol";

contract WalletTest is Test {
    Wallet public wallet;
    address public owner = address(0x123);
    address public nonOwner = address(0x456);
    
    uint256 constant INITIAL_BALANCE = 1 ether;

    function setUp() public {
        vm.deal(owner, 10 ether);
        
        vm.prank(owner);
        wallet = new Wallet();
    }

    function test_InitialState() public {
        assertEq(wallet.owner(), owner);
        assertEq(wallet.testAddress(), 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4);
        assertEq(wallet.getContractBalance(), 0);
        assertEq(wallet.getCurrentBalance(), 0);
    }

    function test_Deposit() public {
        uint256 depositAmount = 1 ether;
        
        vm.deal(address(this), depositAmount);
        
        wallet.deposit{value: depositAmount}();
        
        assertEq(wallet.getCurrentBalance(), depositAmount);
        assertEq(wallet.getContractBalance(), depositAmount);
    }

    function test_Withdraw() public {
        uint256 depositAmount = 1 ether;
        vm.deal(address(this), depositAmount);
        wallet.deposit{value: depositAmount}();

        uint256 withdrawAmount = 0.3 ether;
        uint256 initialContractBalance = wallet.getContractBalance();
        uint256 initialCurrentBalance = wallet.getCurrentBalance();
        uint256 initialOwnerBalance = owner.balance;
        
        vm.prank(owner);
        wallet.withdraw(withdrawAmount);
        
        assertEq(wallet.getContractBalance(), initialContractBalance - withdrawAmount);
        assertEq(wallet.getCurrentBalance(), initialCurrentBalance - withdrawAmount);
        assertEq(owner.balance, initialOwnerBalance + withdrawAmount);
    }

    function test_RevertWhen_NonOwnerTriesToWithdraw() public {
        vm.prank(nonOwner);
        vm.expectRevert("You are not the owner of this contract");
        wallet.withdraw(0.1 ether);
    }
}