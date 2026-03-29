import 'package:flutter/material.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:provider/provider.dart';
import 'add_expense_screen.dart';
import 'expenses_screen.dart';
import 'expense_detail_screen.dart';
import 'category_expenses_screen.dart';
import 'login_screen.dart';
import 'budget_screen.dart';
import 'statistics_screen.dart';
import 'settings_screen.dart';
import '../repositories/auth_repository.dart';
import '../models/category.dart';
import '../providers/firestore_expenses_provider.dart';
import '../providers/categories_provider.dart';
import '../providers/user_settings_provider.dart';
import '../models/expense.dart';
import '../utils/currency_converter.dart';
import '../widgets/app_bottom_nav_bar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    // Провайдер вже ініціалізований в AuthWrapper
  }

  void _onTabSelected(int index) {
    if (index == 0) {
      setState(() => _currentTabIndex = index);
      return;
    }

    if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const BudgetScreen()),
      );
      return;
    }

    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const StatisticsScreen()),
      );
      return;
    }

    if (index == 3) {
      Navigator.push(
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            children: [
              _buildHeader(context),
              _buildQuickStats(),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      _buildRecentExpenses(context),
                      const SizedBox(height: 20),
                      _buildCategories(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: _currentTabIndex,
        onTap: _onTabSelected,
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Text(
                    'Ваші витрати',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              Consumer3<
                FirestoreExpensesProvider,
                UserSettingsProvider,
                CategoriesProvider
              >(
                builder:
                    (
                      context,
                      expensesProvider,
                      settingsProvider,
                      categoriesProvider,
                      child,
                    ) {
                      final spentByCategory = _calculateMonthSpentByCategory(
                        expensesProvider.expenses,
                        categoriesProvider.categories,
                      );
                      final spentMonth = spentByCategory.values.fold<double>(
                        0,
                        (sum, value) => sum + value,
                      );
                      final budgetLimit = categoriesProvider.totalBudget;
                      final balance = (budgetLimit - spentMonth)
                          .clamp(0.0, double.infinity)
                          .toDouble();
                      final currency = settingsProvider.currency;

                      return Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Залишок на рахунку',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    CurrencyConverter.formatFromUah(
                                      balance,
                                      currency,
                                      decimalDigits: 2,
                                    ),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 40,
                                      fontWeight: FontWeight.bold,
                                      height: 1,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  const Text(
                                    'За поточний місяць',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Material(
                              color: Colors.transparent,
                              shape: const CircleBorder(),
                              child: InkWell(
                                customBorder: const CircleBorder(),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const AddExpenseScreen(),
                                    ),
                                  );
                                },
                                child: Container(
                                  width: 78,
                                  height: 78,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: const LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Color(0xFF7B73F6),
                                        Color(0xFF5A56DB),
                                      ],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(
                                          0xFF5A56DB,
                                        ).withOpacity(0.35),
                                        blurRadius: 18,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.add,
                                      size: 32,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStats() {
    return Consumer3<
      FirestoreExpensesProvider,
      UserSettingsProvider,
      CategoriesProvider
    >(
      builder:
          (context, provider, settingsProvider, categoriesProvider, child) {
            final currency = settingsProvider.currency;
            final spentByCategory = _calculateMonthSpentByCategory(
              provider.expenses,
              categoriesProvider.categories,
            );
            final monthSpent = spentByCategory.values.fold<double>(
              0,
              (sum, value) => sum + value,
            );

            return Transform.translate(
              offset: const Offset(0, -30),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            CurrencyConverter.formatFromUah(
                              provider.todayAmount,
                              currency,
                            ),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFE74C3C),
                            ),
                          ),
                          const Text(
                            'Сьогодні',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            CurrencyConverter.formatFromUah(
                              provider.weekAmount,
                              currency,
                            ),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFF39C12),
                            ),
                          ),
                          const Text(
                            'Тиждень',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            CurrencyConverter.formatFromUah(
                              monthSpent,
                              currency,
                            ),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF667EEA),
                            ),
                          ),
                          const Text(
                            'Місяць',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
    );
  }

  Map<String, double> _calculateMonthSpentByCategory(
    List<Expense> expenses,
    List<Category> categories,
  ) {
    final now = DateTime.now();
    final Map<String, double> totals = {};

    for (final expense in expenses) {
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

  Widget _buildRecentExpenses(BuildContext context) {
    return Consumer<FirestoreExpensesProvider>(
      builder: (context, provider, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
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
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Останні витрати',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ExpensesScreen(),
                        ),
                      );
                    },
                    child: const Text('Переглянути всі'),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              if (provider.isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (provider.hasError)
                Center(
                  child: Column(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        provider.errorMessage ?? 'Помилка завантаження',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => provider.retry(),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Спробувати знову'),
                      ),
                    ],
                  ),
                )
              else if (provider.expenses.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 48,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Немає витрат',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...provider.recentExpenses.asMap().entries.map((entry) {
                  final expense = entry.value;
                  return Column(
                    children: [
                      if (entry.key > 0) const SizedBox(height: 15),
                      _buildExpenseItem(expense),
                    ],
                  );
                }).toList(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildExpenseItem(Expense expense) {
    return Builder(
      builder: (context) {
        final currency = context.watch<UserSettingsProvider>().currency;

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ExpenseDetailScreen(
                  id: expense.id,
                  icon: expense.icon,
                  category: expense.category,
                  description: expense.description,
                  amount: expense.amount,
                  amountUah: expense.amountUah,
                  originalAmount: expense.originalAmount,
                  originalCurrency: expense.originalCurrency,
                  rateUahPerOriginal: expense.rateUahPerOriginal,
                  color: expense.color,
                  date: expense.date,
                ),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: expense.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Center(
                    child: Text(
                      expense.icon,
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        expense.category,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      Text(
                        expense.description,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  CurrencyConverter.formatFromUah(expense.amount, currency),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFE74C3C),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCategories() {
    final categories = [
      {'name': 'Їжа', 'icon': '🍕', 'color': const Color(0xFFE53E3E)},
      {'name': 'Транспорт', 'icon': '🚕', 'color': const Color(0xFF3182CE)},
      {'name': 'Покупки', 'icon': '🛒', 'color': const Color(0xFF38A169)},
      {'name': 'Здоров\'я', 'icon': '💊', 'color': const Color(0xFFD69E2E)},
      {'name': 'Розваги', 'icon': '🎬', 'color': const Color(0xFF4A5568)},
      {'name': 'Дім', 'icon': '🏠', 'color': const Color(0xFF2D3748)},
      {'name': 'Освіта', 'icon': '📚', 'color': const Color(0xFF38B2AC)},
      {'name': 'Інше', 'icon': '➕', 'color': const Color(0xFFE53E3E)},
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
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
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Категорії',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              Text('Керувати', style: TextStyle(color: Color(0xFF667EEA))),
            ],
          ),
          const SizedBox(height: 20),
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
              return GestureDetector(
                onTap: () async {
                  await FirebaseAnalytics.instance.logEvent(
                    name: 'category_clicked',
                    parameters: {
                      'category_name': category['name'] as String,
                      'timestamp': DateTime.now().toIso8601String(),
                    },
                  );

                  if (category['name'] == 'Їжа') {
                    try {
                      throw Exception(
                        'Тестова помилка при натисканні на категорію Їжа',
                      );
                    } catch (error, stackTrace) {
                      await FirebaseCrashlytics.instance.recordError(
                        error,
                        stackTrace,
                        reason: 'Користувач натиснув на категорію Їжа',
                        fatal: false,
                      );

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Нефатальний краш-репорт відправлено в Firebase!',
                            ),
                            backgroundColor: Colors.orange,
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    }
                  } else if (category['name'] == 'Транспорт') {
                    await FirebaseCrashlytics.instance.recordError(
                      Exception(
                        'Фатальна помилка при натисканні на категорію Транспорт',
                      ),
                      StackTrace.current,
                      reason: 'Фатальний тестовий краш - Транспорт',
                      fatal: true,
                    );
                    throw Exception('Фатальна тестова помилка - Транспорт');
                  } else {
                    if (context.mounted) {
                      await FirebaseAnalytics.instance.logEvent(
                        name: 'view_category_expenses',
                        parameters: {
                          'category_name': category['name'] as String,
                          'timestamp': DateTime.now().toIso8601String(),
                        },
                      );

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CategoryExpensesScreen(
                            categoryName: category['name'] as String,
                            categoryIcon: category['icon'] as String,
                            categoryColor: category['color'] as Color,
                          ),
                        ),
                      );
                    }
                  }
                },
                child: Column(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: (category['color'] as Color).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Center(
                        child: Text(
                          category['icon'] as String,
                          style: const TextStyle(fontSize: 20),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      category['name'] as String,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
