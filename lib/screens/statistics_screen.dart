import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/expense.dart';
import '../providers/firestore_expenses_provider.dart';
import '../providers/user_settings_provider.dart';
import '../utils/currency_converter.dart';
import '../widgets/app_bottom_nav_bar.dart';
import 'budget_screen.dart';
import 'settings_screen.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Статистика',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: Consumer2<FirestoreExpensesProvider, UserSettingsProvider>(
        builder: (context, provider, settingsProvider, child) {
          final currency = settingsProvider.currency;
          final now = DateTime.now();
          final monthExpenses = provider.expenses
              .where(
                (e) => e.date.year == now.year && e.date.month == now.month,
              )
              .toList();

          if (monthExpenses.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Ще немає витрат за поточний місяць,\nдодайте першу витрату для статистики.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
                ),
              ),
            );
          }

          final categoryStats = _buildCategoryStats(monthExpenses);
          final total = monthExpenses.fold<double>(
            0,
            (sum, e) => sum + e.amount,
          );

          return SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 650),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                  child: Column(
                    children: [
                      _CategoryChartCard(
                        categories: categoryStats,
                        total: total,
                        currency: currency,
                      ),
                      const SizedBox(height: 16),
                      _TrendChartCard(
                        categories: categoryStats,
                        expenses: monthExpenses,
                        currency: currency,
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
        currentIndex: 1,
        onTap: (index) {
          if (index == 1) return;

          if (index == 0) {
            Navigator.pop(context);
            return;
          }

          if (index == 2) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const BudgetScreen()),
            );
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
              content: Text('Екран налаштувань додамо наступним кроком'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      ),
    );
  }

  List<_CategoryStat> _buildCategoryStats(List<Expense> expenses) {
    final map = <String, _CategoryStat>{};

    for (final expense in expenses) {
      final categoryKey = _categoryKey(expense);
      final existing = map[categoryKey];
      if (existing == null) {
        map[categoryKey] = _CategoryStat(
          key: categoryKey,
          category: expense.categoryNameSnapshot,
          color: Color(expense.categoryColorSnapshot),
          icon: expense.categoryIconSnapshot,
          amount: expense.amount,
          count: 1,
        );
      } else {
        map[categoryKey] = existing.copyWith(
          amount: existing.amount + expense.amount,
          count: existing.count + 1,
        );
      }
    }

    final list = map.values.toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));

    final total = list.fold<double>(0, (sum, item) => sum + item.amount);
    return list
        .map(
          (item) => item.copyWith(
            percent: total <= 0 ? 0 : (item.amount / total) * 100,
          ),
        )
        .toList();
  }

  String _categoryKey(Expense expense) {
    final id = expense.categoryId;
    if (id != null && id.trim().isNotEmpty) {
      return 'id:$id';
    }
    return 'legacy:${expense.category}';
  }
}

class _CategoryChartCard extends StatelessWidget {
  final List<_CategoryStat> categories;
  final double total;
  final String currency;

  const _CategoryChartCard({
    required this.categories,
    required this.total,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Витрати за категоріями',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 250,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    centerSpaceRadius: 70,
                    sectionsSpace: 3,
                    sections: categories
                        .map(
                          (item) => PieChartSectionData(
                            color: item.color,
                            value: item.amount,
                            radius: 48,
                            title: '${item.percent.toStringAsFixed(0)}%',
                            titleStyle: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      CurrencyConverter.formatFromUah(total, currency),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF2D3137),
                      ),
                    ),
                    const Text(
                      'Всього',
                      style: TextStyle(fontSize: 20, color: Color(0xFF6B7280)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          ...categories.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF6F7FB),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: item.color,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(item.icon, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.category,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF2D3137),
                            ),
                          ),
                          Text(
                            '${item.count} транзакцій',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      CurrencyConverter.formatFromUah(item.amount, currency),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2D3137),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 48,
                      child: Text(
                        '${item.percent.toStringAsFixed(0)}%',
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _TrendChartCard extends StatelessWidget {
  final List<_CategoryStat> categories;
  final List<Expense> expenses;
  final String currency;

  const _TrendChartCard({
    required this.categories,
    required this.expenses,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final daysCount = 7;
    final startDate = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(const Duration(days: 6));

    final dayLabels = List.generate(
      daysCount,
      (index) => startDate.add(Duration(days: index)),
    );
    final topCategories = categories.take(5).toList();

    final lineBars = <LineChartBarData>[];
    double maxY = 0;

    for (final category in topCategories) {
      final spots = <FlSpot>[];
      for (int i = 0; i < dayLabels.length; i++) {
        final day = dayLabels[i];
        final dayTotal = expenses
            .where(
              (e) =>
                  _categoryKeyForTrend(e) == category.key &&
                  e.date.year == day.year &&
                  e.date.month == day.month &&
                  e.date.day == day.day,
            )
            .fold<double>(0, (sum, e) => sum + e.amount);

        final convertedDayTotal = CurrencyConverter.convertFromUah(
          dayTotal,
          currency,
        );

        maxY = math.max(maxY, convertedDayTotal);
        spots.add(FlSpot(i.toDouble(), convertedDayTotal));
      }

      lineBars.add(
        LineChartBarData(
          spots: spots,
          isCurved: true,
          barWidth: 3,
          color: category.color,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(show: false),
        ),
      );
    }

    if (maxY <= 0) {
      maxY = 100;
    }

    final yStep = maxY / 4;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Динаміка витрат',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Container(
            height: 260,
            padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFF2F4FA), Color(0xFFEFF2FF)],
              ),
            ),
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: (daysCount - 1).toDouble(),
                minY: 0,
                maxY: maxY * 1.2,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: yStep,
                  getDrawingHorizontalLine: (_) =>
                      const FlLine(color: Color(0xFFE1E6F0), strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 52,
                      interval: yStep,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${CurrencyConverter.symbolFor(currency)}${value.toInt()}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF6B7280),
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= dayLabels.length) {
                          return const SizedBox.shrink();
                        }
                        final date = dayLabels[idx];
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            DateFormat('dd.MM').format(date),
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: lineBars,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 10,
            children: topCategories
                .map(
                  (c) => Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: c.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        c.category,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF4B5563),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _CategoryStat {
  final String key;
  final String category;
  final Color color;
  final String icon;
  final double amount;
  final int count;
  final double percent;

  const _CategoryStat({
    required this.key,
    required this.category,
    required this.color,
    required this.icon,
    required this.amount,
    required this.count,
    this.percent = 0,
  });

  _CategoryStat copyWith({
    String? key,
    String? category,
    Color? color,
    String? icon,
    double? amount,
    int? count,
    double? percent,
  }) {
    return _CategoryStat(
      key: key ?? this.key,
      category: category ?? this.category,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      amount: amount ?? this.amount,
      count: count ?? this.count,
      percent: percent ?? this.percent,
    );
  }
}

String _categoryKeyForTrend(Expense expense) {
  final id = expense.categoryId;
  if (id != null && id.trim().isNotEmpty) {
    return 'id:$id';
  }
  return 'legacy:${expense.category}';
}
