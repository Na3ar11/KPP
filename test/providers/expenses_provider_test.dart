import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tracker_costs/models/expense.dart';
import 'package:tracker_costs/providers/expenses_provider.dart';

Expense _expense(String id, double amount) {
  return Expense(
    id: id,
    userId: 'u1',
    icon: '💰',
    category: 'Їжа',
    description: 'd',
    amount: amount,
    color: const Color(0xFF000001),
    date: DateTime.now(),
  );
}

void main() {
  group('ExpensesProvider (AAA)', () {
    late ExpensesProvider provider;

    setUp(() {
      provider = ExpensesProvider();
    });

    test('setBudget оновлює бюджет і balance', () {
      // Arrange
      provider.setBudget(2000);

      // Act
      final balance = provider.balance;

      // Assert
      expect(provider.budget, 2000);
      expect(balance, 2000);
    });

    test('loadExpenses завантажує mock дані і переводить стан в success', () async {
      // Arrange
      expect(provider.loadingState, LoadingState.idle);

      // Act
      await provider.loadExpenses();

      // Assert
      expect(provider.loadingState, LoadingState.success);
      expect(provider.expenses, isNotEmpty);
      expect(provider.totalAmount, greaterThan(0));
    });

    test('add/update/delete витрати працюють послідовно', () async {
      // Arrange
      final expense = _expense('id-1', 120);

      // Act
      await provider.addExpense(expense);
      await provider.updateExpense(expense.copyWith(amount: 150));
      await provider.deleteExpense('id-1');

      // Assert
      expect(provider.expenses.where((e) => e.id == 'id-1'), isEmpty);
    });
  });
}
