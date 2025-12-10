# 🚀 Bitrise CI/CD для Tracker Costs

## 📋 Конфігурація проєкту

**Назва проєкту**: Tracker Costs  
**Package**: com.example.tracker_costs  
**Firebase Project ID**: tracker-costs  
**Firebase App ID**: 1:98211696497:android:6829066851715285e630d0

---

## 🔧 Налаштування Bitrise

### 1. Створення проєкту на Bitrise

1. Перейдіть на [app.bitrise.io](https://app.bitrise.io)
2. Натисніть **"Add new app"**
3. Виберіть **GitHub** як Git provider
4. Виберіть репозиторій **Na3ar11/KPP**
5. Оберіть branch: **main**
6. Bitrise автоматично виявить Flutter проект
7. Підтвердіть конфігурацію

---

### 2. Додавання Secrets (обов'язково)

Перейдіть: **Workflow Editor** → **Secrets**

Додайте наступні секрети:

| Key | Value | Опис |
|-----|-------|------|
| `FIREBASE_APP_ID_ANDROID` | `1:98211696497:android:6829066851715285e630d0` | Firebase App ID для Android |
| `FIREBASE_TOKEN` | `your-firebase-ci-token` | Firebase CI token (згенерувати нижче) |
| `GOOGLE_SERVICES_JSON_BASE64` | `base64-encoded-content` | (Опціонально) google-services.json в base64 |

---

### 3. Генерація Firebase CI Token

Виконайте у терміналі:

```bash
# Встановити Firebase CLI (якщо ще не встановлено)
npm install -g firebase-tools

# Залогінитись і отримати token
firebase login:ci
```

Скопіюйте отриманий token і додайте його як `FIREBASE_TOKEN` у Bitrise Secrets.

---

### 4. Кодування google-services.json в Base64 (опціонально)

Якщо ви не хочете зберігати `google-services.json` в репозиторії:

**Windows (PowerShell):**
```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("android\app\google-services.json")) | Set-Clipboard
```

**Linux/Mac:**
```bash
base64 -i android/app/google-services.json | pbcopy
```

Додайте скопійований текст як `GOOGLE_SERVICES_JSON_BASE64` у Bitrise Secrets.

---

### 5. Завантаження bitrise.yml

1. У корені проєкту створіть файл `bitrise.yml`
2. Скопіюйте вміст з `tracker_costs/bitrise.yml`
3. Commit і push до GitHub:

```bash
git add bitrise.yml
git commit -m "Add Bitrise CI/CD configuration"
git push origin main
```

4. У Bitrise: **Workflow Editor** → **bitrise.yml** → **Switch to YAML mode**
5. Bitrise автоматично підхопить конфігурацію з репозиторію

---

### 6. Створення тестової групи в Firebase

1. Відкрийте [Firebase Console](https://console.firebase.google.com/project/tracker-costs/appdistribution)
2. Перейдіть: **App Distribution** → **Testers & Groups**
3. Натисніть **"Create Group"**
4. Назва групи: **testers**
5. Додайте email адреси тестувальників
6. Збережіть

---

## 🚀 Використання

### Автоматична збірка

Збірка запускається автоматично при:
- Push до гілки `main`
- Створенні Pull Request

### Ручний запуск

1. Перейдіть на [app.bitrise.io](https://app.bitrise.io)
2. Виберіть проект **Tracker Costs**
3. Натисніть **"Start/Schedule a Build"**
4. Виберіть workflow: **android_firebase**
5. Branch: **main**
6. Натисніть **"Start Build"**

---

## 📊 Workflow Steps

| # | Step | Опис |
|---|------|------|
| 1 | SSH Key | Активація SSH ключа для Git |
| 2 | Git Clone | Клонування репозиторію |
| 3 | Flutter Installer | Встановлення Flutter 3.24.5 |
| 4 | Restore Cache | Відновлення Dart package cache |
| 5 | Pub Get | Завантаження залежностей |
| 6 | Analyze | Статичний аналіз коду |
| 7 | Tests | Запуск unit тестів |
| 8 | Save Cache | Збереження cache для наступних збірок |
| 9 | Firebase Setup | Налаштування google-services.json |
| 10 | Build APK | Збірка Release APK |
| 11 | Verify Config | Перевірка Firebase конфігурації |
| 12 | Firebase Deploy | Завантаження в App Distribution |
| 13 | Build Report | Генерація звіту про збірку |
| 14 | Instructions | Створення інструкцій з встановлення |
| 15 | Deploy Artifacts | Збереження артефактів на Bitrise |

---

## 📦 Артефакти збірки

Після успішної збірки доступні:

1. **TrackerCosts_v1.0.0_buildXX.apk** - Release APK
2. **BUILD_REPORT.md** - Детальний звіт про збірку
3. **INSTALL_INSTRUCTIONS.txt** - Інструкції з встановлення

Завантажити: **Builds** → **Artifacts**

---

## 🔥 Firebase App Distribution

### Процес розповсюдження

1. Bitrise збирає APK
2. Завантажує в Firebase App Distribution
3. Firebase відправляє email тестувальникам з групи **testers**
4. Тестувальники отримують сповіщення та можуть завантажити APK

### Перевірка статусу

1. [Firebase Console](https://console.firebase.google.com/project/tracker-costs/appdistribution)
2. **App Distribution** → **Releases**
3. Перегляньте історію релізів та статус розповсюдження

---

## 🧪 Тестування

### Як тестувальники отримують build:

**Метод 1: Firebase App Tester**
1. Встановити [Firebase App Tester](https://play.google.com/store/apps/details?id=com.google.firebase.appdistribution) з Google Play
2. Відкрити запрошення з email
3. Завантажити та встановити через додаток

**Метод 2: Прямий APK**
1. Завантажити APK з Bitrise Artifacts
2. Встановити вручну на Android пристрій

---

## ⚙️ Налаштування версії

Оновлення версії в `pubspec.yaml`:

```yaml
version: 1.0.0+1  # format: major.minor.patch+buildNumber
```

- **1.0.0** - version name (видима користувачам)
- **+1** - version code (використовується Android для оновлень)

---

## 🔍 Troubleshooting

### ❌ "Firebase token expired"

```bash
# Згенеруйте новий token
firebase login:ci

# Оновіть FIREBASE_TOKEN в Bitrise Secrets
```

### ❌ "google-services.json not found"

- Переконайтесь що файл є в `android/app/google-services.json`
- АБО додайте `GOOGLE_SERVICES_JSON_BASE64` в Secrets

### ❌ "Testers group not found"

- Створіть групу **testers** в Firebase Console
- App Distribution → Testers & Groups → Create Group

### ❌ Build fails на Flutter analyze

- Виправте помилки в коді
- Або змініть `is_always_run: true` щоб ігнорувати попередження

---

## 📈 Моніторинг

### Bitrise Dashboard

- Статус збірок: [app.bitrise.io](https://app.bitrise.io)
- Build history
- Build logs
- Artifacts

### Firebase Console

- [Analytics](https://console.firebase.google.com/project/tracker-costs/analytics)
- [Crashlytics](https://console.firebase.google.com/project/tracker-costs/crashlytics)
- [App Distribution](https://console.firebase.google.com/project/tracker-costs/appdistribution)

---

## 🔗 Корисні посилання

- [Bitrise Documentation](https://devcenter.bitrise.io/)
- [Firebase App Distribution](https://firebase.google.com/docs/app-distribution)
- [Flutter CI/CD Best Practices](https://docs.flutter.dev/deployment/cd)
- [Firebase CLI Reference](https://firebase.google.com/docs/cli)

---

## 📝 Чеклист для першого запуску

- [ ] Створено проект на Bitrise
- [ ] Додано `FIREBASE_APP_ID_ANDROID` в Secrets
- [ ] Згенеровано та додано `FIREBASE_TOKEN` в Secrets
- [ ] Створено групу **testers** в Firebase Console
- [ ] Додано email тестувальників
- [ ] Завантажено `bitrise.yml` в репозиторій
- [ ] Виконано push до `main` branch
- [ ] Перевірено успішність збірки
- [ ] Тестувальники отримали email запрошення
- [ ] APK встановлюється на пристрій

---

**Готово! 🎉 Ваш CI/CD pipeline налаштований для Tracker Costs**
