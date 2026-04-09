import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tracker_costs/repositories/user_settings_repository.dart';

void main() {
  group('FirestoreUserSettingsRepository (AAA)', () {
    late FakeFirebaseFirestore firestore;
    late FirestoreUserSettingsRepository repository;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      repository = FirestoreUserSettingsRepository(firestore: firestore);
    });

    test('getUserSettings створює дефолтні при відсутності документа', () async {
      // Arrange
      const userId = 'u1';

      // Act
      final settings = await repository.getUserSettings(userId);

      // Assert
      expect(settings.userId, userId);
      expect(settings.currency, 'UAH');
      expect(settings.defaultCategory, 'Їжа');
    });

    test('updateUserSettings виконує merge і не ламає існуючі поля', () async {
      // Arrange
      const userId = 'u1';
      await repository.createDefaultSettings(userId);

      // Act
      await repository.updateCurrency(userId, 'USD');
      final settings = await repository.getUserSettings(userId);

      // Assert
      expect(settings.currency, 'USD');
      expect(settings.defaultCategory, 'Їжа');
    });

    test('updateField оновлює конкретне поле і ставить userId', () async {
      // Arrange
      const userId = 'u2';

      // Act
      await repository.updateField(userId, 'language', 'en');
      final doc = await firestore.collection('userSettings').doc(userId).get();

      // Assert
      expect(doc.data()?['userId'], userId);
      expect(doc.data()?['language'], 'en');
      expect(doc.data()?['updatedAt'], isNotNull);
    });

    test('getUserSettingsStream повертає дефолт якщо doc не існує', () async {
      // Arrange
      const userId = 'u3';

      // Act
      final emitted = await repository.getUserSettingsStream(userId).first;

      // Assert
      expect(emitted.userId, userId);
      expect(emitted.currency, 'UAH');
    });
  });
}
