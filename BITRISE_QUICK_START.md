# Bitrise CI/CD - Швидкий старт

## Крок 1: Згенеруй Firebase токен

```bash
npm install -g firebase-tools
firebase login:ci
```

Скопіюй токен з консолі (починається з `1//0...`)

## Крок 2: Додай Secrets в Bitrise

1. Відкрий: https://app.bitrise.io
2. Вибери свій проект
3. Перейди: **Workflow Editor** → **Secrets** (вкладка зліва)
4. Додай 2 секрети:

### Secret 1: FIREBASE_APP_ID_ANDROID
```
Key: FIREBASE_APP_ID_ANDROID
Value: 1:98211696497:android:6829066851715285e630d0
Expose for Pull Requests: OFF
```

### Secret 2: FIREBASE_TOKEN
```
Key: FIREBASE_TOKEN
Value: [твій токен з кроку 1]
Expose for Pull Requests: OFF
```

## Крок 3: Запуш код в GitHub

```bash
git add bitrise.yml BITRISE_*.md
git commit -m "Add Bitrise CI/CD configuration"
git push origin main
```

## Крок 4: Запусти білд

1. Bitrise автоматично запустить білд після push
2. АБО запусти вручну: **Start/Schedule a Build** → Workflow: `android_firebase` → Branch: `main`

## Крок 5: Створи групу тестерів в Firebase

1. Firebase Console: https://console.firebase.google.com/project/tracker-costs
2. Перейди: **App Distribution** → **Testers & Groups**
3. Натисни **Create Group**
4. Назва: `testers`
5. Додай email адреси тестерів
6. Збережи

## Результат

Після успішного білду:
- ✅ APK буде зібрано
- ✅ APK буде завантажено в Firebase App Distribution
- ✅ Тестери з групи "testers" отримають email з посиланням
- ✅ Артефакти (APK, звіти) доступні в Bitrise

## Перевірка статусу

- **Bitrise Builds**: https://app.bitrise.io/builds
- **Firebase Distribution**: https://console.firebase.google.com/project/tracker-costs/appdistribution

## Troubleshooting

### "FIREBASE_APP_ID_ANDROID is not set"
→ Додай секрет в Bitrise (див. Крок 2)

### "FIREBASE_TOKEN is not set"
→ Згенеруй токен: `firebase login:ci` і додай в Secrets

### "Tester group 'testers' not found"
→ Створи групу в Firebase Console (див. Крок 5)

### Build fails на Flutter analyze
→ Це попередження, білд продовжиться. Виправ помилки аналізу пізніше.

---

**Готово!** Твій CI/CD pipeline налаштований і готовий до роботи 🚀
