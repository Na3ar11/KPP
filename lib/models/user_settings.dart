import 'package:cloud_firestore/cloud_firestore.dart';

class UserSettings {
  final String userId;
  final double monthlyBudget;
  final String currency;
  final String defaultCategory;
  final bool notificationsEnabled;
  final String language;
  final bool isDarkMode;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserSettings({
    required this.userId,
    this.monthlyBudget = 15000.0,
    this.currency = 'UAH',
    this.defaultCategory = 'Їжа',
    this.notificationsEnabled = true,
    this.language = 'uk',
    this.isDarkMode = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  // Копіювання з можливістю зміни параметрів
  UserSettings copyWith({
    String? userId,
    double? monthlyBudget,
    String? currency,
    String? defaultCategory,
    bool? notificationsEnabled,
    String? language,
    bool? isDarkMode,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserSettings(
      userId: userId ?? this.userId,
      monthlyBudget: monthlyBudget ?? this.monthlyBudget,
      currency: currency ?? this.currency,
      defaultCategory: defaultCategory ?? this.defaultCategory,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      language: language ?? this.language,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  // Символ валюти
  String get currencySymbol {
    switch (currency) {
      case 'UAH':
        return '₴';
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      default:
        return '₴';
    }
  }

  // Конвертація в Firestore Document
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'monthlyBudget': monthlyBudget,
      'currency': currency,
      'defaultCategory': defaultCategory,
      'notificationsEnabled': notificationsEnabled,
      'language': language,
      'isDarkMode': isDarkMode,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // Створення з Firestore Document
  factory UserSettings.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    
    if (data == null) {
      // Повертаємо дефолтні налаштування
      return UserSettings(userId: doc.id);
    }
    
    return UserSettings(
      userId: doc.id,
      monthlyBudget: (data['monthlyBudget'] as num?)?.toDouble() ?? 15000.0,
      currency: data['currency'] as String? ?? 'UAH',
      defaultCategory: data['defaultCategory'] as String? ?? 'Їжа',
      notificationsEnabled: data['notificationsEnabled'] as bool? ?? true,
      language: data['language'] as String? ?? 'uk',
      isDarkMode: data['isDarkMode'] as bool? ?? false,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  // Конвертація в JSON
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'monthlyBudget': monthlyBudget,
      'currency': currency,
      'defaultCategory': defaultCategory,
      'notificationsEnabled': notificationsEnabled,
      'language': language,
      'isDarkMode': isDarkMode,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
