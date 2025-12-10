import 'package:flutter/material.dart';

abstract class AppStrings {
 
  static const String appTitle = 'Finance Tracker';
  
  
  static const String fieldRequired = 'Це поле є обов\'язковим';
  static const String invalidEmail = 'Введіть коректну електронну адресу';
  static const String passwordTooShort = 'Пароль має містити мінімум 6 символів';
  static const String passwordsDoNotMatch = 'Паролі не співпадають';
  static const String invalidName = 'Ім\'я має містити мінімум 2 символи';
  
  const AppStrings._();
}

abstract class Validators {

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.fieldRequired;
    }
    
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    
    if (!emailRegex.hasMatch(value.trim())) {
      return AppStrings.invalidEmail;
    }
    
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return AppStrings.fieldRequired;
    }
    
    if (value.length < 6) {
      return AppStrings.passwordTooShort;
    }
    
    return null;
  }
  
 
  static String? name(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.fieldRequired;
    }
    
    if (value.trim().length < 2) {
      return AppStrings.invalidName;
    }
    
    return null;
  }

  static String? required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.fieldRequired;
    }
    return null;
  }
  

  static String? Function(String?) confirmPassword(TextEditingController passwordController) {
    return (String? value) {
      if (value == null || value.isEmpty) {
        return AppStrings.fieldRequired;
      }
      
      if (value != passwordController.text) {
        return AppStrings.passwordsDoNotMatch;
      }
      
      return null;
    };
  }
  
  const Validators._();
}