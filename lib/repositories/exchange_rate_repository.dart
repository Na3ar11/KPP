import 'dart:convert';
import 'package:http/http.dart' as http;

abstract class ExchangeRateRepository {
  Future<Map<String, double>> fetchUahPerCurrencyRates();
}

class NbuExchangeRateRepository implements ExchangeRateRepository {
  static final Uri _nbuUri =
      Uri.parse('https://bank.gov.ua/NBUStatService/v1/statdirectory/exchange?json');

  final http.Client _httpClient;

  NbuExchangeRateRepository({http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();

  @override
  Future<Map<String, double>> fetchUahPerCurrencyRates() async {
    final response = await _httpClient
        .get(_nbuUri)
        .timeout(const Duration(seconds: 12));

    if (response.statusCode != 200) {
      throw Exception('NBU API помилка: HTTP ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! List) {
      throw Exception('NBU API повернув неочікуваний формат');
    }

    final rates = <String, double>{'UAH': 1.0};

    for (final item in decoded) {
      if (item is! Map<String, dynamic>) continue;
      final code = (item['cc'] as String?)?.toUpperCase();
      final rateRaw = item['rate'];

      if (code == null || code.isEmpty || rateRaw is! num || rateRaw <= 0) {
        continue;
      }

      // NBU rate = UAH за 1 одиницю валюти.
      rates[code] = rateRaw.toDouble();
    }

    if (!rates.containsKey('USD') || !rates.containsKey('EUR')) {
      throw Exception('NBU API не повернув USD/EUR курси');
    }

    return rates;
  }
}
