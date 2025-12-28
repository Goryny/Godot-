// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Wallet {
    address public immutable owner;
    uint private _currentBalance;
    address public testAddress = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;

    constructor() {
        owner = msg.sender;
    }

    function deposit() public payable {
        _currentBalance += msg.value;
    }

    function withdraw(uint amountInWei) public isOwner {
        require(amountInWei <= _currentBalance, "Insufficient contract balance");
        require(amountInWei <= address(this).balance, "Insufficient ETH balance");
        payable(owner).transfer(amountInWei);
        _currentBalance -= amountInWei;
    }

    function withdrawAllMoney() public isOwner {
        uint balanceToWithdraw = _currentBalance;
        require(balanceToWithdraw <= address(this).balance, "Insufficient ETH balance");
        payable(owner).transfer(balanceToWithdraw);
        _currentBalance = 0;
    }

    function sendMoneyTo(address payable to, uint amountInWei) public isOwner {
        require(amountInWei <= _currentBalance, "Insufficient contract balance");
        require(amountInWei <= address(this).balance, "Insufficient ETH balance");
        to.transfer(amountInWei);
        _currentBalance -= amountInWei;
    }

    function returnCurrentBalance() public view isOwner returns (uint) {
        return _currentBalance;
    }

    function getContractBalance() public view returns (uint) {
        return address(this).balance;
    }

    modifier isOwner() {
        require(msg.sender == owner, "You are not the owner of this contract");
        _;
    }

    function getCurrentBalance() public view returns (uint) {
        return _currentBalance;
    }
}