# 🔐 Bitrise Secrets - Повна документація для Tracker Costs

## 📋 Обов'язкові Secrets

### 1. Firebase App Distribution

| Secret Key | Value | Опис | Як отримати |
|------------|-------|------|-------------|
| `FIREBASE_APP_ID_ANDROID` | `1:98211696497:android:6829066851715285e630d0` | Firebase Android App ID | Firebase Console → Project Settings → Your apps → Android app |
| `FIREBASE_TOKEN` | `your-ci-token-here` | Firebase CI/CD токен для автоматичного деплою | Виконати: `firebase login:ci` |

---

### 2. Google Services Configuration

| Secret Key | Value | Опис | Як отримати |
|------------|-------|------|-------------|
| `GOOGLE_SERVICES_JSON_BASE64` | `base64-encoded-json` | (Опціонально) google-services.json закодований в base64 | Див. інструкцію нижче |

> **Примітка:** Якщо `google-services.json` вже є в репозиторії (`android/app/google-services.json`), цей Secret **не обов'язковий**. Використовуйте його тільки якщо хочете тримати конфігурацію Firebase поза Git.

---

### 3. SSH для Git (автоматично від Bitrise)

| Secret Key | Value | Опис |
|------------|-------|------|
| `SSH_RSA_PRIVATE_KEY` | `auto-generated` | SSH ключ для доступу до приватного репозиторію |

> **Примітка:** Bitrise автоматично генерує цей ключ при підключенні GitHub репозиторію. Не потрібно додавати вручну.

---

## 🔒 Опціональні Secrets (для Production)

### 4. Android Signing (Release APK)

> **Поточний стан:** Ваш проект використовує **debug signing** для release builds.  
> Для production builds **обов'язково** створіть keystore і додайте ці Secrets:

| Secret Key | Value | Опис | Як отримати |
|------------|-------|------|-------------|
| `BITRISEIO_ANDROID_KEYSTORE_URL` | `https://...` | URL до upload keystore | Завантажити keystore на Bitrise |
| `BITRISEIO_ANDROID_KEYSTORE_PASSWORD` | `your-keystore-password` | Пароль keystore файлу | З вашого keystore |
| `BITRISEIO_ANDROID_KEYSTORE_ALIAS` | `upload` | Alias ключа в keystore | З вашого keystore |
| `BITRISEIO_ANDROID_KEYSTORE_PRIVATE_KEY_PASSWORD` | `your-key-password` | Пароль приватного ключа | З вашого keystore |

**Статус:** ⚠️ **НЕ НАЛАШТОВАНО** (поки використовується debug signing)

---

## 📊 Детальна інформація про кожен Secret

### 🔥 FIREBASE_APP_ID_ANDROID

**Значення:** `1:98211696497:android:6829066851715285e630d0`

