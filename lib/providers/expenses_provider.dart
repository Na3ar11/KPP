import 'package:flutter/material.dart';
import '../models/expense.dart';
import 'dart:math';

enum LoadingState {
  idle,
  loading,
  success,
  error,
}
//абоба 2 
class ExpensesProvider extends ChangeNotifier {
  List<Expense> _expenses = [];
  LoadingState _loadingState = LoadingState.idle;
  String? _errorMessage;
  double _budget = 15000.0; 

  List<Expense> get expenses => List.unmodifiable(_expenses);
  LoadingState get loadingState => _loadingState;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _loadingState == LoadingState.loading;
  bool get hasError => _loadingState == LoadingState.error;
  double get budget => _budget;

  
  double get balance => _budget - totalAmount;

  
  List<Expense> getExpensesByCategory(String category) {
    return _expenses.where((e) => e.category == category).toList();
  }


  double get totalAmount {
    return _expenses.fold(0, (sum, expense) => sum + expense.amount);
  }


  double get todayAmount {
    final today = DateTime.now();
    return _expenses
        .where((e) =>
            e.date.year == today.year &&
            e.date.month == today.month &&
            e.date.day == today.day)
        .fold(0, (sum, expense) => sum + expense.amount);
  }

  double get weekAmount {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    return _expenses
        .where((e) => e.date.isAfter(weekAgo))
        .fold(0, (sum, expense) => sum + expense.amount);
  }

  double get monthAmount {
    final now = DateTime.now();
    return _expenses
        .where((e) => e.date.year == now.year && e.date.month == now.month)
        .fold(0, (sum, expense) => sum + expense.amount);
  }

  void setBudget(double newBudget) {
    _budget = newBudget;
    notifyListeners();
  }

  List<Expense> get recentExpenses {
    final sorted = List<Expense>.from(_expenses);
    sorted.sort((a, b) => b.date.compareTo(a.date));
    return sorted.take(3).toList();
  }

  Future<void> loadExpenses() async {
    _loadingState = LoadingState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      await Future.delayed(const Duration(seconds: 1));

      _expenses = _generateMockExpenses();

      _loadingState = LoadingState.success;
      notifyListeners();
    } catch (e) {
      _loadingState = LoadingState.error;
      _errorMessage = 'Помилка завантаження витрат: ${e.toString()}';
      notifyListeners();
    }
  }

  Future<void> addExpense(Expense expense) async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));

      _expenses.insert(0, expense);
      notifyListeners();
    } catch (e) {
      throw Exception('Помилка додавання витрати: ${e.toString()}');
    }
  }

  Future<void> deleteExpense(String id) async {
    try {
      await Future.delayed(const Duration(milliseconds: 300));

      _expenses.removeWhere((expense) => expense.id == id);
      notifyListeners();
    } catch (e) {
      throw Exception('Помилка видалення витрати: ${e.toString()}');
    }
  }

  Future<void> updateExpense(Expense expense) async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));

      final index = _expenses.indexWhere((e) => e.id == expense.id);
      if (index != -1) {
        _expenses[index] = expense;
        notifyListeners();
      }
    } catch (e) {
      throw Exception('Помилка оновлення витрати: ${e.toString()}');
    }
  }

  Future<void> retry() async {
    await loadExpenses();
  }

  // Генерація тестових витрат
  List<Expense> _generateMockExpenses() {
    final random = Random();
    final now = DateTime.now();

    final categories = [
      {'name': 'Їжа', 'icon': '🍕', 'color': const Color(0xFFE53E3E)},
      {'name': 'Транспорт', 'icon': '🚕', 'color': const Color(0xFF3182CE)},
      {'name': 'Покупки', 'icon': '🛒', 'color': const Color(0xFF38A169)},
      {'name': 'Здоров\'я', 'icon': '💊', 'color': const Color(0xFFD69E2E)},
      {'name': 'Розваги', 'icon': '🎬', 'color': const Color(0xFF4A5568)},
      {'name': 'Дім', 'icon': '🏠', 'color': const Color(0xFF2D3748)},
      {'name': 'Освіта', 'icon': '📚', 'color': const Color(0xFF38B2AC)},
    ];

    final descriptions = {
      'Їжа': ['Обід у ресторані', 'Кава', 'Сніданок', 'Вечеря', 'Перекус'],
      'Транспорт': ['Таксі', 'Метро', 'Автобус', 'Паркінг', 'Бензин'],
      'Покупки': ['Продукти', 'Одяг', 'Взуття', 'Електроніка', 'Подарунки'],
      'Здоров\'я': ['Ліки', 'Аптека', 'Лікар', 'Вітаміни', 'Спортзал'],
      'Розваги': ['Кіно', 'Театр', 'Концерт', 'Ігри', 'Книги'],
      'Дім': ['Комунальні', 'Ремонт', 'Меблі', 'Побутова хімія', 'Декор'],
      'Освіта': ['Курси', 'Книги', 'Навчальні матеріали', 'Семінар', 'Тренінг'],
    };

    final expenses = <Expense>[];


    final count = 15 + random.nextInt(6);

    for (int i = 0; i < count; i++) {
      final category = categories[random.nextInt(categories.length)];
      final categoryName = category['name'] as String;
      final categoryDescriptions = descriptions[categoryName]!;

      expenses.add(Expense(
        id: 'exp_${DateTime.now().millisecondsSinceEpoch}_$i',
        icon: category['icon'] as String,
        category: categoryName,
        description: categoryDescriptions[random.nextInt(categoryDescriptions.length)],
        amount: (50 + random.nextInt(950)).toDouble(), // 50 до 1000 грн (позитивне число)
        color: category['color'] as Color,
        date: now.subtract(Duration(days: random.nextInt(30))),
      ));
    }


    expenses.sort((a, b) => b.date.compareTo(a.date));

    return expenses;
  }
}
