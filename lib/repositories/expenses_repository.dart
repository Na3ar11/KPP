import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/expense.dart';

/// Абстрактний клас для роботи з витратами
abstract class ExpensesRepository {
  /// Отримати список витрат користувача
  Stream<List<Expense>> getExpensesStream(String userId);
  
  /// Отримати витрати за певний період
  Future<List<Expense>> getExpensesByDateRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  );
  
  /// Отримати витрати за категорією
  Future<List<Expense>> getExpensesByCategory(String userId, String category);
  
  /// Отримати конкретну витрату
  Future<Expense?> getExpenseById(String expenseId);
  
  /// Додати нову витрату
  Future<String> addExpense(Expense expense);
  
  /// Оновити існуючу витрату
  Future<void> updateExpense(Expense expense);
  
  /// Видалити витрату
  Future<void> deleteExpense(String expenseId);
  
  /// Отримати загальну суму витрат за період
  Future<double> getTotalAmount(String userId, DateTime startDate, DateTime endDate);
}

/// Реалізація репозиторію через Firestore
class FirestoreExpensesRepository implements ExpensesRepository {
  final FirebaseFirestore _firestore;
  
  // Назва колекції в Firestore
  static const String _collectionName = 'expenses';
  
  FirestoreExpensesRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;
  
  /// Отримання посилання на колекцію
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
  Future<List<Expense>> getExpensesByDateRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final querySnapshot = await _collection
          .where('userId', isEqualTo: userId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('date', descending: true)
          .get();
      
      return querySnapshot.docs
          .map((doc) => Expense.fromFirestoreQuery(doc))
          .toList();
    } catch (e) {
      throw Exception('Помилка отримання витрат за період: $e');
    }
  }
  
  @override
  Future<List<Expense>> getExpensesByCategory(
    String userId,
    String category,
  ) async {
    try {
      final querySnapshot = await _collection
          .where('userId', isEqualTo: userId)
          .where('category', isEqualTo: category)
          .orderBy('date', descending: true)
          .get();
      
      return querySnapshot.docs
          .map((doc) => Expense.fromFirestoreQuery(doc))
          .toList();
    } catch (e) {
      throw Exception('Помилка отримання витрат за категорією: $e');
    }
  }
  
  @override
  Future<Expense?> getExpenseById(String expenseId) async {
    try {
      final doc = await _collection.doc(expenseId).get();
      
      if (!doc.exists) {
        return null;
      }
      
      return Expense.fromFirestore(doc);
    } catch (e) {
      throw Exception('Помилка отримання витрати: $e');
    }
  }
  
  @override
  Future<String> addExpense(Expense expense) async {
    try {
      // Створюємо новий документ з автогенерованим ID
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
  
  @override
  Future<double> getTotalAmount(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final expenses = await getExpensesByDateRange(userId, startDate, endDate);
      return expenses.fold<double>(0.0, (sum, expense) => sum + expense.amount);
    } catch (e) {
      throw Exception('Помилка обчислення загальної суми: $e');
    }
  }
  
  /// Додаткові методи для статистики
  
  /// Отримати витрати за сьогодні
  Future<List<Expense>> getTodayExpenses(String userId) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
    
    return getExpensesByDateRange(userId, startOfDay, endOfDay);
  }
  
  /// Отримати витрати за тиждень
  Future<List<Expense>> getWeekExpenses(String userId) async {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    
    return getExpensesByDateRange(userId, weekAgo, now);
  }
  
  /// Отримати витрати за місяць
  Future<List<Expense>> getMonthExpenses(String userId) async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    
    return getExpensesByDateRange(userId, startOfMonth, endOfMonth);
  }
  
  /// Отримати статистику по категоріях за період
  Future<Map<String, double>> getCategoryStatistics(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final expenses = await getExpensesByDateRange(userId, startDate, endDate);
      final Map<String, double> categoryTotals = {};
      
      for (var expense in expenses) {
        categoryTotals[expense.category] = 
            (categoryTotals[expense.category] ?? 0) + expense.amount;
      }
      
      return categoryTotals;
    } catch (e) {
      throw Exception('Помилка отримання статистики: $e');
    }
  }
}
