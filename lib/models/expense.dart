import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
//Абоба 
class Expense {
  final String id;
  final String userId; 
  final String icon;
  final String category;
  final String description;
  final double amount;
  final Color color;
  final DateTime date;
  final DateTime createdAt; 
  final DateTime updatedAt; 

  Expense({
    required this.id,
    required this.userId,
    required this.icon,
    required this.category,
    required this.description,
    required this.amount,
    required this.color,
    required this.date,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Expense copyWith({
    String? id,
    String? userId,
    String? icon,
    String? category,
    String? description,
    double? amount,
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
      description: description ?? this.description,
      amount: amount ?? this.amount,
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
      'description': description,
      'amount': amount,
      'color': color.value,
      'date': date.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Створення з JSON
  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'] as String,
      userId: json['userId'] as String,
      icon: json['icon'] as String,
      category: json['category'] as String,
      description: json['description'] as String,
      amount: (json['amount'] as num).toDouble(),
      color: Color(json['color'] as int),
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
      'icon': icon,
      'category': category,
      'description': description,
      'amount': amount,
      'colorValue': color.value, 
      'date': Timestamp.fromDate(date), 
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory Expense.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return Expense(
      id: doc.id, 
      userId: data['userId'] as String,
      icon: data['icon'] as String,
      category: data['category'] as String,
      description: data['description'] as String,
      amount: (data['amount'] as num).toDouble(),
      color: Color(data['colorValue'] as int),
      date: (data['date'] as Timestamp).toDate(),
      createdAt: data['createdAt'] != null 
          ? (data['createdAt'] as Timestamp).toDate() 
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null 
          ? (data['updatedAt'] as Timestamp).toDate() 
          : DateTime.now(),
    );
  }

  factory Expense.fromFirestoreQuery(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return Expense(
      id: doc.id,
      userId: data['userId'] as String,
      icon: data['icon'] as String,
      category: data['category'] as String,
      description: data['description'] as String,
      amount: (data['amount'] as num).toDouble(),
      color: Color(data['colorValue'] as int),
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

