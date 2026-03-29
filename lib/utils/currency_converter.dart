import 'package:intl/intl.dart';

class CurrencyConverter {
  static const Map<String, double> _defaultUahPerCurrencyRate = {
    'UAH': 1.0,
    // Fallback значення, якщо API недоступний.
    'USD': 43.84,
    'EUR': 50.4861,
  };

  static Map<String, double> _uahPerCurrencyRate =
      Map<String, double>.from(_defaultUahPerCurrencyRate);

  static void setUahPerCurrencyRates(Map<String, double> rates) {
    if (rates.isEmpty) return;

    final normalized = <String, double>{'UAH': 1.0};
    rates.forEach((key, value) {
      final upper = key.toUpperCase();
      if (value > 0) {
        normalized[upper] = value;
      }
    });

    _uahPerCurrencyRate = normalized;
  }

  static double convertFromUah(double amountInUah, String targetCurrency) {
    final currency = targetCurrency.toUpperCase();
    if (currency == 'UAH') return amountInUah;

    final uahPerOneUnit =
        _uahPerCurrencyRate[currency] ?? _defaultUahPerCurrencyRate[currency];

    if (uahPerOneUnit == null || uahPerOneUnit <= 0) {
      return amountInUah;
    }

    return amountInUah / uahPerOneUnit;
  }

  static double convertToUah(double amount, String sourceCurrency) {
    final currency = sourceCurrency.toUpperCase();
    if (currency == 'UAH') return amount;

    final uahPerOneUnit =
        _uahPerCurrencyRate[currency] ?? _defaultUahPerCurrencyRate[currency];

    if (uahPerOneUnit == null || uahPerOneUnit <= 0) {
      return amount;
    }

    return amount * uahPerOneUnit;
  }

  static double uahPerCurrency(String currencyCode) {
    final currency = currencyCode.toUpperCase();
    return _uahPerCurrencyRate[currency] ??
        _defaultUahPerCurrencyRate[currency] ??
        1.0;
  }

  static String symbolFor(String currencyCode) {
    switch (currencyCode) {
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'UAH':
      default:
        return '₴';
    }
  }

  static String formatFromUah(
    double amountInUah,
    String targetCurrency, {
    int decimalDigits = 0,
  }) {
    final converted = convertFromUah(amountInUah, targetCurrency);
    final symbol = symbolFor(targetCurrency);
    final formatter = NumberFormat.currency(
      locale: 'uk_UA',
      symbol: symbol,
      decimalDigits: decimalDigits,
    );
    return formatter.format(converted);
  }
}
