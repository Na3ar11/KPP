import 'package:flutter/material.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:provider/provider.dart';
import '../models/category.dart';
import '../providers/categories_provider.dart';
import '../providers/firestore_expenses_provider.dart';
import '../providers/user_settings_provider.dart';
import '../models/expense.dart';
import '../utils/currency_converter.dart';

class AddExpenseScreen extends StatefulWidget {
  final Expense? expense; // null - додавання, є значення - редагування

  const AddExpenseScreen({super.key, this.expense});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();
  String? _selectedCategoryId;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  bool get _isEditMode => widget.expense != null;

  @override
  void initState() {
    super.initState();
    _logOpenAddExpense();

    // Якщо режим редагування - заповнюємо поля
    if (_isEditMode) {
      _amountController.text = widget.expense!.originalAmount.toStringAsFixed(
        0,
      );
      _commentController.text = widget.expense!.description;
      _selectedCategoryId = widget.expense!.categoryId;
      _selectedDate = widget.expense!.date;
    }
  }

  Future<void> _logOpenAddExpense() async {
    await FirebaseAnalytics.instance.logEvent(
      name: _isEditMode
          ? 'open_edit_expense_screen'
          : 'open_add_expense_screen',
      parameters: {
        'screen_name': 'add_expense_screen',
        'mode': _isEditMode ? 'edit' : 'add',
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _isEditMode ? 'Редагувати витрату' : 'Додати витрату',
          style: const TextStyle(color: Colors.black),
        ),
        actions: [
          TextButton(
            onPressed: (_canSave() && !_isLoading) ? _saveExpense : null,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(_isEditMode ? 'Оновити' : 'Зберегти'),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Секція введення суми
                _buildAmountSection(),
                const SizedBox(height: 20),

                // Секція категорій
                _buildCategorySection(),
                const SizedBox(height: 20),

                // Секція дати
                _buildDateSection(),
                const SizedBox(height: 20),

                // Секція коментарів
                _buildCommentSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAmountSection() {
    final currency = context.watch<UserSettingsProvider>().currency;

    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            CurrencyConverter.symbolFor(currency),
            style: const TextStyle(fontSize: 24, color: Color(0xFF667EEA)),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
            decoration: const InputDecoration(
              border: InputBorder.none,
              hintText: '0',
              hintStyle: TextStyle(color: Colors.grey),
            ),
            onChanged: (value) => setState(() {}),
          ),
          const Text(
            'Введіть суму витрати',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySection() {
    final categories = context.watch<CategoriesProvider>().categories;
    String? effectiveSelectedCategoryId = _selectedCategoryId;

    if (_isEditMode && effectiveSelectedCategoryId == null) {
      try {
        effectiveSelectedCategoryId = categories
            .firstWhere((c) => c.name == widget.expense!.category)
            .id;
      } catch (_) {
        effectiveSelectedCategoryId = null;
      }
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Категорія',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 15),
          if (categories.isEmpty)
            const Text(
              'Немає категорій. Зачекайте, поки вони завантажаться.',
              style: TextStyle(color: Colors.grey),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                childAspectRatio: 0.8,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
              ),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                final color = Color(category.colorValue);
                final isSelected = effectiveSelectedCategoryId == category.id;

                return GestureDetector(
                  onTap: () => setState(() {
                    _selectedCategoryId = category.id;
                  }),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFF0F4FF)
                          : const Color(0xFFF8F9FA),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF667EEA)
                            : Colors.transparent,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              category.icon,
                              style: const TextStyle(fontSize: 18),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          category.name,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildDateSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Дата',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 15),
          GestureDetector(
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (date != null) {
                setState(() {
                  _selectedDate = date;
                });
              }
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE1E5E9), width: 2),
              ),
              child: Text(
                '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Коментар (необов\'язково)',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 15),
          TextField(
            controller: _commentController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Додайте опис витрати...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFFE1E5E9),
                  width: 2,
                ),
              ),
              filled: true,
              fillColor: const Color(0xFFF8F9FA),
            ),
          ),
        ],
      ),
    );
  }

  bool _canSave() {
    return _amountController.text.isNotEmpty &&
        double.tryParse(_amountController.text) != null &&
        double.parse(_amountController.text) > 0 &&
        _selectedCategoryId != null;
  }

  Future<void> _saveExpense() async {
    if (!_canSave()) return;

    setState(() => _isLoading = true);

    try {
      final provider = context.read<FirestoreExpensesProvider>();
      final categoriesProvider = context.read<CategoriesProvider>();
      final settingsProvider = context.read<UserSettingsProvider>();
      final userId = provider.userId;

      if (userId == null) {
        throw Exception('Користувач не авторизований');
      }

      final originalAmount = double.parse(_amountController.text);
      final selectedCurrency = settingsProvider.currency;
      final rateUahPerOriginal = CurrencyConverter.uahPerCurrency(
        selectedCurrency,
      );
      final amountUah = CurrencyConverter.convertToUah(
        originalAmount,
        selectedCurrency,
      );
      Category? selectedCategoryData;
      try {
        selectedCategoryData = categoriesProvider.categories.firstWhere(
          (c) => c.id == _selectedCategoryId,
        );
      } catch (_) {
        if (_isEditMode) {
          try {
            selectedCategoryData = categoriesProvider.categories.firstWhere(
              (c) => c.name == widget.expense!.category,
            );
          } catch (_) {
            selectedCategoryData = null;
          }
        }
      }

      if (selectedCategoryData == null) {
        throw Exception('Не вдалося знайти обрану категорію');
      }

      if (_isEditMode) {
        final updatedExpense = widget.expense!.copyWith(
          amount: amountUah,
          amountUah: amountUah,
          originalAmount: originalAmount,
          originalCurrency: selectedCurrency,
          rateUahPerOriginal: rateUahPerOriginal,
          category: selectedCategoryData.name,
          categoryId: selectedCategoryData.id,
          categoryNameSnapshot: selectedCategoryData.name,
          categoryIconSnapshot: selectedCategoryData.icon,
          categoryColorSnapshot: selectedCategoryData.colorValue,
          description: _commentController.text.trim().isEmpty
              ? 'Витрата'
              : _commentController.text.trim(),
          date: _selectedDate,
          icon: selectedCategoryData.icon,
          color: Color(selectedCategoryData.colorValue),
        );

        await provider.updateExpense(updatedExpense);

        await FirebaseAnalytics.instance.logEvent(
          name: 'expense_updated',
          parameters: {
            'category': selectedCategoryData.name,
            'amount_uah': amountUah,
            'original_amount': originalAmount,
            'original_currency': selectedCurrency,
          },
        );

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Витрату оновлено!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // Додавання нової витрати
        final newExpense = Expense(
          id: '', // Firestore згенерує автоматично
          userId: userId,
          amount: amountUah,
          amountUah: amountUah,
          originalAmount: originalAmount,
          originalCurrency: selectedCurrency,
          rateUahPerOriginal: rateUahPerOriginal,
          category: selectedCategoryData.name,
          categoryId: selectedCategoryData.id,
          categoryNameSnapshot: selectedCategoryData.name,
          categoryIconSnapshot: selectedCategoryData.icon,
          categoryColorSnapshot: selectedCategoryData.colorValue,
          description: _commentController.text.trim().isEmpty
              ? 'Витрата'
              : _commentController.text.trim(),
          date: _selectedDate,
          icon: selectedCategoryData.icon,
          color: Color(selectedCategoryData.colorValue),
        );

        await provider.addExpense(newExpense);

        await FirebaseAnalytics.instance.logEvent(
          name: 'expense_added',
          parameters: {
            'category': selectedCategoryData.name,
            'amount_uah': amountUah,
            'original_amount': originalAmount,
            'original_currency': selectedCurrency,
          },
        );

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Витрату додано!'),
            backgroundColor: Colors.green,
          ),
        );
      }

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Помилка: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
