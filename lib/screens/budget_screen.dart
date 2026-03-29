import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/category.dart';
import '../models/expense.dart';
import '../providers/categories_provider.dart';
import '../providers/firestore_expenses_provider.dart';
import '../providers/user_settings_provider.dart';
import '../utils/currency_converter.dart';
import '../widgets/app_bottom_nav_bar.dart';
import '../widgets/budget_status_notification.dart';
import 'edit_budget_screen.dart';
import 'settings_screen.dart';
import 'statistics_screen.dart';

class BudgetScreen extends StatelessWidget {
  const BudgetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Бюджет',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: Consumer3<FirestoreExpensesProvider, UserSettingsProvider, CategoriesProvider>(
        builder: (context, expensesProvider, settingsProvider, categoriesProvider, child) {
          final categories = categoriesProvider.categories;
          final budget = categoriesProvider.totalBudget;
          final spentByCategory = _calculateMonthSpentByCategory(
            expensesProvider,
            categories,
          );
          final spent = spentByCategory.values.fold<double>(
            0,
            (sum, value) => sum + value,
          );
          final remaining = (budget - spent).clamp(0, double.infinity);
          final currency = settingsProvider.currency;
          final progress = budget <= 0 ? 0.0 : (spent / budget).clamp(0.0, 1.0);
          final percent = budget <= 0 ? 0.0 : (spent / budget) * 100;

          final notificationState = percent < 40
              ? BudgetNotificationState.safe
              : (percent < 80
                    ? BudgetNotificationState.warning
                    : BudgetNotificationState.danger);

          return SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                          children: [
                            Text(
                              _formatCurrency(budget, currency),
                              style: const TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF2D3137),
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Загальний бюджет на місяць (сума категорій)',
                              style: TextStyle(
                                color: Color(0xFF6B7280),
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 14),
                            _BudgetProgressBar(progress: progress),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  child: _BudgetMetric(
                                    label: 'Витрачено',
                                    value: _formatCurrency(spent, currency),
                                    color: const Color(0xFFE04D4D),
                                  ),
                                ),
                                Expanded(
                                  child: _BudgetMetric(
                                    label: 'Залишилось',
                                    value: _formatCurrency(
                                      remaining.toDouble(),
                                      currency,
                                    ),
                                    color: const Color(0xFF2EAD69),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
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
                            const Text(
                              'Бюджети категорій',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF2D3137),
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Редагування бюджету виконується для конкретної категорії.',
                              style: TextStyle(color: Color(0xFF6B7280)),
                            ),
                            const SizedBox(height: 12),
                            if (categories.isEmpty)
                              const Text(
                                'Немає категорій. Додайте їх у Налаштування -> Категорії.',
                                style: TextStyle(color: Color(0xFF6B7280)),
                              )
                            else
                              ...categories.map(
                                (category) => Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: _CategoryBudgetTile(
                                    category: category,
                                    spentUah: spentByCategory[category.id] ?? 0,
                                    currency: currency,
                                    onEdit: () async {
                                      final changed =
                                          await Navigator.push<bool>(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => EditBudgetScreen(
                                                category: category,
                                              ),
                                            ),
                                          );

                                      if (changed == true && context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Бюджет категорії "${category.name}" змінено',
                                            ),
                                            behavior: SnackBarBehavior.floating,
                                            backgroundColor: const Color(
                                              0xFF2EAD69,
                                            ),
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
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
                            const Text(
                              'Сповіщення',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF2D3137),
                              ),
                            ),
                            const SizedBox(height: 12),
                            BudgetStatusNotification(
                              state: notificationState,
                              spentAmount: spent,
                              budgetAmount: budget,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: 2,
        onTap: (index) {
          if (index == 0) {
            Navigator.pop(context);
            return;
          }

          if (index == 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const StatisticsScreen()),
            );
            return;
          }

          if (index == 2) {
            return;
          }

          if (index == 3) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            );
            return;
          }

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Цей екран додамо наступним кроком'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      ),
    );
  }

  String _formatCurrency(double valueInUah, String currency) {
    return CurrencyConverter.formatFromUah(valueInUah, currency);
  }

  Map<String, double> _calculateMonthSpentByCategory(
    FirestoreExpensesProvider provider,
    List<Category> categories,
  ) {
    final now = DateTime.now();
    final Map<String, double> totals = {};

    for (final expense in provider.expenses) {
      if (expense.date.year != now.year || expense.date.month != now.month) {
        continue;
      }

      final key = _resolveBudgetCategoryKey(expense, categories);
      if (key == null) {
        continue;
      }

      totals[key] = (totals[key] ?? 0) + expense.amount;
    }

    return totals;
  }

  String? _resolveBudgetCategoryKey(
    Expense expense,
    List<Category> categories,
  ) {
    final id = expense.categoryId;
    if (id != null && id.trim().isNotEmpty) {
      return id;
    }

    final fallbackName = expense.categoryNameSnapshot.trim().isNotEmpty
        ? expense.categoryNameSnapshot
        : expense.category;

    try {
      return categories.firstWhere((c) => c.name == fallbackName).id;
    } catch (_) {
      return null;
    }
  }
}

class _CategoryBudgetTile extends StatelessWidget {
  final Category category;
  final double spentUah;
  final String currency;
  final VoidCallback onEdit;

  const _CategoryBudgetTile({
    required this.category,
    required this.spentUah,
    required this.currency,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final budget = category.monthlyBudget;
    final progress = budget <= 0 ? 0.0 : (spentUah / budget).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(category.icon, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  category.name,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              IconButton(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Змінити бюджет категорії',
              ),
            ],
          ),
          const SizedBox(height: 6),
          _BudgetProgressBar(progress: progress),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Витрачено: ${CurrencyConverter.formatFromUah(spentUah, currency)}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
              ),
              Text(
                'Бюджет: ${CurrencyConverter.formatFromUah(budget, currency)}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BudgetProgressBar extends StatelessWidget {
  final double progress;

  const _BudgetProgressBar({required this.progress});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        height: 8,
        child: Stack(
          children: [
            Container(color: const Color(0xFFE6E8ED)),
            FractionallySizedBox(
              widthFactor: progress,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF2EAD69),
                      Color(0xFFE0C02C),
                      Color(0xFFE04D4D),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BudgetMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _BudgetMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
        ),
      ],
    );
  }
}
