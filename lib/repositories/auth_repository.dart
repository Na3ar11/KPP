import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';

class AuthRepository {
  static final AuthRepository _instance = AuthRepository._internal();
  factory AuthRepository() => _instance;
  AuthRepository._internal();
  
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  
  // Завжди доступний - працює через Firebase Auth Provider!
  bool get isGoogleSignInAvailable => true;
  
  User? get currentUser => _firebaseAuth.currentUser;
  
  String get userName {
    final user = currentUser;
    if (user?.displayName != null && user!.displayName!.isNotEmpty) {
      return user.displayName!;
    }
    if (user?.email != null) {
      return user!.email!.split('@')[0];
    }
    return 'Користувач';
  }
  
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();
  Future<UserCredential> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      await userCredential.user?.updateDisplayName(name);
      await userCredential.user?.reload();
      
      try {
        await userCredential.user?.sendEmailVerification();
      } catch (e) {
        print('⚠️ Email verification failed: $e');
      }
      
      await _analytics.logSignUp(signUpMethod: 'email');
      
      await FirebaseCrashlytics.instance.setUserIdentifier(
        userCredential.user?.uid ?? 'unknown',
      );
      
      return userCredential;
      
    } on FirebaseAuthException catch (e) {
      await FirebaseCrashlytics.instance.recordError(
        e,
        StackTrace.current,
        reason: 'Sign up failed',
      );
      throw _handleAuthException(e);
    } catch (e) {
      await FirebaseCrashlytics.instance.recordError(
        e,
        StackTrace.current,
        reason: 'Unexpected sign up error',
      );
      throw 'Невідома помилка при реєстрації';
    }
  }
  
  /// Вхід через Email та Password
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      await _analytics.logLogin(loginMethod: 'email');
      
      await FirebaseCrashlytics.instance.setUserIdentifier(
        userCredential.user?.uid ?? 'unknown',
      );
      
      return userCredential;
      
    } on FirebaseAuthException catch (e) {
      await FirebaseCrashlytics.instance.recordError(
        e,
        StackTrace.current,
        reason: 'Sign in failed',
      );
      throw _handleAuthException(e);
    } catch (e) {
      await FirebaseCrashlytics.instance.recordError(
        e,
        StackTrace.current,
        reason: 'Unexpected sign in error',
      );
      throw 'Невідома помилка при вході';
    }
  }
  
  
  Future<UserCredential> signInWithGoogle() async {
    print('🔵 Starting Google Sign In...');
    
    try {
      UserCredential userCredential;
      
      if (kIsWeb) {
        print('🔵 Using Firebase Auth for Web');
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        googleProvider.addScope('profile');
        googleProvider.setCustomParameters({'prompt': 'select_account'});
        
        try {
          userCredential = await _firebaseAuth.signInWithPopup(googleProvider);
        } catch (e) {
          print('🔵 Popup blocked, trying redirect');
          await _firebaseAuth.signInWithRedirect(googleProvider);
          throw 'Перенаправлення до Google...';
        }
      } else {
        print('🔵 Using Google Sign In package for Native platforms');
        final GoogleSignIn googleSignIn = GoogleSignIn(
          scopes: ['email', 'profile'],
        );
        
       
        await googleSignIn.signOut();
        
        
        final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
        
        if (googleUser == null) {
          throw 'Вхід скасовано користувачем';
        }
        
        print('✅ Google user selected: ${googleUser.email}');
        
        // Отримуємо токени автентифікації
        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        
        // Створюємо credentials для Firebase
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        
        // Входимо в Firebase з цими credentials
        userCredential = await _firebaseAuth.signInWithCredential(credential);
      }
      
      print('✅ Google Sign In successful!');
      print('✅ User: ${userCredential.user?.email}');
      print('✅ Display Name: ${userCredential.user?.displayName}');
      
      await _analytics.logLogin(loginMethod: 'google');
      
      await FirebaseCrashlytics.instance.setUserIdentifier(
        userCredential.user?.uid ?? 'unknown',
      );
      
      return userCredential;
      
    } on FirebaseAuthException catch (e) {
      print('❌ FirebaseAuthException: ${e.code}');
      print('❌ Message: ${e.message}');
      
      await FirebaseCrashlytics.instance.recordError(
        e,
        StackTrace.current,
        reason: 'Google sign in failed',
      );
      
      if (e.code == 'popup-closed-by-user' || 
          e.code == 'cancelled-popup-request' ||
          e.code == 'user-cancelled') {
        throw 'Вхід скасовано користувачем';
      }
      
      throw _handleAuthException(e);
    } catch (e) {
      print('❌ Unexpected error: $e');
      
      await FirebaseCrashlytics.instance.recordError(
        e,
        StackTrace.current,
        reason: 'Unexpected Google sign in error',
      );
      
      if (e.toString().contains('popup_closed_by_user') ||
          e.toString().contains('user_cancelled')) {
        throw 'Вхід скасовано користувачем';
      }
      
      throw 'Помилка входу через Google: ${e.toString()}';
    }
  }
  
  Future<UserCredential?> checkRedirectResult() async {
    try {
      print('🔵 Checking for redirect result...');
      final result = await _firebaseAuth.getRedirectResult();
      
      if (result.user != null) {
        print('✅ Found redirect result!');
        print('✅ User: ${result.user?.email}');
        
        await _analytics.logLogin(loginMethod: 'google_redirect');
        
        await FirebaseCrashlytics.instance.setUserIdentifier(
          result.user?.uid ?? 'unknown',
        );
        
        return result;
      }
      
      print('ℹ️ No redirect result found');
      return null;
    } catch (e) {
      print('❌ Error checking redirect result: $e');
      return null;
    }
  }
  
  Future<void> signOut() async {
    try {
      await _analytics.logEvent(name: 'logout');
      await _firebaseAuth.signOut();
    } catch (e) {
      await FirebaseCrashlytics.instance.recordError(
        e,
        StackTrace.current,
        reason: 'Sign out failed',
      );
      throw 'Помилка при виході';
    }
  }
  
  /// Скидання пароля
  Future<void> resetPassword({required String email}) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
      
      await _analytics.logEvent(
        name: 'password_reset_requested',
        parameters: {'email': email},
      );
      
    } on FirebaseAuthException catch (e) {
      await FirebaseCrashlytics.instance.recordError(
        e,
        StackTrace.current,
        reason: 'Password reset failed',
      );
      throw _handleAuthException(e);
    }
  }
  
  /// Обробка помилок Firebase Auth
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'Пароль занадто слабкий (мінімум 6 символів)';
      case 'email-already-in-use':
        return 'Email вже використовується';
      case 'invalid-email':
        return 'Некоректний email';
      case 'user-disabled':
        return 'Користувач заблокований';
      case 'user-not-found':
        return 'Користувача не знайдено';
      case 'wrong-password':
        return 'Невірний пароль';
      case 'too-many-requests':
        return 'Занадто багато спроб. Спробуйте пізніше';
      case 'operation-not-allowed':
        return 'Операція не дозволена. Увімкніть метод авторизації в Firebase Console';
      case 'network-request-failed':
        return 'Помилка мережі. Перевірте підключення до інтернету';
      case 'popup-blocked':
        return 'Браузер заблокував popup. Дозвольте popup для цього сайту';
      case 'popup-closed-by-user':
        return 'Вхід скасовано користувачем';
      case 'unauthorized-domain':
        return 'Домен не авторизований в Firebase Console';
      case 'invalid-credential':
        return 'Невірні дані для входу';
      default:
        return 'Помилка: ${e.message ?? e.code}';
    }
  }
}