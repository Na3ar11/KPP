import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tracker_costs/models/expense.dart';
import 'package:tracker_costs/repositories/expenses_repository.dart';

Expense _expense({
  required String id,
  required String userId,
  required String category,
  required double amount,
  required DateTime date,
}) {
  return Expense(
    id: id,
    userId: userId,
    icon: '💰',
    category: category,
    description: 'desc',
    amount: amount,
    color: const Color(0xFF000001),
    date: date,
  );
}

void main() {
  group('FirestoreExpensesRepository (AAA)', () {
    late FakeFirebaseFirestore firestore;
    late FirestoreExpensesRepository repository;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      repository = FirestoreExpensesRepository(firestore: firestore);
    });

    test('add/get/update/delete expense', () async {
      // Arrange
      final now = DateTime(2026, 4, 8);
      final expense = _expense(
        id: 'local',
        userId: 'u1',
        category: 'Їжа',
        amount: 100,
        date: now,
      );

      // Act
      final id = await repository.addExpense(expense);
      final found = await repository.getExpenseById(id);
      await repository.updateExpense(found!.copyWith(description: 'updated'));
      final updated = await repository.getExpenseById(id);
      await repository.deleteExpense(id);
      final deleted = await repository.getExpenseById(id);

      // Assert
      expect(found, isNotNull);
      expect(updated?.description, 'updated');
      expect(deleted, isNull);
    });

    test('getExpensesByDateRange повертає витрати на межах діапазону', () async {
      // Arrange
      final start = DateTime(2026, 4, 1);
      final end = DateTime(2026, 4, 30, 23, 59, 59);
      await repository.addExpense(_expense(
        id: 'a',
        userId: 'u1',
        category: 'Їжа',
        amount: 10,
        date: start,
      ));
      await repository.addExpense(_expense(
        id: 'b',
        userId: 'u1',
        category: 'Їжа',
        amount: 20,
        date: end,
      ));
      await repository.addExpense(_expense(
        id: 'c',
        userId: 'u1',
        category: 'Їжа',
        amount: 30,
        date: DateTime(2026, 5, 1),
      ));

      // Act
      final items = await repository.getExpensesByDateRange('u1', start, end);

      // Assert
      expect(items.length, 2);
      expect(items.map((e) => e.amount).toSet(), {10.0, 20.0});
    });

    test('getExpensesByCategory і getTotalAmount повертають коректні значення', () async {
      // Arrange
      final start = DateTime(2026, 4, 1);
      final end = DateTime(2026, 4, 30, 23, 59, 59);
      await repository.addExpense(_expense(
        id: 'a',
        userId: 'u1',
        category: 'Їжа',
        amount: 10,
        date: DateTime(2026, 4, 8),
      ));
      await repository.addExpense(_expense(
        id: 'b',
        userId: 'u1',
        category: 'Транспорт',
        amount: 25.5,
        date: DateTime(2026, 4, 8),
      ));

      // Act
      final food = await repository.getExpensesByCategory('u1', 'Їжа');
      final total = await repository.getTotalAmount('u1', start, end);
      final stats = await repository.getCategoryStatistics('u1', start, end);

      // Assert
      expect(food.length, 1);
      expect(total, 35.5);
      expect(stats['Їжа'], 10);
      expect(stats['Транспорт'], 25.5);
    });
  });
}
