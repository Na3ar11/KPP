import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/expense.dart';
import '../repositories/expenses_repository.dart';

enum LoadingState {
  idle,
  loading,
  success,
  error,
}

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
  LoadingState get loadingState => _loadingState;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _loadingState == LoadingState.loading;
  bool get hasError => _loadingState == LoadingState.error;
  double get budget => _budget;
  double get balance => _budget - totalAmount;
  
  // ID поточного користувача
  String? get userId => _auth.currentUser?.uid;
  
  // Обчислені властивості
  double get totalAmount {
    return _expenses.fold<double>(0, (sum, expense) => sum + expense.amount);
  }
  
  double get todayAmount {
    final today = DateTime.now();
    return _expenses
        .where((e) =>
            e.date.year == today.year &&
            e.date.month == today.month &&
            e.date.day == today.day)
        .fold<double>(0, (sum, expense) => sum + expense.amount);
  }
  
  double get weekAmount {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    return _expenses
        .where((e) => e.date.isAfter(weekAgo))
        .fold<double>(0, (sum, expense) => sum + expense.amount);
  }
  
  double get monthAmount {
    final now = DateTime.now();
    return _expenses
        .where((e) => e.date.year == now.year && e.date.month == now.month)
        .fold<double>(0, (sum, expense) => sum + expense.amount);
  }
  
  List<Expense> get recentExpenses {
    final sorted = List<Expense>.from(_expenses);
    sorted.sort((a, b) => b.date.compareTo(a.date));
    return sorted.take(3).toList();
  }
  
  List<Expense> getExpensesByCategory(String category) {
    return _expenses.where((e) => e.category == category).toList();
  }
  
  // Методи для роботи з бюджетом
  void setBudget(double newBudget) {
    _budget = newBudget;
    notifyListeners();
  }
  
  /// Ініціалізація - підписка на зміни витрат в реальному часі
  Future<void> initializeExpenses() async {
    if (userId == null) {
      _loadingState = LoadingState.error;
      _errorMessage = 'Користувач не авторизований';
      notifyListeners();
      return;
    }
    
    _loadingState = LoadingState.loading;
    _errorMessage = null;
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
      // Створюємо витрату з userId
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
    if (userId == null) {
      throw Exception('Користувач не авторизований');
    }
    
    try {
      // Оновлюємо витрату з новим часом оновлення
      final updatedExpense = expense.copyWith(
        updatedAt: DateTime.now(),
      );
      
      await _repository.updateExpense(updatedExpense);
    } catch (e) {
      throw Exception('Помилка оновлення витрати: $e');
    }
  }
  
  /// Видалити витрату
  Future<void> deleteExpense(String expenseId) async {
    if (userId == null) {
      throw Exception('Користувач не авторизований');
    }
    
    try {
      await _repository.deleteExpense(expenseId);
    } catch (e) {
      throw Exception('Помилка видалення витрати: $e');
    }
  }
  
  /// Повторна спроба завантаження
  Future<void> retry() async {
    await initializeExpenses();
  }
  
  /// Завантажити витрати за період (без стріму)
  Future<List<Expense>> getExpensesByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    if (userId == null) {
      throw Exception('Користувач не авторизований');
    }
    
    try {
      return await _repository.getExpensesByDateRange(
        userId!,
        startDate,
        endDate,
      );
    } catch (e) {
      throw Exception('Помилка завантаження витрат за період: $e');
    }
  }
  
  /// Отримати статистику по категоріях
  Future<Map<String, double>> getCategoryStatistics(
    DateTime startDate,
    DateTime endDate,
  ) async {
    if (userId == null) {
      throw Exception('Користувач не авторизований');
    }
    
    try {
      final repository = _repository as FirestoreExpensesRepository;
      return await repository.getCategoryStatistics(
        userId!,
        startDate,
        endDate,
      );
    } catch (e) {
      throw Exception('Помилка отримання статистики: $e');
    }
  }
  
  @override
  void dispose() {
    // Відписуємось від стріму при знищенні Provider
    _expensesSubscription?.cancel();
    super.dispose();
  }
}
