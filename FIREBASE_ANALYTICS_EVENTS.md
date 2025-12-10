# Firebase Analytics - Кастомні івенти

## Список івентів

### 1. **view_expenses_history**
Спрацьовує коли користувач відкриває екран історії витрат

**Параметри:**
- `screen_name`: "expenses_screen"
- `timestamp`: ISO 8601 дата і час

**Файл:** `lib/screens/expenses_screen.dart`

---

### 2. **open_add_expense_screen**
Спрацьовує коли користувач відкриває екран додавання витрати

**Параметри:**
- `screen_name`: "add_expense_screen"
- `timestamp`: ISO 8601 дата і час

**Файл:** `lib/screens/add_expense_screen.dart`

---

### 3. **user_login**
Спрацьовує коли користувач успішно входить в акаунт

**Параметри:**
- `login_method`: "email" або "google"
- `user_email`: email користувача (тільки для email методу)
- `timestamp`: ISO 8601 дата і час

**Файл:** `lib/screens/login_screen.dart`

---

### 4. **user_register**
Спрацьовує коли користувач успішно реєструється

**Параметри:**
- `register_method`: "email" або "google"
- `user_email`: email користувача (тільки для email методу)
- `timestamp`: ISO 8601 дата і час

**Файл:** `lib/screens/register_screen.dart`

---

### 5. **user_logout**
Спрацьовує коли користувач виходить з акаунта

**Параметри:**
- `user_email`: email користувача
- `timestamp`: ISO 8601 дата і час

**Файл:** `lib/screens/home_screen.dart`

---

## Як переглянути івенти в Firebase Console

1. Відкрийте [Firebase Console](https://console.firebase.google.com/)
2. Виберіть проект **tracker-costs**
3. Перейдіть в розділ **Analytics** → **Events**
4. Зачекайте 24-48 годин для першої статистики
5. Для real-time тестування використовуйте **DebugView**

## Як увімкнути DebugView

### Android:
```bash
adb shell setprop debug.firebase.analytics.app com.example.tracker_costs
```

### iOS:
Додайте аргумент `-FIRAnalyticsDebugEnabled` в Xcode scheme

### Web:
Додайте параметр `?debug_mode=1` до URL

---

## Приклади використання даних

### Популярні екрани
Подивіться які екрани найбільше відвідують користувачі:
- `view_expenses_history` - скільки разів переглядають історію
- `open_add_expense_screen` - скільки разів додають витрати

### Методи входу
Яким способом користувачі найчастіше входять:
- Фільтруйте `user_login` по `login_method`
- Порівняйте "email" vs "google"

### Retention
Порівняйте кількість реєстрацій (`user_register`) з кількістю виходів (`user_logout`)

---

*Оновлено: 5 листопада 2025*
