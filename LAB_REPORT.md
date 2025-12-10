# Звіт до лабораторної роботи №6
## Інтеграція Firebase Firestore та Storage

---

## 1. Структура колекцій Firestore

### 1.1 Колекція `expenses` (Витрати)

**Призначення**: Зберігання витрат користувачів з можливістю CRUD операцій

**Поля документа**:

| Поле | Тип | Опис | Обов'язкове |
|------|-----|------|-------------|
| `userId` | string | ID користувача з Firebase Auth | ✅ |
| `category` | string | Категорія витрати ("Їжа", "Транспорт", тощо) | ✅ |
| `description` | string | Опис витрати | ✅ |
| `amount` | number | Сума витрати (має бути > 0) | ✅ |
| `icon` | string | Емодзі іконка категорії | ✅ |
| `colorValue` | number | Колір категорії (Color.value as int) | ✅ |
| `date` | timestamp | Дата і час витрати | ✅ |
| `receiptUrl` | string | URL чека з Firebase Storage | ❌ (опційно) |
| `createdAt` | timestamp | Дата створення запису | ✅ |
| `updatedAt` | timestamp | Дата останнього оновлення | ✅ |

**Приклад документа**:
```json
{
  "userId": "abc123xyz",
  "category": "Їжа",
  "description": "Покупка продуктів в АТБ",
  "amount": 450.50,
  "icon": "🍕",
  "colorValue": 4294198070,
  "date": "Timestamp(2025-12-04 14:30:00)",
  "receiptUrl": null,
  "createdAt": "Timestamp(2025-12-04 14:30:00)",
  "updatedAt": "Timestamp(2025-12-04 14:30:00)"
}
```

**Індекси** (створюються автоматично при запитах):
- Композитний: `userId` (ASC) + `date` (DESC)
- Композитний: `userId` (ASC) + `category` (ASC) + `date` (DESC)

---

### 1.2 Колекція `userSettings` (Налаштування користувачів)

**Призначення**: Зберігання персональних налаштувань кожного користувача

**ID документа**: Дорівнює `userId` (один документ на користувача)

**Поля документа**:

| Поле | Тип | Опис | Значення за замовчуванням |
|------|-----|------|---------------------------|
| `userId` | string | ID користувача | - |
| `monthlyBudget` | number | Місячний бюджет | 15000.0 |
| `currency` | string | Валюта ("UAH", "USD", "EUR") | "UAH" |
| `defaultCategory` | string | Категорія за замовчуванням | "Їжа" |
| `notificationsEnabled` | boolean | Увімкнути сповіщення | true |
| `language` | string | Мова інтерфейсу | "uk" |
| `isDarkMode` | boolean | Темна тема | false |
| `createdAt` | timestamp | Дата створення | - |
| `updatedAt` | timestamp | Дата оновлення | - |

**Приклад документа** (ID: "abc123xyz"):
```json
{
  "userId": "abc123xyz",
  "monthlyBudget": 15000.0,
  "currency": "UAH",
  "defaultCategory": "Їжа",
  "notificationsEnabled": true,
  "language": "uk",
  "isDarkMode": false,
  "createdAt": "Timestamp(2025-12-01 10:00:00)",
  "updatedAt": "Timestamp(2025-12-04 14:30:00)"
}
```

---

## 2. Firestore Security Rules

### 2.1 Вкладка Rules в Firebase Console

**Статус**: ✅ Опубліковано

**Зміст файлу** (`firestore.rules`):

