import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/category.dart';

abstract class CategoriesRepository {
  Future<void> ensureDefaultCategories(String userId);

  Stream<List<Category>> getCategoriesStream(
    String userId, {
    bool includeArchived = false,
  });

  Future<String> addCategory(Category category);
  Future<void> updateCategory(Category category);
  Future<void> deleteCategory(String categoryId);
  Future<void> archiveCategory(String categoryId, String userId);
  Future<void> restoreCategory(String categoryId, String userId);
}

class FirestoreCategoriesRepository implements CategoriesRepository {
  final FirebaseFirestore _firestore;

  static const String _collectionName = 'categories';

  FirestoreCategoriesRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference get _collection => _firestore.collection(_collectionName);

  @override
  Future<void> ensureDefaultCategories(String userId) async {
    final existing = await _collection
        .where('userId', isEqualTo: userId)
        .limit(1)
        .get();
    if (existing.docs.isNotEmpty) {
      return;
    }

    final now = Timestamp.now();

    final defaults = [
      {
        'id': '${userId}_cat_food',
        'name': 'Їжа',
        'icon': '🍕',
        'colorValue': 0xFFE53E3E,
        'monthlyBudget': 3000.0,
      },
      {
        'id': '${userId}_cat_transport',
        'name': 'Транспорт',
        'icon': '🚕',
        'colorValue': 0xFF3182CE,
        'monthlyBudget': 2000.0,
      },
      {
        'id': '${userId}_cat_shopping',
        'name': 'Покупки',
        'icon': '🛒',
        'colorValue': 0xFF38A169,
        'monthlyBudget': 2500.0,
      },
      {
        'id': '${userId}_cat_health',
        'name': 'Здоров\'я',
        'icon': '💊',
        'colorValue': 0xFFD69E2E,
        'monthlyBudget': 1500.0,
      },
      {
        'id': '${userId}_cat_entertainment',
        'name': 'Розваги',
        'icon': '🎬',
        'colorValue': 0xFF4A5568,
        'monthlyBudget': 1800.0,
      },
      {
        'id': '${userId}_cat_home',
        'name': 'Дім',
        'icon': '🏠',
        'colorValue': 0xFF2D3748,
        'monthlyBudget': 2200.0,
      },
      {
        'id': '${userId}_cat_education',
        'name': 'Освіта',
        'icon': '📚',
        'colorValue': 0xFF38B2AC,
        'monthlyBudget': 1000.0,
      },
    ];

    final batch = _firestore.batch();

    for (final item in defaults) {
      final docRef = _collection.doc(item['id'] as String);
      batch.set(docRef, {
        'userId': userId,
        'name': item['name'],
        'icon': item['icon'],
        'colorValue': item['colorValue'],
        'monthlyBudget': item['monthlyBudget'],
        'isArchived': false,
        'createdAt': now,
        'updatedAt': now,
      });
    }

    await batch.commit();
  }

  @override
  Stream<List<Category>> getCategoriesStream(
    String userId, {
    bool includeArchived = false,
  }) {
    Query query = _collection.where('userId', isEqualTo: userId);
    if (!includeArchived) {
      query = query.where('isArchived', isEqualTo: false);
    }

    return query.orderBy('createdAt', descending: false).snapshots().map((
      snapshot,
    ) {
      return snapshot.docs
          .map((doc) => Category.fromFirestoreQuery(doc))
          .toList();
    });
  }

  @override
  Future<String> addCategory(Category category) async {
    final docRef = await _collection.add(category.toFirestore());
    return docRef.id;
  }

  @override
  Future<void> updateCategory(Category category) async {
    await _collection.doc(category.id).update(category.toFirestore());
  }

  @override
  Future<void> deleteCategory(String categoryId) async {
    await _collection.doc(categoryId).delete();
  }

  @override
  Future<void> archiveCategory(String categoryId, String userId) async {
    await _collection.doc(categoryId).update({
      'userId': userId,
      'isArchived': true,
      'updatedAt': Timestamp.now(),
    });
  }

  @override
  Future<void> restoreCategory(String categoryId, String userId) async {
    await _collection.doc(categoryId).update({
      'userId': userId,
      'isArchived': false,
      'updatedAt': Timestamp.now(),
    });
  }
}
