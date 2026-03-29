import 'package:flutter/foundation.dart';
import '../repositories/exchange_rate_repository.dart';
import '../utils/currency_converter.dart';

class ExchangeRateProvider extends ChangeNotifier {
  final ExchangeRateRepository _repository;

  Map<String, double> _uahPerCurrencyRates = {'UAH': 1.0};
  bool _isLoading = false;
  String? _error;
  DateTime? _lastUpdated;

  ExchangeRateProvider({required ExchangeRateRepository repository})
      : _repository = repository;

  Map<String, double> get rates => Map.unmodifiable(_uahPerCurrencyRates);
  bool get isLoading => _isLoading;
  String? get error => _error;
  DateTime? get lastUpdated => _lastUpdated;

  Future<void> refreshRates() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final fetched = await _repository.fetchUahPerCurrencyRates();
      _uahPerCurrencyRates = fetched;
      _lastUpdated = DateTime.now();

      CurrencyConverter.setUahPerCurrencyRates(fetched);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