**Де знайти:**
1. Відкрийте [Firebase Console](https://console.firebase.google.com/project/tracker-costs)
2. Клацніть на шестерню ⚙️ → **Project Settings**
3. Прокрутіть до секції **Your apps**
4. Виберіть Android app (📱 com.example.tracker_costs)
5. Скопіюйте **App ID**

**Для чого:**
- Ідентифікує ваш Android додаток в Firebase
- Використовується для завантаження APK в Firebase App Distribution
- Обов'язковий для роботи Firebase CLI

---

### 🔑 FIREBASE_TOKEN

**Як отримати:**

```bash
# 1. Встановити Firebase CLI (якщо ще не встановлено)
npm install -g firebase-tools

# 2. Залогінитись через браузер і отримати CI token
firebase login:ci
```

**Виведе щось типу:**
```
✔ Success! Use this token to login on a CI server:

1//0abcdefghijklmnopqrstuvwxyz1234567890ABCDEFG

Example: firebase deploy --token "$FIREBASE_TOKEN"
```

**Скопіюйте токен** і додайте як `FIREBASE_TOKEN` в Bitrise Secrets.

**Для чого:**
- Автентифікація Firebase CLI на CI/CD сервері
- Дозволяє автоматично завантажувати APK в App Distribution
- Без нього неможливий deploy на Firebase

**Термін дії:** Токен не має терміну дії, але може бути відкликаний вручну.

**Відкликання (якщо скомпрометовано):**
```bash
firebase logout --token "YOUR_OLD_TOKEN"
firebase login:ci  # Отримати новий
```

---

### 📄 GOOGLE_SERVICES_JSON_BASE64 (опціонально)

**Коли використовувати:**
- Якщо НЕ хочете зберігати `google-services.json` в Git репозиторії
- Для різних конфігурацій (dev/staging/prod)
- Для безпеки (щоб Firebase API ключі не були публічні)

**Як закодувати:**

**Windows PowerShell:**
```powershell
# Перейти в директорію проєкту
cd D:\Project_KPP\tracker_costs

# Закодувати файл в base64 і скопіювати в буфер
[Convert]::ToBase64String([IO.File]::ReadAllBytes("android\app\google-services.json")) | Set-Clipboard

# Вивести на екран (якщо Set-Clipboard не працює)
[Convert]::ToBase64String([IO.File]::ReadAllBytes("android\app\google-services.json"))
```

**Linux/macOS:**
```bash
# Закодувати і скопіювати
base64 -i android/app/google-services.json | pbcopy

# Вивести на екран
base64 -i android/app/google-services.json
```

**Git Bash (Windows):**
```bash
base64 android/app/google-services.json | clip
```

**Результат буде виглядати як:**
```
ewogICJwcm9qZWN0X2luZm8iOiB7CiAgICAicHJvamVjdF9udW1iZXIiOiAiOTgy...
```

**Додати в Bitrise:**
1. Скопіюйте весь base64 текст
2. Bitrise → Workflow Editor → Secrets
3. Add new secret:
   - Key: `GOOGLE_SERVICES_JSON_BASE64`
   - Value: (вставте base64 текст)
   - ✅ Expose for Pull Requests: NO
4. Save

**Що робить bitrise.yml:**
```bash
# Автоматично декодує і створює файл
echo "$GOOGLE_SERVICES_JSON_BASE64" | base64 -d > android/app/google-services.json
```

**Примітка:** У вашому випадку `google-services.json` вже є в репозиторії, тому цей Secret **не обов'язковий**.

---

## 🔐 Android Keystore для Production (TODO)

### Чому потрібен Keystore?

Зараз ваш `build.gradle.kts` використовує **debug signing**:
```kotlin
buildTypes {
    release {
        signingConfig = signingConfigs.getByName("debug")  // ⚠️ НЕ для production!
    }
}
```

**Проблеми debug signing:**
- ❌ APK не можна завантажити в Google Play Store
- ❌ Інші розробники можуть підписати APK тим самим ключем
- ❌ Небезпечно для production

### Створення Keystore

**1. Згенерувати keystore:**
```bash
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

**Приклад заповнення:**
```
Enter keystore password: [ваш_пароль_keystore]
Re-enter new password: [ваш_пароль_keystore]
What is your first and last name?
  [Unknown]:  Nazarii
What is the name of your organizational unit?
  [Unknown]:  Tracker Costs
What is the name of your organization?
  [Unknown]:  Tracker Costs
What is the name of your City or Locality?
  [Unknown]:  Lviv
What is the name of your State or Province?
  [Unknown]:  Lviv
What is the two-letter country code for this unit?
  [Unknown]:  UA
Is CN=Nazarii, OU=Tracker Costs, O=Tracker Costs, L=Lviv, ST=Lviv, C=UA correct?
  [no]:  yes

Enter key password for <upload>
        (RETURN if same as keystore password): [ваш_пароль_ключа]
```

**2. Створити `android/key.properties`:**
```properties
storePassword=ваш_пароль_keystore
keyPassword=ваш_пароль_ключа
keyAlias=upload
storeFile=upload-keystore.jks
```

**3. Оновити `android/app/build.gradle.kts`:**
```kotlin
// Додати на початку файлу
import java.util.Properties
import java.io.FileInputStream

// Після android {
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    // ... інші налаштування
    
    // Додати signingConfigs
    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?
            storeFile = keystoreProperties["storeFile"]?.let { file(it) }
            storePassword = keystoreProperties["storePassword"] as String?
        }
    }
    
    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")  // ✅ Використовувати release signing
        }
    }
}
```

**4. Додати в `.gitignore`:**
```
# Keystore files
*.jks
*.keystore
key.properties
```

**5. Завантажити keystore на Bitrise:**
1. Bitrise → Workflow Editor → **Code Signing**
2. Android Keystore file → **Upload**
3. Завантажте `upload-keystore.jks`
4. Bitrise автоматично створить `BITRISEIO_ANDROID_KEYSTORE_URL`

**6. Додати Secrets на Bitrise:**
```
BITRISEIO_ANDROID_KEYSTORE_PASSWORD = [пароль з key.properties]
BITRISEIO_ANDROID_KEYSTORE_ALIAS = upload
BITRISEIO_ANDROID_KEYSTORE_PRIVATE_KEY_PASSWORD = [пароль ключа]
```

**7. Оновити bitrise.yml:**
```yaml
# Додати step перед Build APK
- script@1:
    title: Setup Keystore
    inputs:
    - content: |-
        #!/usr/bin/env bash
        set -e
        
        echo "Setting up release keystore..."
        
        # Download keystore
        wget -O android/app/upload-keystore.jks "$BITRISEIO_ANDROID_KEYSTORE_URL"
        
        # Create key.properties
        cat > android/key.properties << EOF
        storePassword=$BITRISEIO_ANDROID_KEYSTORE_PASSWORD
        keyPassword=$BITRISEIO_ANDROID_KEYSTORE_PRIVATE_KEY_PASSWORD
        keyAlias=$BITRISEIO_ANDROID_KEYSTORE_ALIAS
        storeFile=upload-keystore.jks
        EOF
        
        echo "✅ Keystore configured"