```javascript
rules_version = '2';

service cloud.firestore {
  match /databases/{database}/documents {
    
    // Функція для перевірки автентифікації
    function isAuthenticated() {
      return request.auth != null;
    }
    
    // Функція для перевірки чи це власник документа
    function isOwner(userId) {
      return isAuthenticated() && request.auth.uid == userId;
    }
    
    // Правила для колекції витрат (expenses)
    match /expenses/{expenseId} {
      // Дозволити читання тільки власних витрат
      allow read: if isAuthenticated() && 
                    resource.data.userId == request.auth.uid;
      
      // Дозволити створення тільки з власним userId
      allow create: if isAuthenticated() && 
                     request.resource.data.userId == request.auth.uid &&
                     request.resource.data.keys().hasAll([
                       'userId', 'category', 'description', 
                       'amount', 'date', 'colorValue'
                     ]) &&
                     request.resource.data.amount is number &&
                     request.resource.data.amount > 0;
      
      // Дозволити оновлення тільки власних витрат
      allow update: if isAuthenticated() && 
                     resource.data.userId == request.auth.uid &&
                     request.resource.data.userId == request.auth.uid;
      
      // Дозволити видалення тільки власних витрат
      allow delete: if isAuthenticated() && 
                     resource.data.userId == request.auth.uid;
    }
    
    // Правила для налаштувань користувача (userSettings)
    match /userSettings/{userId} {
      // Дозволити читання тільки власних налаштувань
      allow read: if isOwner(userId);
      
      // Дозволити створення тільки власних налаштувань
      allow create: if isOwner(userId) &&
                     request.resource.data.userId == userId;
      
      // Дозволити оновлення тільки власних налаштувань
      allow update: if isOwner(userId) &&
                     request.resource.data.userId == userId;
      
      // Дозволити видалення тільки власних налаштувань
      allow delete: if isOwner(userId);
    }
    
    // Заборонити доступ до інших колекцій
    match /{document=**} {
      allow read, write: if false;
    }
  }
}
```

### 2.2 Пояснення правил

**Для колекції `expenses`**:
- ✅ **Читання**: Користувачі можуть читати тільки витрати де `userId == auth.uid`
- ✅ **Створення**: Можливе тільки якщо `userId` в документі відповідає поточному користувачу
- ✅ **Валідація**: Перевірка обов'язкових полів та що `amount > 0`
- ✅ **Оновлення**: Тільки власник витрати може її редагувати
- ✅ **Видалення**: Тільки власник витрати може її видалити

**Для колекції `userSettings`**:
- ✅ **Читання/Запис**: Користувач може працювати тільки зі своїм документом
- ✅ **ID документа**: Має відповідати userId користувача

**Безпека**:
- ❌ Неавтентифіковані користувачі НЕ можуть читати/писати дані
- ❌ Користувачі НЕ можуть бачити дані інших користувачів
- ❌ Доступ до невизначених колекцій заборонений

---

## 3. Програмний код репозиторіїв

### 3.1 ExpensesRepository

**Файл**: `lib/repositories/expenses_repository.dart`

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/expense.dart';

/// Абстрактний клас для роботи з витратами
abstract class ExpensesRepository {
  Stream<List<Expense>> getExpensesStream(String userId);
  Future<List<Expense>> getExpensesByDateRange(String userId, DateTime startDate, DateTime endDate);
  Future<List<Expense>> getExpensesByCategory(String userId, String category);
  Future<Expense?> getExpenseById(String expenseId);
  Future<String> addExpense(Expense expense);
  Future<void> updateExpense(Expense expense);
  Future<void> deleteExpense(String expenseId);
  Future<double> getTotalAmount(String userId, DateTime startDate, DateTime endDate);
}

/// Реалізація репозиторію через Firestore
class FirestoreExpensesRepository implements ExpensesRepository {
  final FirebaseFirestore _firestore;
  static const String _collectionName = 'expenses';
  
  FirestoreExpensesRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;
  
  CollectionReference get _collection => _firestore.collection(_collectionName);
  
