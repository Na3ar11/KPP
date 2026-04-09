import 'dart:async';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tracker_costs/models/expense.dart';
import 'package:tracker_costs/providers/firestore_expenses_provider.dart' as provider_layer;
import 'package:tracker_costs/repositories/expenses_repository.dart';

class _MockExpensesRepository extends Mock implements ExpensesRepository {}

Expense _expense(String id, double amount, DateTime date) {
  return Expense(
    id: id,
    userId: 'u1',
    icon: '💰',
    category: 'Їжа',
    description: 'd',
    amount: amount,
    color: const Color(0xFF000001),
    date: date,
  );
}

void main() {
  group('FirestoreExpensesProvider (AAA)', () {
    test('initializeExpenses ставить error без авторизації', () async {
      // Arrange
      final repo = _MockExpensesRepository();
      final auth = MockFirebaseAuth(signedIn: false);
      final provider = provider_layer.FirestoreExpensesProvider(
        repository: repo,
        auth: auth,
      );

      // Act
      await provider.initializeExpenses();

      // Assert
      expect(provider.loadingState, provider_layer.LoadingState.error);
      expect(provider.errorMessage, contains('не авторизований'));
    });

    test('initializeExpenses приймає стрім і рахує totalAmount', () async {
      // Arrange
      final repo = _MockExpensesRepository();
      final auth = MockFirebaseAuth(
        mockUser: MockUser(uid: 'u1', email: 'u1@test.com'),
        signedIn: true,
      );
      final stream = StreamController<List<Expense>>();
      when(() => repo.getExpensesStream('u1')).thenAnswer((_) => stream.stream);

      final provider = provider_layer.FirestoreExpensesProvider(
        repository: repo,
        auth: auth,
      );

      // Act
      await provider.initializeExpenses();
      stream.add([_expense('e1', 100, DateTime.now()), _expense('e2', 50, DateTime.now())]);
      await Future<void>.delayed(Duration.zero);

      // Assert
      expect(provider.loadingState, provider_layer.LoadingState.success);
      expect(provider.totalAmount, 150);
      await stream.close();
    });

    test('getCategoryStatistics працює з реальним FirestoreExpensesRepository', () async {
      // Arrange
      final firestore = FakeFirebaseFirestore();
      final repo = FirestoreExpensesRepository(firestore: firestore);
      final auth = MockFirebaseAuth(
        mockUser: MockUser(uid: 'u1', email: 'u1@test.com'),
        signedIn: true,
      );
      final provider = provider_layer.FirestoreExpensesProvider(
        repository: repo,
        auth: auth,
      );
      await repo.addExpense(_expense('a', 20, DateTime(2026, 4, 8)));
      await repo.addExpense(Expense(
        id: 'b',
        userId: 'u1',
        icon: '🚌',
        category: 'Транспорт',
        description: 'd',
        amount: 30,
        color: const Color(0xFF000001),
        date: DateTime(2026, 4, 9),
      ));

      // Act
      final stats = await provider.getCategoryStatistics(
        DateTime(2026, 4, 1),
        DateTime(2026, 4, 30, 23, 59, 59),
      );

      // Assert
      expect(stats['Їжа'], 20);
      expect(stats['Транспорт'], 30);
    });
  });
}