```

---

## 📋 Додавання Secrets в Bitrise

### Крок за кроком:

1. **Відкрийте Bitrise Dashboard**
   - Перейдіть на [app.bitrise.io](https://app.bitrise.io)
   - Виберіть проект **Tracker Costs**

2. **Перейдіть до Secrets**
   - Клацніть **Workflow Editor** (ліва панель)
   - Виберіть вкладку **Secrets** (вгорі)

3. **Додайте кожен Secret:**
   - Клацніть **+ Add new**
   - **Key**: Назва змінної (наприклад, `FIREBASE_TOKEN`)
   - **Value**: Значення секрету
   - **Expose for Pull Requests**: ❌ NO (для безпеки)
   - Клацніть **Add**

4. **Повторіть для всіх обов'язкових Secrets**

---

## ✅ Чеклист Secrets

### Мінімальна конфігурація (для поточного стану):

- [x] `FIREBASE_APP_ID_ANDROID` = `1:98211696497:android:6829066851715285e630d0`
- [x] `FIREBASE_TOKEN` = (згенерувати через `firebase login:ci`)
- [ ] `GOOGLE_SERVICES_JSON_BASE64` = (опціонально, файл вже в Git)

### Production конфігурація (рекомендовано):

- [ ] `BITRISEIO_ANDROID_KEYSTORE_URL` = (після створення keystore)
- [ ] `BITRISEIO_ANDROID_KEYSTORE_PASSWORD` = (пароль keystore)
- [ ] `BITRISEIO_ANDROID_KEYSTORE_ALIAS` = `upload`
- [ ] `BITRISEIO_ANDROID_KEYSTORE_PRIVATE_KEY_PASSWORD` = (пароль ключа)

---

## 🔍 Перевірка Secrets

Після додавання всіх Secrets, запустіть тестову збірку:

1. **Manual Build:**
   - Bitrise → **Start/Schedule a Build**
   - Workflow: `android_firebase`
   - Branch: `main`
   - **Start Build**

2. **Перевірте логи:**
   - Step "Verify Firebase App ID" покаже чи всі Secrets налаштовані
   - Помилки типу "FIREBASE_TOKEN is not set" означають що Secret не додано

3. **Успішна збірка:**
   - ✅ APK створено
   - ✅ Завантажено в Firebase App Distribution
   - ✅ Тестувальники отримали email

---

## 🆘 Troubleshooting

### ❌ "FIREBASE_TOKEN is not set"
**Рішення:** Додайте Secret `FIREBASE_TOKEN` з токеном від `firebase login:ci`

### ❌ "Invalid Firebase token"
**Рішення:** Токен застарів. Згенеруйте новий:
```bash
firebase logout --token "OLD_TOKEN"
firebase login:ci
```

### ❌ "google-services.json not found"
**Рішення:** Файл є в репозиторії, переконайтесь що він не в `.gitignore`

### ❌ "Failed to sign APK"
**Рішення:** Keystore не налаштований. Поки залиште debug signing або створіть release keystore.

---

## 📊 Підсумок

### Обов'язкові зараз (2 Secrets):
1. ✅ `FIREBASE_APP_ID_ANDROID`
2. ✅ `FIREBASE_TOKEN`

### Для production (4+ Secrets):
3. 🔒 Keystore Secrets (4 штуки)
4. 📄 `GOOGLE_SERVICES_JSON_BASE64` (опціонально)

**Всього мінімально:** 2 Secrets  
**Для production:** 6-7 Secrets

---

## 🔗 Корисні посилання

- [Bitrise Secrets Documentation](https://devcenter.bitrise.io/en/builds/secrets.html)
- [Firebase CI/CD Token](https://firebase.google.com/docs/cli#cli-ci-systems)
- [Android App Signing](https://developer.android.com/studio/publish/app-signing)
- [Bitrise Android Code Signing](https://devcenter.bitrise.io/en/code-signing/android-code-signing.html)
