// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

contract VulnerableVault {
    mapping(address => uint256) public balances;

    // внос средств
    function deposit() external payable {
        balances[msg.sender] += msg.value;
    }

    function withdraw() external {
        uint256 amount = balances[msg.sender];
        require(amount > 0, "No balance");

        (bool ok, ) = msg.sender.call{value: amount}("");
        require(ok, "Transfer failed");

        balances[msg.sender] = 0;
    }

    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
}