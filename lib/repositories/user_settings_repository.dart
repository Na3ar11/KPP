import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_settings.dart';

abstract class UserSettingsRepository {
  Future<UserSettings> getUserSettings(String userId);
  
  Stream<UserSettings> getUserSettingsStream(String userId);
  
  Future<void> updateUserSettings(UserSettings settings);
  
  Future<void> createDefaultSettings(String userId);
  
  Future<void> updateField(String userId, String field, dynamic value);
}

class FirestoreUserSettingsRepository implements UserSettingsRepository {
  final FirebaseFirestore _firestore;
  
  static const String _collectionName = 'userSettings';
  
  FirestoreUserSettingsRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;
  
  CollectionReference get _collection => _firestore.collection(_collectionName);
  
  @override
  Future<UserSettings> getUserSettings(String userId) async {
    try {
      final doc = await _collection.doc(userId).get();
      
      if (!doc.exists) {
        // Якщо налаштувань немає, створюємо дефолтні
        await createDefaultSettings(userId);
        final newDoc = await _collection.doc(userId).get();
        return UserSettings.fromFirestore(newDoc);
      }
      
      return UserSettings.fromFirestore(doc);
    } catch (e) {
      throw Exception('Помилка отримання налаштувань: $e');
    }
  }
  
  @override
  Stream<UserSettings> getUserSettingsStream(String userId) {
    return _collection
        .doc(userId)
        .snapshots()
        .map((doc) {
          if (!doc.exists) {
            return UserSettings(userId: userId);
          }
          return UserSettings.fromFirestore(doc);
        });
  }
  
  @override
  Future<void> updateUserSettings(UserSettings settings) async {
    try {
      await _collection.doc(settings.userId).set(
        settings.toFirestore(),
        SetOptions(merge: true), // Merge щоб не перезаписувати всі поля
      );
    } catch (e) {
      throw Exception('Помилка оновлення налаштувань: $e');
    }
  }
  
  @override
  Future<void> createDefaultSettings(String userId) async {
    try {
      final defaultSettings = UserSettings(userId: userId);
      await _collection.doc(userId).set(defaultSettings.toFirestore());
    } catch (e) {
      throw Exception('Помилка створення налаштувань: $e');
    }
  }
  
  @override
  Future<void> updateField(String userId, String field, dynamic value) async {
    try {
      await _collection.doc(userId).update({
        field: value,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Помилка оновлення поля $field: $e');
    }
  }
  
  /// Додаткові методи для зручності
  
  /// Оновити бюджет
  Future<void> updateBudget(String userId, double budget) async {
    await updateField(userId, 'monthlyBudget', budget);
  }
  
  /// Оновити валюту
  Future<void> updateCurrency(String userId, String currency) async {
    await updateField(userId, 'currency', currency);
  }
  
  /// Оновити категорію за замовчуванням
  Future<void> updateDefaultCategory(String userId, String category) async {
    await updateField(userId, 'defaultCategory', category);
  }
  
  /// Перемикач сповіщень
  Future<void> toggleNotifications(String userId, bool enabled) async {
    await updateField(userId, 'notificationsEnabled', enabled);
  }
  
  /// Перемикач темної теми
  Future<void> toggleDarkMode(String userId, bool enabled) async {
    await updateField(userId, 'isDarkMode', enabled);
  }
  
  /// Оновити мову
  Future<void> updateLanguage(String userId, String language) async {
    await updateField(userId, 'language', language);
  }
}
