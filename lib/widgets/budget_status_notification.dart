import 'package:flutter/material.dart';

enum BudgetNotificationState {
  safe,
  warning,
  danger,
}

class BudgetStatusNotification extends StatelessWidget {
  final BudgetNotificationState state;
  final double spentAmount;
  final double budgetAmount;

  const BudgetStatusNotification({
    super.key,
    required this.state,
    required this.spentAmount,
    required this.budgetAmount,
  });

  @override
  Widget build(BuildContext context) {
    final percent = budgetAmount <= 0 ? 0.0 : (spentAmount / budgetAmount) * 100;

    final config = switch (state) {
      BudgetNotificationState.safe => _NotificationConfig(
          title: 'Бюджет під контролем',
          message: 'Витрачено ${percent.toStringAsFixed(0)}% бюджету. Рівень витрат безпечний.',
          icon: Icons.check_circle,
          accent: const Color(0xFF2EAD69),
          background: const Color(0xFFEAF8F0),
          border: const Color(0xFFA7E4C2),
        ),
      BudgetNotificationState.warning => _NotificationConfig(
          title: 'Наближаєтесь до ліміту',
          message: 'Витрачено ${percent.toStringAsFixed(0)}% бюджету. Варто зменшити витрати.',
          icon: Icons.warning_amber_rounded,
          accent: const Color(0xFFE2A21A),
          background: const Color(0xFFFFF8E7),
          border: const Color(0xFFF2D486),
        ),
      BudgetNotificationState.danger => _NotificationConfig(
          title: 'Перевищено 80% ліміту',
          message: 'Витрачено ${percent.toStringAsFixed(0)}% бюджету. Ліміт майже вичерпано.',
          icon: Icons.error,
          accent: const Color(0xFFE04D4D),
          background: const Color(0xFFFFEFEF),
          border: const Color(0xFFF0B0B0),
        ),
    };

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: config.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: config.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: config.accent,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(config.icon, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  config.title,
                  style: TextStyle(
                    color: config.accent,
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  config.message,
                  style: const TextStyle(
                    color: Color(0xFF434A54),
                    fontSize: 14,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationConfig {
  final String title;
  final String message;
  final IconData icon;
  final Color accent;
  final Color background;
  final Color border;

  const _NotificationConfig({
    required this.title,
    required this.message,
    required this.icon,
    required this.accent,
    required this.background,
    required this.border,
  });
}
