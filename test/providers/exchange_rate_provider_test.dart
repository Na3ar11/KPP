import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tracker_costs/providers/exchange_rate_provider.dart';
import 'package:tracker_costs/repositories/exchange_rate_repository.dart';

class _MockExchangeRateRepository extends Mock implements ExchangeRateRepository {}

void main() {
  group('ExchangeRateProvider (AAA)', () {
    late _MockExchangeRateRepository repository;
    late ExchangeRateProvider provider;

    setUp(() {
      repository = _MockExchangeRateRepository();
      provider = ExchangeRateProvider(repository: repository);
    });

    test('refreshRates успішно оновлює rates і lastUpdated', () async {
      // Arrange
      when(() => repository.fetchUahPerCurrencyRates())
          .thenAnswer((_) async => {'UAH': 1.0, 'USD': 42.0, 'EUR': 45.0});

      // Act
      await provider.refreshRates();

      // Assert
      expect(provider.isLoading, isFalse);
      expect(provider.error, isNull);
      expect(provider.rates['USD'], 42.0);
      expect(provider.lastUpdated, isNotNull);
    });

    test('refreshRates зберігає помилку якщо репозиторій падає', () async {
      // Arrange
      when(() => repository.fetchUahPerCurrencyRates())
          .thenThrow(Exception('network'));

      // Act
      await provider.refreshRates();

      // Assert
      expect(provider.isLoading, isFalse);
      expect(provider.error, contains('Exception: network'));
    });
  });
}
