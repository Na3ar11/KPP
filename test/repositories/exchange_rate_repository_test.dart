import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tracker_costs/repositories/exchange_rate_repository.dart';

void main() {
  group('NbuExchangeRateRepository (AAA)', () {
    test('fetchUahPerCurrencyRates парсить валідну відповідь', () async {
      // Arrange
      final client = MockClient((request) async {
        expect(request.url.toString(), contains('bank.gov.ua'));
        return http.Response(
          jsonEncode([
            {'cc': 'usd', 'rate': 41.2},
            {'cc': 'EUR', 'rate': 44.8},
            {'cc': 'pln', 'rate': 10.5},
          ]),
          200,
        );
      });
      final repository = NbuExchangeRateRepository(httpClient: client);

      // Act
      final rates = await repository.fetchUahPerCurrencyRates();

      // Assert
      expect(rates['UAH'], 1.0);
      expect(rates['USD'], 41.2);
      expect(rates['EUR'], 44.8);
      expect(rates['PLN'], 10.5);
    });

    test('fetchUahPerCurrencyRates кидає помилку для non-200', () async {
      // Arrange
      final client = MockClient((_) async => http.Response('error', 500));
      final repository = NbuExchangeRateRepository(httpClient: client);

      // Act
      final act = repository.fetchUahPerCurrencyRates;

      // Assert
      await expectLater(act(), throwsA(isA<Exception>()));
    });

    test('fetchUahPerCurrencyRates кидає помилку коли формат не List', () async {
      // Arrange
      final client = MockClient((_) async => http.Response(jsonEncode({'x': 1}), 200));
      final repository = NbuExchangeRateRepository(httpClient: client);

      // Act
      final act = repository.fetchUahPerCurrencyRates;

      // Assert
      await expectLater(act(), throwsA(isA<Exception>()));
    });

    test('fetchUahPerCurrencyRates фільтрує вразливі/невалідні значення rate', () async {
      // Arrange
      final client = MockClient((_) async {
        return http.Response(
          jsonEncode([
            {'cc': 'USD', 'rate': 41.2},
            {'cc': 'EUR', 'rate': 44.8},
            {'cc': 'BTC', 'rate': 0},
            {'cc': 'ETH', 'rate': -1},
            {'cc': '', 'rate': 1.0},
            {'cc': null, 'rate': 1.0},
            {'cc': 'JPY', 'rate': 'not-num'},
          ]),
          200,
        );
      });
      final repository = NbuExchangeRateRepository(httpClient: client);

      // Act
      final rates = await repository.fetchUahPerCurrencyRates();

      // Assert
      expect(rates.containsKey('BTC'), isFalse);
      expect(rates.containsKey('ETH'), isFalse);
      expect(rates.containsKey('JPY'), isFalse);
      expect(rates['USD'], 41.2);
      expect(rates['EUR'], 44.8);
    });

    test('fetchUahPerCurrencyRates кидає помилку якщо відсутній USD/EUR', () async {
      // Arrange
      final client = MockClient((_) async {
        return http.Response(
          jsonEncode([
            {'cc': 'GBP', 'rate': 50.0},
          ]),
          200,
        );
      });
      final repository = NbuExchangeRateRepository(httpClient: client);

      // Act
      final act = repository.fetchUahPerCurrencyRates;

      // Assert
      await expectLater(act(), throwsA(isA<Exception>()));
    });
  });
}
