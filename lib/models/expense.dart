import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Expense {
  final String id;
  final String userId;

  // Legacy category fields (kept for compatibility with existing UI).
  final String icon;
  final String category;
  final Color color;

  // New category link + snapshots.
  final String? categoryId;
  final String categoryNameSnapshot;
  final String categoryIconSnapshot;
  final int categoryColorSnapshot;

  final String description;
  final double amount;
  final double amountUah;
  final double originalAmount;
  final String originalCurrency;
  final double rateUahPerOriginal;
  final DateTime date;
  final DateTime createdAt;
  final DateTime updatedAt;

  Expense({
    required this.id,
    required this.userId,
    required this.icon,
    required this.category,
    this.categoryId,
    String? categoryNameSnapshot,
    String? categoryIconSnapshot,
    int? categoryColorSnapshot,
    required this.description,
    required this.amount,
    double? amountUah,
    double? originalAmount,
    String? originalCurrency,
    double? rateUahPerOriginal,
    required this.color,
    required this.date,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : categoryNameSnapshot = categoryNameSnapshot ?? category,
       categoryIconSnapshot = categoryIconSnapshot ?? icon,
       categoryColorSnapshot = categoryColorSnapshot ?? color.value,
       amountUah = amountUah ?? amount,
       originalAmount = originalAmount ?? amount,
       originalCurrency = originalCurrency ?? 'UAH',
       rateUahPerOriginal = rateUahPerOriginal ?? 1.0,
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  Expense copyWith({
    String? id,
    String? userId,
    String? icon,
    String? category,
    String? categoryId,
    String? categoryNameSnapshot,
    String? categoryIconSnapshot,
    int? categoryColorSnapshot,
    String? description,
    double? amount,
    double? amountUah,
    double? originalAmount,
    String? originalCurrency,
    double? rateUahPerOriginal,
    Color? color,
    DateTime? date,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Expense(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      icon: icon ?? this.icon,
      category: category ?? this.category,
      categoryId: categoryId ?? this.categoryId,
      categoryNameSnapshot: categoryNameSnapshot ?? this.categoryNameSnapshot,
      categoryIconSnapshot: categoryIconSnapshot ?? this.categoryIconSnapshot,
      categoryColorSnapshot:
          categoryColorSnapshot ?? this.categoryColorSnapshot,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      amountUah: amountUah ?? this.amountUah,
      originalAmount: originalAmount ?? this.originalAmount,
      originalCurrency: originalCurrency ?? this.originalCurrency,
      rateUahPerOriginal: rateUahPerOriginal ?? this.rateUahPerOriginal,
      color: color ?? this.color,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'icon': icon,
      'category': category,
      'categoryId': categoryId,
      'categoryNameSnapshot': categoryNameSnapshot,
      'categoryIconSnapshot': categoryIconSnapshot,
      'categoryColorSnapshot': categoryColorSnapshot,
      'description': description,
      'amount': amount,
      'amountUah': amountUah,
      'originalAmount': originalAmount,
      'originalCurrency': originalCurrency,
      'rateUahPerOriginal': rateUahPerOriginal,
      'color': color.value,
      'date': date.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Expense.fromJson(Map<String, dynamic> json) {
    final legacyCategory = json['category'] as String? ?? 'Без категорії';
    final legacyIcon = json['icon'] as String? ?? '💰';
    final legacyColorValue = (json['color'] as int?) ?? 0xFF6B7280;

    final snapshotName =
        json['categoryNameSnapshot'] as String? ?? legacyCategory;
    final snapshotIcon = json['categoryIconSnapshot'] as String? ?? legacyIcon;
    final snapshotColor =
        (json['categoryColorSnapshot'] as int?) ?? legacyColorValue;

    final amountUah = json['amountUah'] != null
        ? (json['amountUah'] as num).toDouble()
        : (json['amount'] as num).toDouble();

    return Expense(
      id: json['id'] as String,
      userId: json['userId'] as String,
      icon: snapshotIcon,
      category: snapshotName,
      categoryId: json['categoryId'] as String?,
      categoryNameSnapshot: snapshotName,
      categoryIconSnapshot: snapshotIcon,
      categoryColorSnapshot: snapshotColor,
      description: json['description'] as String,
      amount: amountUah,
      amountUah: amountUah,
      originalAmount: json['originalAmount'] != null
          ? (json['originalAmount'] as num).toDouble()
          : (json['amount'] as num).toDouble(),
      originalCurrency: json['originalCurrency'] as String? ?? 'UAH',
      rateUahPerOriginal: json['rateUahPerOriginal'] != null
          ? (json['rateUahPerOriginal'] as num).toDouble()
          : 1.0,
      color: Color(snapshotColor),
      date: DateTime.parse(json['date'] as String),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'categoryId': (categoryId != null && categoryId!.trim().isNotEmpty)
          ? categoryId
          : category,
      'categoryNameSnapshot': categoryNameSnapshot,
      'categoryIconSnapshot': categoryIconSnapshot,
      'categoryColorSnapshot': categoryColorSnapshot,
      'description': description,
      'amountUah': amountUah,
      'originalAmount': originalAmount,
      'originalCurrency': originalCurrency,
      'rateUahPerOriginal': rateUahPerOriginal,
      'date': Timestamp.fromDate(date),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory Expense.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return _fromFirestoreData(doc.id, data);
  }

  factory Expense.fromFirestoreQuery(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return _fromFirestoreData(doc.id, data);
  }

  static Expense _fromFirestoreData(String id, Map<String, dynamic> data) {
    final legacyCategory = data['category'] as String? ?? 'Без категорії';
    final legacyIcon = data['icon'] as String? ?? '💰';
    final legacyColorValue = (data['colorValue'] as int?) ?? 0xFF6B7280;

    final snapshotName =
        data['categoryNameSnapshot'] as String? ?? legacyCategory;
    final snapshotIcon = data['categoryIconSnapshot'] as String? ?? legacyIcon;
    final snapshotColor =
        (data['categoryColorSnapshot'] as int?) ?? legacyColorValue;

    final amountUah = data['amountUah'] != null
        ? (data['amountUah'] as num).toDouble()
        : (data['amount'] as num).toDouble();

    return Expense(
      id: id,
      userId: data['userId'] as String,
      icon: snapshotIcon,
      category: snapshotName,
      categoryId: data['categoryId'] as String?,
      categoryNameSnapshot: snapshotName,
      categoryIconSnapshot: snapshotIcon,
      categoryColorSnapshot: snapshotColor,
      description: data['description'] as String,
      amount: amountUah,
      amountUah: amountUah,
      originalAmount: data['originalAmount'] != null
          ? (data['originalAmount'] as num).toDouble()
          : (data['amount'] as num).toDouble(),
      originalCurrency: data['originalCurrency'] as String? ?? 'UAH',
      rateUahPerOriginal: data['rateUahPerOriginal'] != null
          ? (data['rateUahPerOriginal'] as num).toDouble()
          : 1.0,
      color: Color(snapshotColor),
      date: (data['date'] as Timestamp).toDate(),
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }
}
