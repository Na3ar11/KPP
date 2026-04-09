import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tracker_costs/utils/currency_converter.dart';
import 'package:tracker_costs/utils/validators.dart';

void main() {
  group('Validators (AAA)', () {
    test('email: порожній/null/невалідний/валідний', () {
      // Arrange
      const validEmail = 'user@test.com';

      // Act + Assert
      expect(Validators.email(null), AppStrings.fieldRequired);
      expect(Validators.email('   '), AppStrings.fieldRequired);
      expect(Validators.email('broken-email'), AppStrings.invalidEmail);
      expect(Validators.email(validEmail), isNull);
    });

    test('password: межа 5 і 6 символів', () {
      // Act + Assert
      expect(Validators.password('12345'), AppStrings.passwordTooShort);
      expect(Validators.password('123456'), isNull);
    });

    test('name: trim і мінімальна довжина', () {
      // Act + Assert
      expect(Validators.name(' '), AppStrings.fieldRequired);
      expect(Validators.name('a'), AppStrings.invalidName);
      expect(Validators.name(' ab '), isNull);
    });

    test('confirmPassword перевіряє співпадіння', () {
      // Arrange
      final controller = TextEditingController(text: 'secret123');
      final validator = Validators.confirmPassword(controller);

      // Act + Assert
      expect(validator(''), AppStrings.fieldRequired);
      expect(validator('another'), AppStrings.passwordsDoNotMatch);
      expect(validator('secret123'), isNull);
    });
  });

  group('CurrencyConverter (AAA)', () {
    setUp(() {
      CurrencyConverter.setUahPerCurrencyRates({
        'UAH': 1.0,
        'USD': 40.0,
        'EUR': 44.0,
      });
    });

    test('convertFromUah і convertToUah працюють симетрично для валідної ставки', () {
      // Arrange
      const amountUah = 400.0;

      // Act
      final usd = CurrencyConverter.convertFromUah(amountUah, 'USD');
      final backToUah = CurrencyConverter.convertToUah(usd, 'USD');

      // Assert
      expect(usd, 10.0);
      expect(backToUah, 400.0);
    });

    test('ігнорує невалідні ставки (<=0) при setUahPerCurrencyRates', () {
      // Arrange
      CurrencyConverter.setUahPerCurrencyRates({
        'USD': 0,
        'EUR': -1,
      });

      // Act
      final usdRate = CurrencyConverter.uahPerCurrency('USD');
      final eurRate = CurrencyConverter.uahPerCurrency('EUR');

      // Assert
      expect(usdRate, 43.84);
      expect(eurRate, 50.4861);
    });

    test('unknown currency повертає amount без змін і символ UAH', () {
      // Arrange
      const amount = 100.0;

      // Act
      final fromUah = CurrencyConverter.convertFromUah(amount, 'XYZ');
      final toUah = CurrencyConverter.convertToUah(amount, 'XYZ');
      final symbol = CurrencyConverter.symbolFor('XYZ');

      // Assert
      expect(fromUah, amount);
      expect(toUah, amount);
      expect(symbol, '₴');
    });
  });
}
