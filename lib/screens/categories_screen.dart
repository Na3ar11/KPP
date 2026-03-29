import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/category.dart';
import '../providers/categories_provider.dart';
import '../providers/user_settings_provider.dart';
import '../utils/currency_converter.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  @override
  void dispose() {
    final provider = context.read<CategoriesProvider>();
    if (provider.includeArchived) {
      provider.setIncludeArchived(false);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(title: const Text('Категорії')),
      body: Consumer2<CategoriesProvider, UserSettingsProvider>(
        builder: (context, categoriesProvider, settingsProvider, child) {
          final categories = categoriesProvider.categories;
          final currency = settingsProvider.currency;
          final includeArchived = categoriesProvider.includeArchived;

          if (categoriesProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (categoriesProvider.errorMessage != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  categoriesProvider.errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            );
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  tileColor: Colors.white,
                  value: includeArchived,
                  title: const Text('Показувати архівні'),
                  subtitle: const Text(
                    'Дозволяє бачити та відновлювати архівовані категорії',
                  ),
                  onChanged: (value) async {
                    await categoriesProvider.setIncludeArchived(value);
                  },
                ),
              ),
              Expanded(
                child: categories.isEmpty
                    ? Center(
                        child: Text(
                          includeArchived
                              ? 'Категорій не знайдено'
                              : 'Категорій ще немає',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: categories.length,
                        itemBuilder: (context, index) {
                          final category = categories[index];
                          final isSystem = _isSystemCategory(
                            category,
                            categoriesProvider.userId,
                          );

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _CategoryCard(
                              category: category,
                              budgetText: CurrencyConverter.formatFromUah(
                                category.monthlyBudget,
                                currency,
                                decimalDigits: 2,
                              ),
                              onEdit: () => _showCategorySheet(
                                context,
                                category: category,
                              ),
                              onDelete: isSystem
                                  ? null
                                  : () => _confirmDelete(context, category),
                              onRestore: category.isArchived
                                  ? () => _restoreCategory(context, category)
                                  : null,
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCategorySheet(context),
        backgroundColor: const Color(0xFF667EEA),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Категорія'),
      ),
    );
  }

  bool _isSystemCategory(Category category, String? currentUserId) {
    if (currentUserId == null) {
      return false;
    }
    return category.id.startsWith('${currentUserId}_cat_');
  }

  Future<void> _confirmDelete(BuildContext context, Category category) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Видалити категорію?'),
        content: Text('Категорія "${category.name}" буде видалена назавжди.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Скасувати'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Видалити'),
          ),
        ],
      ),
    );

    if (shouldDelete != true || !context.mounted) return;

    try {
      await context.read<CategoriesProvider>().deleteCategory(category);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Категорію видалено'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Color(0xFF2EAD69),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Помилка: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _restoreCategory(BuildContext context, Category category) async {
    try {
      await context.read<CategoriesProvider>().restoreCategory(category.id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Категорію відновлено'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Color(0xFF2EAD69),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Помилка: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _showCategorySheet(
    BuildContext context, {
    Category? category,
  }) async {
    final isEdit = category != null;
    final settings = context.read<UserSettingsProvider>();
    final selectedCurrency = settings.currency;

    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: category?.name ?? '');
    final budgetController = TextEditingController(
      text: category == null
          ? ''
          : CurrencyConverter.convertFromUah(
              category.monthlyBudget,
              selectedCurrency,
            ).toStringAsFixed(2),
    );

    final iconOptions = const [
      '🍕',
      '🚕',
      '🛒',
      '💊',
      '🎬',
      '🏠',
      '📚',
      '🎯',
      '💡',
      '🧾',
    ];
    final colorOptions = const [
      0xFFE53E3E,
      0xFF3182CE,
      0xFF38A169,
      0xFFD69E2E,
      0xFF4A5568,
      0xFF2D3748,
      0xFF38B2AC,
      0xFF8B5CF6,
      0xFFF97316,
      0xFF06B6D4,
    ];

    String selectedIcon = category?.icon ?? iconOptions.first;
    int selectedColor = category?.colorValue ?? colorOptions.first;
    final customIconController = TextEditingController(text: selectedIcon);

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        bool isSaving = false;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                top: 16,
              ),
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEdit ? 'Редагувати категорію' : 'Нова категорія',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: nameController,
                          decoration: const InputDecoration(
                            labelText: 'Назва',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Введіть назву категорії';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: budgetController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(
                            labelText:
                                'Бюджет (${CurrencyConverter.symbolFor(selectedCurrency)})',
                            border: const OutlineInputBorder(),
                          ),
                          validator: (value) {
                            final parsed = double.tryParse(
                              (value ?? '').replaceAll(',', '.'),
                            );
                            if (parsed == null || parsed < 0) {
                              return 'Введіть коректний бюджет';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Іконка',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: iconOptions.map((icon) {
                            final selected = selectedIcon == icon;
                            return InkWell(
                              onTap: () => setModalState(() {
                                selectedIcon = icon;
                                customIconController.text = icon;
                              }),
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: selected
                                      ? const Color(0xFFEFF2FF)
                                      : const Color(0xFFF3F4F6),
                                  borderRadius: BorderRadius.circular(10),
                                  border: selected
                                      ? Border.all(
                                          color: const Color(0xFF667EEA),
                                          width: 2,
                                        )
                                      : null,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  icon,
                                  style: const TextStyle(fontSize: 20),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: customIconController,
                          maxLength: 8,
                          decoration: const InputDecoration(
                            labelText: 'Свій емодзі (опційно)',
                            hintText: 'Наприклад: 🧘',
                            border: OutlineInputBorder(),
                            counterText: '',
                          ),
                          onChanged: (value) {
                            final trimmed = value.trim();
                            if (trimmed.isNotEmpty) {
                              setModalState(() => selectedIcon = trimmed);
                            }
                          },
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Колір',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: colorOptions.map((colorValue) {
                            final selected = selectedColor == colorValue;
                            return InkWell(
                              onTap: () => setModalState(
                                () => selectedColor = colorValue,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: Color(colorValue),
                                  shape: BoxShape.circle,
                                  border: selected
                                      ? Border.all(
                                          color: Colors.black87,
                                          width: 2,
                                        )
                                      : Border.all(
                                          color: Colors.white,
                                          width: 2,
                                        ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: isSaving
                                ? null
                                : () async {
                                    if (!formKey.currentState!.validate())
                                      return;

                                    final rawBudget = budgetController.text
                                        .replaceAll(',', '.');
                                    final typedBudget = double.parse(rawBudget);
                                    final finalIcon =
                                        customIconController.text.trim().isEmpty
                                        ? selectedIcon
                                        : customIconController.text.trim();
                                    final budgetInUah =
                                        CurrencyConverter.convertToUah(
                                          typedBudget,
                                          selectedCurrency,
                                        );

                                    setModalState(() => isSaving = true);
                                    try {
                                      if (isEdit) {
                                        final updated = category!.copyWith(
                                          name: nameController.text.trim(),
                                          icon: finalIcon,
                                          colorValue: selectedColor,
                                          monthlyBudget: budgetInUah,
                                          updatedAt: DateTime.now(),
                                        );
                                        await context
                                            .read<CategoriesProvider>()
                                            .updateCategory(updated);
                                      } else {
                                        await context
                                            .read<CategoriesProvider>()
                                            .addCategory(
                                              name: nameController.text.trim(),
                                              icon: finalIcon,
                                              colorValue: selectedColor,
                                              monthlyBudget: budgetInUah,
                                            );
                                      }

                                      if (!context.mounted) return;
                                      Navigator.pop(context, true);
                                    } catch (e) {
                                      if (!context.mounted) return;
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text('Помилка: $e'),
                                          backgroundColor: Colors.red,
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                      setModalState(() => isSaving = false);
                                    }
                                  },
                            child: isSaving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    isEdit
                                        ? 'Зберегти зміни'
                                        : 'Створити категорію',
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
    customIconController.dispose();

    if (result == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEdit ? 'Категорію оновлено' : 'Категорію створено'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF2EAD69),
        ),
      );
    }
  }
}

class _CategoryCard extends StatelessWidget {
  final Category category;
  final String budgetText;
  final VoidCallback onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onRestore;

  const _CategoryCard({
    required this.category,
    required this.budgetText,
    required this.onEdit,
    this.onDelete,
    this.onRestore,
  });

  @override
  Widget build(BuildContext context) {
    final color = Color(category.colorValue);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withOpacity(0.16),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(category.icon, style: const TextStyle(fontSize: 22)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (category.isArchived)
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Text(
                      'Архівовано',
                      style: TextStyle(
                        color: Color(0xFFE67E22),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                Text(
                  'Бюджет: $budgetText',
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') {
                onEdit();
              } else if (value == 'delete' && onDelete != null) {
                onDelete!();
              } else if (value == 'restore' && onRestore != null) {
                onRestore!();
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'edit', child: Text('Редагувати')),
              if (onDelete != null)
                const PopupMenuItem(value: 'delete', child: Text('Видалити')),
              if (category.isArchived)
                const PopupMenuItem(value: 'restore', child: Text('Відновити')),
            ],
          ),
        ],
      ),
    );
  }
}
