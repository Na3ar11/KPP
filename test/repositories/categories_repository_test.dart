import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tracker_costs/models/category.dart';
import 'package:tracker_costs/repositories/categories_repository.dart';

void main() {
  group('FirestoreCategoriesRepository (AAA)', () {
    late FakeFirebaseFirestore firestore;
    late FirestoreCategoriesRepository repository;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      repository = FirestoreCategoriesRepository(firestore: firestore);
    });

    test('ensureDefaultCategories створює дефолтні категорії один раз', () async {
      // Arrange
      const userId = 'user-1';

      // Act
      await repository.ensureDefaultCategories(userId);
      await repository.ensureDefaultCategories(userId);
      final docs = await firestore
          .collection('categories')
          .where('userId', isEqualTo: userId)
          .get();

      // Assert
      expect(docs.docs.length, 7);
    });

    test('addCategory/updateCategory/deleteCategory працюють послідовно', () async {
      // Arrange
      final category = Category(
        id: 'ignored',
        userId: 'u1',
        name: 'Тест',
        icon: 'T',
        colorValue: 0xFF000001,
        monthlyBudget: 1234.56,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      // Act
      final id = await repository.addCategory(category);
      await repository.updateCategory(category.copyWith(id: id, name: 'Оновлено'));
      final updated = await firestore.collection('categories').doc(id).get();
      await repository.deleteCategory(id);
      final deleted = await firestore.collection('categories').doc(id).get();

      // Assert
      expect(updated.data()?['name'], 'Оновлено');
      expect(deleted.exists, isFalse);
    });

    test('archiveCategory/restoreCategory змінюють isArchived', () async {
      // Arrange
      final ref = await firestore.collection('categories').add({
        'userId': 'u1',
        'name': 'Їжа',
        'icon': '🍕',
        'colorValue': 1,
        'monthlyBudget': 100.0,
        'isArchived': false,
        'createdAt': DateTime(2026, 1, 1),
        'updatedAt': DateTime(2026, 1, 1),
      });

      // Act
      await repository.archiveCategory(ref.id, 'u1');
      final archived = await ref.get();
      await repository.restoreCategory(ref.id, 'u1');
      final restored = await ref.get();

      // Assert
      expect(archived.data()?['isArchived'], isTrue);
      expect(restored.data()?['isArchived'], isFalse);
    });

    test('getCategoriesStream exclude archived by default', () async {
      // Arrange
      await firestore.collection('categories').doc('1').set({
        'userId': 'u1',
        'name': 'A',
        'icon': 'A',
        'colorValue': 1,
        'monthlyBudget': 1.0,
        'isArchived': false,
        'createdAt': DateTime(2026, 1, 1),
        'updatedAt': DateTime(2026, 1, 1),
      });
      await firestore.collection('categories').doc('2').set({
        'userId': 'u1',
        'name': 'B',
        'icon': 'B',
        'colorValue': 1,
        'monthlyBudget': 1.0,
        'isArchived': true,
        'createdAt': DateTime(2026, 1, 2),
        'updatedAt': DateTime(2026, 1, 2),
      });

      // Act
      final result = await repository.getCategoriesStream('u1').first;

      // Assert
      expect(result.map((c) => c.id), ['1']);
    });
  });
}
