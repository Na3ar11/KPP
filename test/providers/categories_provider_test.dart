import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tracker_costs/models/category.dart';
import 'package:tracker_costs/providers/categories_provider.dart';
import 'package:tracker_costs/repositories/categories_repository.dart';

class _MockCategoriesRepository extends Mock implements CategoriesRepository {}

class _FakeUser extends Fake implements User {}

Category _category(String id, {double monthlyBudget = 100}) {
  return Category(
    id: id,
    userId: 'u1',
    name: 'C$id',
    icon: 'I',
    colorValue: 1,
    monthlyBudget: monthlyBudget,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );
}

void main() {
  group('CategoriesProvider (AAA)', () {
    late _MockCategoriesRepository repository;

    setUpAll(() {
      registerFallbackValue(_category('fallback'));
      registerFallbackValue(_FakeUser());
    });

    setUp(() {
      repository = _MockCategoriesRepository();
    });

    test('initialize показує помилку коли user не авторизований', () async {
      // Arrange
      final auth = MockFirebaseAuth(signedIn: false);
      final provider = CategoriesProvider(repository: repository, auth: auth);

      // Act
      await provider.initialize();

      // Assert
      expect(provider.categories, isEmpty);
      expect(provider.errorMessage, contains('не авторизований'));
    });

    test('initialize підписується на стрім і рахує totalBudget', () async {
      // Arrange
      final stream = StreamController<List<Category>>();
      final auth = MockFirebaseAuth(
        mockUser: MockUser(uid: 'u1', email: 'u1@test.com'),
        signedIn: true,
      );
      when(() => repository.ensureDefaultCategories('u1')).thenAnswer((_) async {});
      when(() => repository.getCategoriesStream('u1', includeArchived: false))
          .thenAnswer((_) => stream.stream);
      final provider = CategoriesProvider(repository: repository, auth: auth);

      // Act
      await provider.initialize();
      stream.add([_category('1', monthlyBudget: 10), _category('2', monthlyBudget: 40)]);
      await Future<void>.delayed(Duration.zero);

      // Assert
      expect(provider.isLoading, isFalse);
      expect(provider.categories.length, 2);
      expect(provider.totalBudget, 50);
      verify(() => repository.ensureDefaultCategories('u1')).called(1);
      await stream.close();
    });

    test('deleteCategory блокує видалення системної категорії', () async {
      // Arrange
      final auth = MockFirebaseAuth(
        mockUser: MockUser(uid: 'u1', email: 'u1@test.com'),
        signedIn: true,
      );
      final provider = CategoriesProvider(repository: repository, auth: auth);
      final systemCategory = _category('u1_cat_food');

      // Act
      final act = provider.deleteCategory(systemCategory);

      // Assert
      await expectLater(act, throwsA(isA<Exception>()));
      verifyNever(() => repository.deleteCategory(any()));
    });
  });
}
