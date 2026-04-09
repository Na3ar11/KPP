import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:tracker_costs/models/expense.dart';
import 'package:tracker_costs/providers/categories_provider.dart';
import 'package:tracker_costs/providers/firestore_expenses_provider.dart';
import 'package:tracker_costs/repositories/categories_repository.dart';
import 'package:tracker_costs/repositories/expenses_repository.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Integration flows', () {
    testWidgets('CategoriesProvider + FirestoreCategoriesRepository archive/restore flow', (
      tester,
    ) async {
      // Arrange
      final firestore = FakeFirebaseFirestore();
      final auth = MockFirebaseAuth(
        mockUser: MockUser(uid: 'u1', email: 'u1@test.com'),
        signedIn: true,
      );
      final repository = FirestoreCategoriesRepository(firestore: firestore);
      final provider = CategoriesProvider(repository: repository, auth: auth);

      // Act
      await provider.initialize();
      await provider.addCategory(
        name: 'Хобі',
        icon: '🎸',
        colorValue: 0xFF123456,
        monthlyBudget: 900,
      );
      await tester.pumpAndSettle();

      final added = provider.categories.firstWhere((c) => c.name == 'Хобі');
      await provider.archiveCategory(added.id);
      await tester.pumpAndSettle();

      final hiddenAfterArchive = provider.categories.any((c) => c.id == added.id);

      await provider.setIncludeArchived(true);
      await tester.pumpAndSettle();

      final archivedVisible = provider.categories.firstWhere((c) => c.id == added.id);
      await provider.restoreCategory(archivedVisible.id);
      await provider.setIncludeArchived(false);
      await tester.pumpAndSettle();

      // Assert
      expect(hiddenAfterArchive, isFalse);
      expect(provider.categories.any((c) => c.id == added.id), isTrue);
      expect(provider.totalBudget, greaterThan(0));
    });

    testWidgets('FirestoreExpensesProvider + repository stream and statistics flow', (
      tester,
    ) async {
      // Arrange
      final firestore = FakeFirebaseFirestore();
      final auth = MockFirebaseAuth(
        mockUser: MockUser(uid: 'u1', email: 'u1@test.com'),
        signedIn: true,
      );
      final repository = FirestoreExpensesRepository(firestore: firestore);
      final provider = FirestoreExpensesProvider(repository: repository, auth: auth);

      // Act
      await repository.addExpense(
        _expense('a', 'u1', 'Їжа', 120, DateTime(2026, 4, 8)),
      );
      await repository.addExpense(
        _expense('b', 'u1', 'Транспорт', 80, DateTime(2026, 4, 9)),
      );

      await provider.initializeExpenses();
      await tester.pumpAndSettle();

      final stats = await provider.getCategoryStatistics(
        DateTime(2026, 4, 1),
        DateTime(2026, 4, 30, 23, 59, 59),
      );

      // Assert
      expect(provider.totalAmount, 200);
      expect(stats['Їжа'], 120);
      expect(stats['Транспорт'], 80);
    });
  });
}

Expense _expense(String id, String userId, String category, double amount, DateTime date) {
  return Expense(
    id: id,
    userId: userId,
    icon: '💰',
    category: category,
    description: 'integration',
    amount: amount,
    color: const Color(0xFF000001),
    date: date,
  );
}
