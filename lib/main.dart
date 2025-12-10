import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'repositories/auth_repository.dart';
import 'repositories/expenses_repository.dart';
import 'repositories/user_settings_repository.dart';
import 'providers/firestore_expenses_provider.dart';
import 'providers/user_settings_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Ініціалізація Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Налаштування Crashlytics
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  
  static FirebaseAnalytics analytics = FirebaseAnalytics.instance;
  static FirebaseAnalyticsObserver observer = 
      FirebaseAnalyticsObserver(analytics: analytics);

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
        title: 'Expense Tracker',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.deepPurple,
          useMaterial3: true,
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        navigatorObservers: <NavigatorObserver>[observer],
        home: const AuthWrapper(),
      ),
    );
  }
}


class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authRepository = AuthRepository();
    
    return StreamBuilder(
      stream: authRepository.authStateChanges,
      builder: (context, snapshot) {

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        

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