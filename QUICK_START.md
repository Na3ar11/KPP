# 🚀 Швидкий старт - Firebase Integration

## Що було реалізовано

✅ **Cloud Firestore Database** - багатокористувацька система зберігання витрат  
✅ **Firebase Storage** - завантаження чеків та фото  
✅ **Security Rules** - захист даних на рівні бази  
✅ **Provider State Management** - real-time синхронізація  
✅ **CRUD операції** - повний цикл роботи з даними  

---

## 📋 Інструкції по налаштуванню

### Крок 1: Налаштуйте Firebase Console

Детальна інструкція: **[FIREBASE_SETUP.md](FIREBASE_SETUP.md)**

**Коротко**:
1. Firebase Console → Firestore Database → Create database
2. Виберіть регіон: europe-west1
3. Скопіюйте вміст `firestore.rules` в Rules
4. Firebase Console → Storage → Get started
5. Скопіюйте вміст `storage.rules` в Rules

### Крок 2: Запустіть застосунок

```bash
# Встановіть залежності
flutter pub get

# Запустіть застосунок
flutter run
```

### Крок 3: Протестуйте

1. Увійдіть через email або Google
2. Додайте витрату
3. Перевірте Firebase Console → Firestore Database
4. Витрата з'явиться в колекції `expenses`

---

## 📂 Структура проекту

```
lib/
├── models/
│   ├── expense.dart              # Модель витрати з Firestore методами
│   └── user_settings.dart        # Модель налаштувань користувача
├── repositories/
│   ├── expenses_repository.dart  # FirestoreExpensesRepository
│   ├── user_settings_repository.dart  # FirestoreUserSettingsRepository
│   ├── storage_repository.dart   # FirebaseStorageRepository
│   └── auth_repository.dart      # Firebase Auth
├── providers/
│   ├── firestore_expenses_provider.dart  # Provider з Firestore Stream
│   ├── user_settings_provider.dart       # Provider налаштувань
│   └── expenses_provider.dart    # Старий (mock) - можна видалити
├── screens/
│   ├── home_screen.dart          # Головний екран з витратами
│   ├── add_expense_screen.dart   # Додавання/редагування
│   ├── expenses_screen.dart      # Список всіх витрат
│   ├── expense_detail_screen.dart
│   └── category_expenses_screen.dart
└── main.dart                     # MultiProvider setup
```

---

## 🔑 Ключові файли

### Колекції Firestore

**expenses** - зберігання витрат:
- userId, category, description, amount
- icon, colorValue, date
- receiptUrl (optional), createdAt, updatedAt

**userSettings** - налаштування користувачів:
- monthlyBudget, currency, defaultCategory
- notificationsEnabled, language, isDarkMode

### Security Rules

**Firestore**: `firestore.rules`
- Користувачі бачать тільки свої дані
- Валідація обов'язкових полів
- Перевірка що amount > 0

**Storage**: `storage.rules`
- Завантаження тільки зображень до 5 МБ
- Доступ тільки до власних файлів

---

## 🔄 Як це працює

### Real-time синхронізація

```dart
// Provider підписується на Stream
_repository.getExpensesStream(userId!).listen((expenses) {
  _expenses = expenses;
  notifyListeners(); // UI оновлюється автоматично
});
```

### Додавання витрати

```dart
// 1. Користувач натискає "Зберегти"
final newExpense = Expense(
  id: '', // Firestore згенерує
  userId: provider.userId!,
  amount: 450.0,
  category: 'Їжа',
  // ...
);

// 2. Provider зберігає в Firestore
await provider.addExpense(newExpense);

// 3. Stream автоматично отримує нову витрату
// 4. UI перемальовується через Consumer
```

### Безпека

```javascript
// Firestore Rules
match /expenses/{expenseId} {
  allow read: if resource.data.userId == request.auth.uid;
  allow create: if request.resource.data.userId == request.auth.uid;
}
```

---

## 📝 Документація

- **[FIREBASE_SETUP.md](FIREBASE_SETUP.md)** - Повна інструкція по налаштуванню Firebase Console
- **[LAB_REPORT.md](LAB_REPORT.md)** - Звіт до лабораторної роботи з детальним описом

---

## 🎯 Функціонал

✅ Автентифікація (Email/Password, Google)  
✅ Додавання, редагування, видалення витрат  
✅ Фільтрація по категоріях  
✅ Real-time оновлення на всіх пристроях  
✅ Статистика (сьогодні, тиждень, місяць)  
✅ Налаштування користувача (бюджет, валюта)  
✅ Firebase Analytics & Crashlytics  
✅ Багатокористувацька система  

---

## 🐛 Troubleshooting

### "PERMISSION_DENIED"
- Перевірте що користувач увійшов
- Перевірте що Security Rules опубліковані
- Перевірте що витрата має userId

### "Missing required field"
- Переконайтесь що всі обов'язкові поля заповнені
- Перевірте toFirestore() метод в Expense

### Витрати не з'являються
- Перевірте FirestoreExpensesProvider.initializeExpenses() викликається
- Перегляньте логи в Debug Console
- Перевірте Firebase Console → Firestore Database

---

## 📊 Firebase Console

Після запуску застосунку перевірте:

1. **Firestore Database**:
   - Колекція `expenses` з витратами
   - Колекція `userSettings` з налаштуваннями

2. **Storage** (якщо додаєте чеки):
   - Папка `receipts/{userId}/{expenseId}/`

3. **Authentication**:
   - Список користувачів які увійшли

---

## 🚀 Наступні кроки

1. ✅ Реалізуйте завантаження чеків через image_picker
2. ✅ Додайте пагінацію для великої кількості витрат
3. ✅ Реалізуйте екран налаштувань (зміна валюти, бюджету)
4. ✅ Додайте сповіщення при перевищенні бюджету
5. ✅ Експорт витрат в CSV/PDF

---

**Готово!** 🎉 Ваш застосунок повністю інтегрований з Firebase!
