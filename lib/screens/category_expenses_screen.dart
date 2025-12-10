import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/firestore_expenses_provider.dart';
import 'expense_detail_screen.dart';

class CategoryExpensesScreen extends StatelessWidget {
  final String categoryName;
  final String categoryIcon;
  final Color categoryColor;

  const CategoryExpensesScreen({
    super.key,
    required this.categoryName,
    required this.categoryIcon,
    required this.categoryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text('Витрати: $categoryName'),
        backgroundColor: categoryColor,
        foregroundColor: Colors.white,
      ),
      body: Consumer<FirestoreExpensesProvider>(
        builder: (context, provider, child) {
          final categoryExpenses = provider.getExpensesByCategory(categoryName);

          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (categoryExpenses.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    categoryIcon,
                    style: const TextStyle(fontSize: 80),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Немає витрат у категорії "$categoryName"',
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Додайте нову витрату',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }

          // Групуємо витрати по датам
          final groupedExpenses = <String, List<dynamic>>{};
          for (var expense in categoryExpenses) {
            final dateKey = _formatDate(expense.date);
            if (!groupedExpenses.containsKey(dateKey)) {
              groupedExpenses[dateKey] = [];
            }
            groupedExpenses[dateKey]!.add(expense);
          }

          // Підрахунок загальної суми
          final totalAmount = categoryExpenses.fold<double>(
            0,
            (sum, expense) => sum + expense.amount,
          );

          return Column(
            children: [
              // Статистика категорії
              Container(
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [categoryColor, categoryColor.withOpacity(0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: categoryColor.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Center(
                        child: Text(
                          categoryIcon,
                          style: const TextStyle(fontSize: 30),
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Загальна сума',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            '₴${totalAmount.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            '${categoryExpenses.length} ${_getPluralForm(categoryExpenses.length)}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Список витрат
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: groupedExpenses.length,
                  itemBuilder: (context, index) {
                    final date = groupedExpenses.keys.elementAt(index);
                    final expenses = groupedExpenses[date]!;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            date,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        ...expenses.map((expense) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildExpenseCard(context, expense),
                        )).toList(),
                      ],
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildExpenseCard(BuildContext context, dynamic expense) {
    return InkWell(
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
              color: expense.color,
              date: expense.date,
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: categoryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  expense.icon,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    expense.description,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(expense.date),
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '${expense.amount.toStringAsFixed(0)}₴',
              style: TextStyle(
                color: categoryColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateToCheck = DateTime(date.year, date.month, date.day);

    if (dateToCheck == today) {
      return 'Сьогодні';
    } else if (dateToCheck == yesterday) {
      return 'Вчора';
    } else {
      final months = [
        'Січня', 'Лютого', 'Березня', 'Квітня', 'Травня', 'Червня',
        'Липня', 'Серпня', 'Вересня', 'Жовтня', 'Листопада', 'Грудня'
      ];
      return '${date.day} ${months[date.month - 1]}';
    }
  }

  String _getPluralForm(int count) {
    if (count % 10 == 1 && count % 100 != 11) {
      return 'витрата';
    } else if ([2, 3, 4].contains(count % 10) && ![12, 13, 14].contains(count % 100)) {
      return 'витрати';
    } else {
      return 'витрат';
    }
  }
}
