import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_settings.dart';
import '../repositories/user_settings_repository.dart';

/// Provider для керування налаштуваннями користувача через Firestore
class UserSettingsProvider extends ChangeNotifier {
  final UserSettingsRepository _repository;
  final FirebaseAuth _auth;
  
  UserSettings? _settings;
  bool _isInitialized = false;
  StreamSubscription<UserSettings>? _settingsSubscription;
  
  UserSettingsProvider({
    required UserSettingsRepository repository,
    FirebaseAuth? auth,
  })  : _repository = repository,
        _auth = auth ?? FirebaseAuth.instance;
  
  // Геттери
  UserSettings? get settings => _settings;
  bool get isInitialized => _isInitialized;
  String? get userId => _auth.currentUser?.uid;
  
  // Зручні геттери для UI
  bool get isDarkMode => _settings?.isDarkMode ?? false;
  String get currency => _settings?.currency ?? 'UAH';
  double get monthlyBudgetLimit => _settings?.monthlyBudget ?? 15000.0;
  bool get notificationsEnabled => _settings?.notificationsEnabled ?? true;
  String get defaultCategory => _settings?.defaultCategory ?? 'Їжа';
  String get language => _settings?.language ?? 'uk';
  String get currencySymbol => _settings?.currencySymbol ?? '₴';
  
  /// Ініціалізація - підписка на зміни налаштувань
  Future<void> initialize() async {
    if (userId == null) {
      _isInitialized = false;
      notifyListeners();
      return;
    }
    
    try {
      // Підписуємось на стрім налаштувань
      _settingsSubscription = _repository.getUserSettingsStream(userId!).listen(
        (settings) {
          _settings = settings;
          _isInitialized = true;
          notifyListeners();
        },
        onError: (error) {
          debugPrint('Помилка завантаження налаштувань: $error');
        },
      );
    } catch (e) {
      debugPrint('Помилка ініціалізації налаштувань: $e');
    }
  }
  
  /// Оновити всі налаштування
  Future<void> updateSettings(UserSettings settings) async {
    if (userId == null) {
      throw Exception('Користувач не авторизований');
    }
    
    try {
      await _repository.updateUserSettings(settings);
      // Стрім автоматично оновить _settings
    } catch (e) {
      throw Exception('Помилка оновлення налаштувань: $e');
    }
  }
  
  /// Перемикач темної теми
  Future<void> toggleDarkMode() async {
    if (userId == null || _settings == null) return;
    
    try {
      final repo = _repository as FirestoreUserSettingsRepository;
      await repo.toggleDarkMode(userId!, !_settings!.isDarkMode);
    } catch (e) {
      throw Exception('Помилка зміни теми: $e');
    }
  }
  
  /// Змінити валюту
  Future<void> setCurrency(String newCurrency) async {
    if (userId == null || _settings == null) return;
    if (_settings!.currency == newCurrency) return;
    
    try {
      final repo = _repository as FirestoreUserSettingsRepository;
      await repo.updateCurrency(userId!, newCurrency);
    } catch (e) {
      throw Exception('Помилка зміни валюти: $e');
    }
  }
  
  /// Змінити місячний бюджет
  Future<void> setMonthlyBudgetLimit(double limit) async {
    if (userId == null) return;
    
    try {
      final repo = _repository as FirestoreUserSettingsRepository;
      await repo.updateBudget(userId!, limit);
    } catch (e) {
      throw Exception('Помилка зміни бюджету: $e');
    }
  }
  
  /// Перемикач сповіщень
  Future<void> toggleNotifications() async {
    if (userId == null || _settings == null) return;
    
    try {
      final repo = _repository as FirestoreUserSettingsRepository;
      await repo.toggleNotifications(userId!, !_settings!.notificationsEnabled);
    } catch (e) {
      throw Exception('Помилка зміни сповіщень: $e');
    }
  }
  
  /// Змінити категорію за замовчуванням
  Future<void> setDefaultCategory(String category) async {
    if (userId == null) return;
    
    try {
      final repo = _repository as FirestoreUserSettingsRepository;
      await repo.updateDefaultCategory(userId!, category);
    } catch (e) {
      throw Exception('Помилка зміни категорії: $e');
    }
  }
  
  /// Змінити мову
  Future<void> setLanguage(String lang) async {
    if (userId == null) return;
    
    try {
      final repo = _repository as FirestoreUserSettingsRepository;
      await repo.updateLanguage(userId!, lang);
    } catch (e) {
      throw Exception('Помилка зміни мови: $e');
    }
  }
  
  /// Скинути налаштування до значень за замовчуванням
  Future<void> resetToDefaults() async {
    if (userId == null) return;
    
    try {
      final defaultSettings = UserSettings(userId: userId!);
      await _repository.updateUserSettings(defaultSettings);
    } catch (e) {
      throw Exception('Помилка скидання налаштувань: $e');
    }
  }
  
  @override
  void dispose() {
    // Відписуємось від стріму
    _settingsSubscription?.cancel();
    super.dispose();
  }
}