  @override
  Stream<List<Expense>> getExpensesStream(String userId) {
    return _collection
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Expense.fromFirestoreQuery(doc))
              .toList();
        });
  }
  
  @override
  Future<String> addExpense(Expense expense) async {
    try {
      final docRef = await _collection.add(expense.toFirestore());
      return docRef.id;
    } catch (e) {
      throw Exception('Помилка додавання витрати: $e');
    }
  }
  
  @override
  Future<void> updateExpense(Expense expense) async {
    try {
      await _collection.doc(expense.id).update(expense.toFirestore());
    } catch (e) {
      throw Exception('Помилка оновлення витрати: $e');
    }
  }
  
  @override
  Future<void> deleteExpense(String expenseId) async {
    try {
      await _collection.doc(expenseId).delete();
    } catch (e) {
      throw Exception('Помилка видалення витрати: $e');
    }
  }
  
  // ... інші методи (getExpensesByDateRange, getExpensesByCategory, getTotalAmount)
}
```

**Ключові особливості**:
- ✅ Використовує Stream для real-time оновлень
- ✅ Автоматична фільтрація по userId
- ✅ Обробка помилок з детальними повідомленнями
- ✅ Підтримка складних запитів (по даті, категорії)

---

### 3.2 UserSettingsRepository

**Файл**: `lib/repositories/user_settings_repository.dart`

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_settings.dart';

/// Абстрактний клас для роботи з налаштуваннями користувача
abstract class UserSettingsRepository {
  Future<UserSettings> getUserSettings(String userId);
  Stream<UserSettings> getUserSettingsStream(String userId);
  Future<void> updateUserSettings(UserSettings settings);
  Future<void> createDefaultSettings(String userId);
  Future<void> updateField(String userId, String field, dynamic value);
}

/// Реалізація репозиторію через Firestore
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
        SetOptions(merge: true),
      );
    } catch (e) {
      throw Exception('Помилка оновлення налаштувань: $e');
    }
  }
  
  // Зручні методи для оновлення окремих полів
  Future<void> updateBudget(String userId, double budget) async {
    await updateField(userId, 'monthlyBudget', budget);
  }
  
  Future<void> updateCurrency(String userId, String currency) async {
    await updateField(userId, 'currency', currency);
  }
  
  // ... інші методи
}
```

---

### 3.3 StorageRepository

**Файл**: `lib/repositories/storage_repository.dart`

```dart
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

/// Абстрактний клас для роботи з файлами
abstract class StorageRepository {
  Future<String> uploadFile(File file, String path);
  Future<String> uploadFileWithProgress(File file, String path, Function(double) onProgress);
  Future<void> deleteFile(String url);
  Future<String> getFileUrl(String path);
}

/// Реалізація репозиторію через Firebase Storage
class FirebaseStorageRepository implements StorageRepository {
  final FirebaseStorage _storage;
  
  FirebaseStorageRepository({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;
  
  @override
  Future<String> uploadFile(File file, String path) async {
    try {
      final ref = _storage.ref().child(path);
      final uploadTask = await ref.putFile(file);
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('Помилка завантаження файлу: $e');
    }
  }
  
  @override
  Future<String> uploadFileWithProgress(
    File file,
    String path,
    Function(double) onProgress,
  ) async {
    try {
      final ref = _storage.ref().child(path);
      final uploadTask = ref.putFile(file);
      
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        onProgress(progress);
      });
      
      final taskSnapshot = await uploadTask;
      final downloadUrl = await taskSnapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('Помилка завантаження файлу: $e');
    }
  }
  
  /// Завантажити чек для витрати
  Future<String> uploadReceipt(File file, String userId, String expenseId) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final path = 'receipts/$userId/$expenseId/$timestamp.jpg';
    return await uploadFile(file, path);
  }
  
  /// Видалити чек
  Future<void> deleteReceipt(String receiptUrl) async {
    if (receiptUrl.isEmpty) return;
    await deleteFile(receiptUrl);
  }
}
```

---

## 4. Менеджери стану (Provider)

### 4.1 FirestoreExpensesProvider

**Файл**: `lib/providers/firestore_expenses_provider.dart`

```dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/expense.dart';
import '../repositories/expenses_repository.dart';

enum LoadingState { idle, loading, success, error }

/// Provider для керування витратами через Firestore
class FirestoreExpensesProvider extends ChangeNotifier {
  final ExpensesRepository _repository;
  final FirebaseAuth _auth;
  
  List<Expense> _expenses = [];
  LoadingState _loadingState = LoadingState.idle;
  String? _errorMessage;
  double _budget = 15000.0;
  StreamSubscription<List<Expense>>? _expensesSubscription;
  
  FirestoreExpensesProvider({
    required ExpensesRepository repository,
    FirebaseAuth? auth,
  })  : _repository = repository,
        _auth = auth ?? FirebaseAuth.instance;
  
  // Геттери
  List<Expense> get expenses => List.unmodifiable(_expenses);
  bool get isLoading => _loadingState == LoadingState.loading;
  bool get hasError => _loadingState == LoadingState.error;
  String? get userId => _auth.currentUser?.uid;
  
  /// Ініціалізація - підписка на зміни витрат в реальному часі
  Future<void> initializeExpenses() async {
    if (userId == null) {
      _loadingState = LoadingState.error;
      _errorMessage = 'Користувач не авторизований';
      notifyListeners();
      return;
    }
    
    _loadingState = LoadingState.loading;
    notifyListeners();
    
    try {
      // Підписуємось на стрім витрат з Firestore
      _expensesSubscription = _repository.getExpensesStream(userId!).listen(
        (expenses) {
          _expenses = expenses;
          _loadingState = LoadingState.success;
          notifyListeners();
        },
        onError: (error) {
          _loadingState = LoadingState.error;
          _errorMessage = 'Помилка завантаження витрат: $error';
          notifyListeners();
        },
      );
    } catch (e) {
      _loadingState = LoadingState.error;
      _errorMessage = 'Помилка ініціалізації: $e';
      notifyListeners();
    }
  }
  
  /// Додати нову витрату
  Future<void> addExpense(Expense expense) async {
    if (userId == null) {
      throw Exception('Користувач не авторизований');
    }
    
    try {
      final expenseWithUser = expense.copyWith(
        userId: userId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      // Зберігаємо в Firestore (стрім автоматично оновить _expenses)
      await _repository.addExpense(expenseWithUser);
    } catch (e) {
      throw Exception('Помилка додавання витрати: $e');
    }
  }
  
  /// Оновити витрату
  Future<void> updateExpense(Expense expense) async {
    try {
      final updatedExpense = expense.copyWith(updatedAt: DateTime.now());
      await _repository.updateExpense(updatedExpense);
    } catch (e) {
      throw Exception('Помилка оновлення витрати: $e');
    }
  }
  
  /// Видалити витрату
  Future<void> deleteExpense(String expenseId) async {
    try {
      await _repository.deleteExpense(expenseId);
    } catch (e) {
      throw Exception('Помилка видалення витрати: $e');
    }
  }
  
  @override
  void dispose() {
    _expensesSubscription?.cancel();
    super.dispose();
  }
}
```

**Ключові особливості**:
- ✅ **Real-time оновлення**: Використовує Stream для автоматичного оновлення UI
- ✅ **Стани завантаження**: idle, loading, success, error
- ✅ **Автоматичне додавання userId**: При створенні витрати
- ✅ **Обробка помилок**: Детальні повідомлення про помилки
- ✅ **Очищення ресурсів**: Відписка від Stream в dispose()

---

### 4.2 UserSettingsProvider

**Файл**: `lib/providers/user_settings_provider.dart`

```dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_settings.dart';
import '../repositories/user_settings_repository.dart';

/// Provider для керування налаштуваннями користувача
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
  bool get isDarkMode => _settings?.isDarkMode ?? false;
  String get currency => _settings?.currency ?? 'UAH';
  double get monthlyBudgetLimit => _settings?.monthlyBudget ?? 15000.0;
  
  /// Ініціалізація - підписка на зміни налаштувань
  Future<void> initialize() async {
    if (userId == null) return;
    
    try {
      _settingsSubscription = _repository.getUserSettingsStream(userId!).listen(
        (settings) {
          _settings = settings;
          _isInitialized = true;
          notifyListeners();
        },
      );
    } catch (e) {
      debugPrint('Помилка ініціалізації налаштувань: $e');
    }
  }
  
  /// Змінити валюту
  Future<void> setCurrency(String newCurrency) async {
    if (userId == null || _settings == null) return;
    
    try {
      final repo = _repository as FirestoreUserSettingsRepository;
      await repo.updateCurrency(userId!, newCurrency);
    } catch (e) {
      throw Exception('Помилка зміни валюти: $e');
    }
  }
  
  @override
  void dispose() {
    _settingsSubscription?.cancel();
    super.dispose();
  }
}
```

---

## 5. Firebase Storage

### 5.1 Storage Rules

**Файл**: `storage.rules`

```javascript
rules_version = '2';

service firebase.storage {
  match /b/{bucket}/o {
    function isAuthenticated() {
      return request.auth != null;
    }
    
    function isOwner(userId) {
      return isAuthenticated() && request.auth.uid == userId;
    }
    
    function isImage() {
      return request.resource.contentType.matches('image/.*');
    }
    
    function isValidSize() {
      return request.resource.size <= 5 * 1024 * 1024;
    }
    
    // Правила для чеків витрат
    match /receipts/{userId}/{expenseId}/{fileName} {
      allow read: if isOwner(userId);
      allow write: if isOwner(userId) && isImage() && isValidSize();
      allow delete: if isOwner(userId);
    }
    
    // Правила для аватарів
    match /avatars/{userId}/{fileName} {
      allow read: if isAuthenticated();
      allow write: if isOwner(userId) && isImage() && isValidSize();
      allow delete: if isOwner(userId);
    }
  }
}
```

