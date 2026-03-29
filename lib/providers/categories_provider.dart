import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/category.dart';
import '../repositories/categories_repository.dart';

class CategoriesProvider extends ChangeNotifier {
  final CategoriesRepository _repository;
  final FirebaseAuth _auth;

  List<Category> _categories = [];
  bool _isLoading = false;
  bool _includeArchived = false;
  String? _errorMessage;
  StreamSubscription<List<Category>>? _categoriesSubscription;

  CategoriesProvider({
    required CategoriesRepository repository,
    FirebaseAuth? auth,
  }) : _repository = repository,
       _auth = auth ?? FirebaseAuth.instance;

  List<Category> get categories => List.unmodifiable(_categories);
  bool get isLoading => _isLoading;
  bool get includeArchived => _includeArchived;
  String? get errorMessage => _errorMessage;
  String? get userId => _auth.currentUser?.uid;

  double get totalBudget => _categories.fold<double>(
    0,
    (sum, category) => sum + category.monthlyBudget,
  );

  Category? getCategoryById(String id) {
    try {
      return _categories.firstWhere((category) => category.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> initialize({bool includeArchived = false}) async {
    if (userId == null) {
      _categories = [];
      _errorMessage = 'Користувач не авторизований';
      notifyListeners();
      return;
    }

    _includeArchived = includeArchived;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    await _categoriesSubscription?.cancel();

    try {
      await _repository.ensureDefaultCategories(userId!);
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Помилка створення дефолтних категорій: $e';
      notifyListeners();
      return;
    }

    _categoriesSubscription = _repository
        .getCategoriesStream(userId!, includeArchived: _includeArchived)
        .listen(
          (items) {
            _categories = items;
            _isLoading = false;
            _errorMessage = null;
            notifyListeners();
          },
          onError: (error) {
            _isLoading = false;
            _errorMessage = 'Помилка завантаження категорій: $error';
            notifyListeners();
          },
        );
  }

  Future<void> addCategory({
    required String name,
    required String icon,
    required int colorValue,
    required double monthlyBudget,
  }) async {
    if (userId == null) {
      throw Exception('Користувач не авторизований');
    }

    final category = Category(
      id: '',
      userId: userId!,
      name: name,
      icon: icon,
      colorValue: colorValue,
      monthlyBudget: monthlyBudget,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _repository.addCategory(category);
  }

  Future<void> updateCategory(Category category) async {
    if (userId == null) {
      throw Exception('Користувач не авторизований');
    }

    final updated = category.copyWith(updatedAt: DateTime.now());
    await _repository.updateCategory(updated);
  }

  Future<void> deleteCategory(Category category) async {
    if (userId == null) {
      throw Exception('Користувач не авторизований');
    }

    if (_isSystemCategoryId(category.id)) {
      throw Exception('Системні категорії не можна видаляти');
    }

    await _repository.deleteCategory(category.id);
  }

  Future<void> archiveCategory(String categoryId) async {
    if (userId == null) {
      throw Exception('Користувач не авторизований');
    }

    await _repository.archiveCategory(categoryId, userId!);
  }

  Future<void> restoreCategory(String categoryId) async {
    if (userId == null) {
      throw Exception('Користувач не авторизований');
    }

    await _repository.restoreCategory(categoryId, userId!);
  }

  Future<void> setIncludeArchived(bool value) async {
    if (_includeArchived == value) {
      return;
    }

    await initialize(includeArchived: value);
  }

  @override
  void dispose() {
    _categoriesSubscription?.cancel();
    super.dispose();
  }

  bool _isSystemCategoryId(String categoryId) {
    final uid = userId;
    if (uid == null) {
      return false;
    }

    return categoryId.startsWith('${uid}_cat_');
  }
}
