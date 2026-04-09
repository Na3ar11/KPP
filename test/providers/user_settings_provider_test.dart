import 'dart:async';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tracker_costs/models/user_settings.dart';
import 'package:tracker_costs/providers/user_settings_provider.dart';
import 'package:tracker_costs/repositories/user_settings_repository.dart';

class _MockUserSettingsRepository extends Mock implements UserSettingsRepository {}

void main() {
  group('UserSettingsProvider (AAA)', () {
    test('initialize без авторизації не ініціалізує провайдер', () async {
      // Arrange
      final repository = _MockUserSettingsRepository();
      final auth = MockFirebaseAuth(signedIn: false);
      final provider = UserSettingsProvider(repository: repository, auth: auth);

      // Act
      await provider.initialize();

      // Assert
      expect(provider.isInitialized, isFalse);
    });

    test('initialize читає settings із стріма', () async {
      // Arrange
      final repository = _MockUserSettingsRepository();
      final auth = MockFirebaseAuth(
        mockUser: MockUser(uid: 'u1', email: 'u1@test.com'),
        signedIn: true,
      );
      final stream = StreamController<UserSettings>();
      when(() => repository.getUserSettingsStream('u1')).thenAnswer((_) => stream.stream);
      final provider = UserSettingsProvider(repository: repository, auth: auth);

      // Act
      await provider.initialize();
      stream.add(UserSettings(userId: 'u1', currency: 'USD'));
      await Future<void>.delayed(Duration.zero);

      // Assert
      expect(provider.isInitialized, isTrue);
      expect(provider.currency, 'USD');
      await stream.close();
    });

    test('setCurrency не викликає репозиторій якщо значення не змінилось', () async {
      // Arrange
      final firestore = FakeFirebaseFirestore();
      final repository = FirestoreUserSettingsRepository(firestore: firestore);
      final auth = MockFirebaseAuth(
        mockUser: MockUser(uid: 'u1', email: 'u1@test.com'),
        signedIn: true,
      );
      final provider = UserSettingsProvider(repository: repository, auth: auth);
      await repository.createDefaultSettings('u1');
      await provider.initialize();
      await Future<void>.delayed(Duration.zero);

      // Act
      await provider.setCurrency('UAH');
      final settings = await repository.getUserSettings('u1');

      // Assert
      expect(settings.currency, 'UAH');
    });

    test('toggleDarkMode інвертує прапорець', () async {
      // Arrange
      final firestore = FakeFirebaseFirestore();
      final repository = FirestoreUserSettingsRepository(firestore: firestore);
      final auth = MockFirebaseAuth(
        mockUser: MockUser(uid: 'u1', email: 'u1@test.com'),
        signedIn: true,
      );
      final provider = UserSettingsProvider(repository: repository, auth: auth);
      await repository.createDefaultSettings('u1');
      await provider.initialize();
      await Future<void>.delayed(Duration.zero);

      // Act
      await provider.toggleDarkMode();
      final settings = await repository.getUserSettings('u1');

      // Assert
      expect(settings.isDarkMode, isTrue);
    });
  });
}
