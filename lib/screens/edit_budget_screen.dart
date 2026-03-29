import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/category.dart';
import '../providers/categories_provider.dart';
import '../providers/user_settings_provider.dart';
import '../utils/currency_converter.dart';

class EditBudgetScreen extends StatefulWidget {
  final Category category;

  const EditBudgetScreen({super.key, required this.category});

  @override
  State<EditBudgetScreen> createState() => _EditBudgetScreenState();
}

class _EditBudgetScreenState extends State<EditBudgetScreen> {
  late final TextEditingController _budgetController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final selectedCurrency = context.read<UserSettingsProvider>().currency;
    final budgetInSelectedCurrency = CurrencyConverter.convertFromUah(
      widget.category.monthlyBudget,
      selectedCurrency,
    );

    _budgetController = TextEditingController(
      text: budgetInSelectedCurrency.toStringAsFixed(0),
    );
  }

  @override
  void dispose() {
    _budgetController.dispose();
    super.dispose();
  }

  Future<void> _saveBudget() async {
    final newBudget = double.tryParse(
      _budgetController.text.replaceAll(',', '.'),
    );
    if (newBudget == null || newBudget <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Введіть коректний бюджет більше 0'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final selectedCurrency = context.read<UserSettingsProvider>().currency;
      final budgetInUah = CurrencyConverter.convertToUah(
        newBudget,
        selectedCurrency,
      );

      final updated = widget.category.copyWith(
        monthlyBudget: budgetInUah,
        updatedAt: DateTime.now(),
      );

      await context.read<CategoriesProvider>().updateCategory(updated);

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Не вдалося зберегти бюджет: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(title: Text('Бюджет: ${widget.category.name}')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Місячний бюджет категорії "${widget.category.name}"',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Consumer<UserSettingsProvider>(
                        builder: (context, settingsProvider, child) {
                          return TextField(
                            controller: _budgetController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: InputDecoration(
                              prefixText:
                                  '${CurrencyConverter.symbolFor(settingsProvider.currency)} ',
                              labelText: 'Сума',
                              border: const OutlineInputBorder(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Це ліміт витрат для конкретної категорії на поточний місяць.',
                        style: TextStyle(color: Color(0xFF6B7280)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveBudget,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Зберегти бюджет'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