**Пояснення**:
- ✅ Завантаження тільки зображень (image/*)
- ✅ Максимальний розмір файлу 5 МБ
- ✅ Користувач може завантажувати тільки до своєї папки
- ✅ Чеки доступні тільки власнику
- ✅ Аватари видимі всім автентифікованим користувачам

---

## 6. Модифікації моделей даних

### 6.1 Expense Model

**Файл**: `lib/models/expense.dart`

**Додано**:
- `userId` - для багатокористувацької системи
- `receiptUrl` - для збереження URL чека з Storage
- `createdAt`, `updatedAt` - для відстеження змін
- `toFirestore()` - конвертація в Firestore Document
- `fromFirestore()` - створення з Firestore Document
- `fromFirestoreQuery()` - для QueryDocumentSnapshot

```dart
class Expense {
  final String id;
  final String userId;
  final String icon;
  final String category;
  final String description;
  final double amount;
  final Color color;
  final DateTime date;
  final String? receiptUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Конвертація в Firestore Document
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'icon': icon,
      'category': category,
      'description': description,
      'amount': amount,
      'colorValue': color.value,
      'date': Timestamp.fromDate(date),
      'receiptUrl': receiptUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
  
  // Створення з Firestore Document
  factory Expense.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return Expense(
      id: doc.id,
      userId: data['userId'] as String,
      icon: data['icon'] as String,
      category: data['category'] as String,
      description: data['description'] as String,
      amount: (data['amount'] as num).toDouble(),
      color: Color(data['colorValue'] as int),
      date: (data['date'] as Timestamp).toDate(),
      receiptUrl: data['receiptUrl'] as String?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }
}
```

---

### 6.2 UserSettings Model

**Файл**: `lib/models/user_settings.dart`

**Створено нову модель** для зберігання налаштувань:

```dart
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
  
  factory UserSettings.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    
    if (data == null) {
      return UserSettings(userId: doc.id);
    }
    
    return UserSettings(
      userId: doc.id,
      monthlyBudget: (data['monthlyBudget'] as num?)?.toDouble() ?? 15000.0,
      currency: data['currency'] as String? ?? 'UAH',
      // ... інші поля з дефолтними значеннями
    );
  }
}
```

---

## 7. Інтеграція в UI

### 7.1 Налаштування Provider в main.dart

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Репозиторії
        Provider<ExpensesRepository>(
          create: (_) => FirestoreExpensesRepository(),
        ),
        Provider<UserSettingsRepository>(
          create: (_) => FirestoreUserSettingsRepository(),
        ),
        
        // Providers з автоматичною підпискою на Firestore
        ChangeNotifierProvider<FirestoreExpensesProvider>(
          create: (context) => FirestoreExpensesProvider(
            repository: context.read<ExpensesRepository>(),
          ),
        ),
        ChangeNotifierProvider<UserSettingsProvider>(
          create: (context) => UserSettingsProvider(
            repository: context.read<UserSettingsRepository>(),
          ),
        ),
      ],
      child: MaterialApp(
        home: const AuthWrapper(),
      ),
    );
  }
}
```

### 7.2 Ініціалізація після автентифікації

```dart
class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: authRepository.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          // Ініціалізація провайдерів після входу
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.read<FirestoreExpensesProvider>().initializeExpenses();
            context.read<UserSettingsProvider>().initialize();
          });
          
          return const HomeScreen();
        }
        
        return const LoginScreen();
      },
    );
  }
}
```

### 7.3 Використання в UI

**HomeScreen - відображення витрат**:
```dart
Consumer<FirestoreExpensesProvider>(
  builder: (context, provider, child) {
    if (provider.isLoading) {
      return CircularProgressIndicator();
    }
    
    return ListView.builder(
      itemCount: provider.expenses.length,
      itemBuilder: (context, index) {
        final expense = provider.expenses[index];
        return ExpenseCard(expense: expense);
      },
    );
  },
)
```

**AddExpenseScreen - додавання витрати**:
```dart
Future<void> _saveExpense() async {
  final provider = context.read<FirestoreExpensesProvider>();
  
  final newExpense = Expense(
    id: '', // Firestore згенерує автоматично
    userId: provider.userId!,
    amount: amount,
    category: _selectedCategory!,
    description: _commentController.text,
    // ... інші поля
  );
  
  await provider.addExpense(newExpense);
  Navigator.pop(context);
}
```

---

## 8. Переваги реалізації

### 8.1 Архітектурні переваги

✅ **Розділення відповідальностей**:
- Моделі - тільки структура даних
- Репозиторії - робота з Firestore/Storage
- Providers - управління станом та бізнес-логіка
- UI - тільки відображення

✅ **Тестованість**:
- Абстрактні репозиторії легко мокати
- Providers можна тестувати окремо від Firebase
- DI через MultiProvider

✅ **Розширюваність**:
- Легко додати нові репозиторії (наприклад REST API)
- Можна замінити Firestore на іншу базу даних
- Модульна структура

### 8.2 Технічні переваги

✅ **Real-time синхронізація**:
- Використання Stream для автоматичного оновлення UI
- Зміни видимі на всіх пристроях користувача

✅ **Безпека**:
- Security Rules захищають дані на рівні бази даних
- Користувачі бачать тільки свої дані
- Валідація даних при записі

✅ **Оптимізація**:
- Кешування Firestore (offline persistence)
- Пагінація можлива через limit() та startAfter()
- Індекси для швидких запитів

---

## 9. Висновок

✅ **Виконано всі вимоги лабораторної роботи**:

1. ✅ Підключено Firestore Database з колекціями `expenses` та `userSettings`
2. ✅ Налаштовано Security Rules для захисту даних
3. ✅ Створено репозиторії з методами CRUD операцій
4. ✅ Реалізовано моделі даних з toFirestore/fromFirestore
5. ✅ Використано Provider для state management з Firestore
6. ✅ Інтегровано Firebase Storage для зберігання файлів
7. ✅ Налаштовано Storage Rules для безпеки файлів

**Результат**: Повнофункціональний застосунок для відстеження витрат з багатокористувацькою системою, real-time синхронізацією та надійною безпекою даних.
