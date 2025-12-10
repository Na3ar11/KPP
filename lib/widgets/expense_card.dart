import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../screens/expense_detail_screen.dart';

class ExpenseCard extends StatelessWidget {
  final IconData icon;
  final String category;
  final String description;
  final double amount;
  final Color color;

  const ExpenseCard({
    super.key,
    required this.icon,
    required this.category,
    required this.description,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final formattedAmount = NumberFormat.currency(locale: 'uk_UA', symbol: '₴').format(amount);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          // Конвертуємо IconData в emoji для деталей
          String emoji;
          switch (icon) {
            case Icons.fastfood:
              emoji = '🍕';
              break;
            case Icons.local_cafe:
              emoji = '☕';
              break;
            case Icons.shopping_cart:
              emoji = '🛒';
              break;
            case Icons.directions_car:
              emoji = '🚗';
              break;
            case Icons.local_hospital:
              emoji = '💊';
              break;
            case Icons.movie:
              emoji = '🎬';
              break;
            case Icons.home:
              emoji = '🏠';
              break;
            case Icons.school:
              emoji = '📚';
              break;
            default:
              emoji = '💰';
          }

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ExpenseDetailScreen(
                id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
                icon: emoji,
                category: category,
                description: description,
                amount: amount,
                color: color,
                date: DateTime.now(),
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: color.withOpacity(0.1),
            foregroundColor: color,
            child: Icon(icon),
          ),
          title: Text(category, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(description),
          trailing: Text(
            formattedAmount,
            style: TextStyle(
              color: amount < 0 ? Colors.red : Colors.green,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }
}