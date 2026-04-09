import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tracker_costs/repositories/auth_repository.dart';

class _MockFirebaseAnalytics extends Mock implements FirebaseAnalytics {}

void main() {
  group('AuthRepository (AAA)', () {
    late _MockFirebaseAnalytics analytics;

    setUp(() {
      analytics = _MockFirebaseAnalytics();
    });

    test('isGoogleSignInAvailable завжди true', () {
      // Arrange
      final auth = MockFirebaseAuth();
      final repository = AuthRepository.forTest(
        firebaseAuth: auth,
        analytics: analytics,
      );

      // Act
      final isAvailable = repository.isGoogleSignInAvailable;

      // Assert
      expect(isAvailable, isTrue);
    });

    test('userName повертає displayName якщо він заповнений', () {
      // Arrange
      final auth = MockFirebaseAuth(
        mockUser: MockUser(
          uid: 'u1',
          email: 'user@example.com',
          displayName: 'Nazarii',
        ),
        signedIn: true,
      );
      final repository = AuthRepository.forTest(
        firebaseAuth: auth,
        analytics: analytics,
      );

      // Act
      final userName = repository.userName;

      // Assert
      expect(userName, 'Nazarii');
    });

    test('userName fallback на локальну частину email якщо displayName порожній', () {
      // Arrange
      final auth = MockFirebaseAuth(
        mockUser: MockUser(
          uid: 'u1',
          email: 'finance.user@domain.com',
          displayName: '',
        ),
        signedIn: true,
      );
      final repository = AuthRepository.forTest(
        firebaseAuth: auth,
        analytics: analytics,
      );

      // Act
      final userName = repository.userName;

      // Assert
      expect(userName, 'finance.user');
    });

    test('userName повертає дефолт якщо користувач не залогінений', () {
      // Arrange
      final auth = MockFirebaseAuth(signedIn: false);
      final repository = AuthRepository.forTest(
        firebaseAuth: auth,
        analytics: analytics,
      );

      // Act
      final userName = repository.userName;

      // Assert
      expect(userName, 'Користувач');
    });
  });
}
