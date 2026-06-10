import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/currency_formatter.dart';
import '../../models/expense_model.dart';
import '../../services/api_service.dart';
import '../../shared/widgets/app_sidebar_drawer.dart';
import 'add_expense_screen.dart';

class ExpenseListScreen extends StatefulWidget {
  const ExpenseListScreen({super.key});

  @override
  State<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends State<ExpenseListScreen> {
  final searchCtrl = TextEditingController();
  List<ExpenseModel> expenses = [];
  bool loading = true;
  String? error;
  String? selectedCategory;
  String? selectedStatus;

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    searchCtrl.dispose();
    super.dispose();
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final res = await ApiService().get(
        '/expenses',
        query: {
          if (searchCtrl.text.trim().isNotEmpty) 'search': searchCtrl.text.trim(),
          if (selectedCategory != null) 'category': selectedCategory,
          if (selectedStatus?.isNotEmpty ?? false) 'paymentStatus': selectedStatus,
        },
      );
      final list = (res['data'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(ExpenseModel.fromJson)
          .toList();

      if (!mounted) return;
      setState(() => expenses = list);
    } catch (e) {
      if (!mounted) return;
      setState(() => error = e.toString());
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  Future<void> deleteExpense(String id) async {
    try {
      await ApiService().delete('/expenses/$id');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Expense deleted')),
      );
      await load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> openAddExpense({ExpenseModel? expense}) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AddExpenseScreen(
          initialData: expense?.toJsonWithId(),
        ),
      ),
    );

    if (changed == true) {
      await load();
    }
  }

  Future<void> confirmDelete(ExpenseModel expense) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete expense?'),
        content: Text('This will remove "${expense.title}".'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && expense.id != null) {
      await deleteExpense(expense.id!);
    }
  }

  Future<void> openFilters() async {
    String? category = selectedCategory;
    String? status = selectedStatus;

    await showModalBottomSheet<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Filter Expenses', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                DropdownButtonFormField<String?>(
                  initialValue: category,
                  items: [
                    const DropdownMenuItem<String?>(value: null, child: Text('All categories')),
                    ...AppConstants.categories.map(
                      (item) => DropdownMenuItem<String?>(value: item, child: Text(item)),
                    ),
                  ],
                  onChanged: (value) => setSheetState(() => category = value),
                  decoration: const InputDecoration(labelText: 'Category'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String?>(
                  initialValue: status,
                  items: [
                    const DropdownMenuItem<String?>(value: null, child: Text('All statuses')),
                    ...AppConstants.paymentStatuses.map(
                      (item) => DropdownMenuItem<String?>(value: item, child: Text(item)),
                    ),
                  ],
                  onChanged: (value) => setSheetState(() => status = value),
                  decoration: const InputDecoration(labelText: 'Payment Status'),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      setState(() {
                        selectedCategory = category;
                        selectedStatus = status;
                      });
                      Navigator.pop(context);
                      load();
                    },
                    child: const Text('Apply Filters'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String buildMeta(ExpenseModel expense) {
    final parts = <String>[
      expense.category,
      expense.paymentStatus,
      DateFormat('dd MMM yyyy').format(expense.expenseDate),
    ];

    if (expense.dueDate != null) {
      parts.add('Due ${DateFormat('dd MMM').format(expense.dueDate!)}');
    }

    return parts.join(' • ');
  }

  Color statusColor(String status) {
    switch (status) {
      case 'Paid':
        return const Color(0xFF2EB67D);
      case 'Partial':
        return const Color(0xFFF2A541);
      default:
        return const Color(0xFFE35D6A);
    }
  }

  Future<void> sendExpenseReminder(ExpenseModel expense) async {
    final phone = (expense.shopkeeperPhone ?? '').trim();
    final shopkeeper = (expense.shopkeeperName ?? '').trim();
    if (phone.isEmpty || shopkeeper.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add shopkeeper name and mobile number first.')),
      );
      return;
    }

    final cleanedPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final message = '''
Hello $shopkeeper,

This is a payment reminder regarding the following expense:

Title: ${expense.title}
Category: ${expense.category}
Total: ${formatInr(expense.amount)}
Paid: ${formatInr(expense.paidAmount)}
Balance: ${formatInr(expense.balanceAmount)}
${expense.dueDate == null ? '' : 'Due Date: ${DateFormat('dd MMM yyyy').format(expense.dueDate!)}'}

Please review the pending amount and update us once settled.
''';

    final uri = Uri.parse('https://wa.me/$cleanedPhone?text=${Uri.encodeComponent(message)}');
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open WhatsApp.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalAmount = expenses.fold<double>(0, (sum, item) => sum + item.amount);
    final totalPaid = expenses.fold<double>(0, (sum, item) => sum + item.paidAmount);
    final totalBalance = expenses.fold<double>(0, (sum, item) => sum + item.balanceAmount);

    return Scaffold(
      drawer: const AppSidebarDrawer(),
      appBar: AppBar(
        title: const Text('Expenses'),
        actions: const [
          Center(
            child: Padding(
              padding: EdgeInsets.only(right: 16),
              child: Text(
                'NBExpenseManager',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'expenses_add_fab',
        onPressed: () => openAddExpense(),
        icon: const Icon(Icons.add),
        label: const Text('Add Expense'),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? _ErrorState(message: error!, onRetry: load)
              : RefreshIndicator(
                  onRefresh: load,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                    children: [
                      _ExpenseHeroCard(
                        totalAmount: totalAmount,
                        totalPaid: totalPaid,
                        totalBalance: totalBalance,
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x12000000),
                              blurRadius: 18,
                              offset: Offset(0, 8),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: searchCtrl,
                          textInputAction: TextInputAction.search,
                          decoration: InputDecoration(
                            hintText: 'Search title, shopkeeper, or notes',
                            prefixIcon: const Icon(Icons.search),
                            border: InputBorder.none,
                            suffixIcon: searchCtrl.text.isEmpty
                                ? null
                                : IconButton(
                                    onPressed: () {
                                      searchCtrl.clear();
                                      setState(() {});
                                      load();
                                    },
                                    icon: const Icon(Icons.close),
                                  ),
                          ),
                          onChanged: (_) => setState(() {}),
                          onSubmitted: (_) => load(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Smart filters',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                          FilledButton.tonalIcon(
                            onPressed: openFilters,
                            icon: const Icon(Icons.tune),
                            label: const Text('Filters'),
                          ),
                        ],
                      ),
                      if (selectedCategory != null || selectedStatus != null) ...[
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            if (selectedCategory != null)
                              InputChip(
                                label: Text(selectedCategory!),
                                onDeleted: () {
                                  setState(() => selectedCategory = null);
                                  load();
                                },
                              ),
                            if (selectedStatus != null)
                              InputChip(
                                label: Text(selectedStatus!),
                                onDeleted: () {
                                  setState(() => selectedStatus = null);
                                  load();
                                },
                              ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Recent Expenses',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                          Text(
                            '${expenses.length} item${expenses.length == 1 ? '' : 's'}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (expenses.isEmpty)
                        const _EmptyState()
                      else
                        ...expenses.map(
                          (expense) => _ExpensePremiumCard(
                            expense: expense,
                            statusColor: statusColor(expense.paymentStatus),
                            meta: buildMeta(expense),
                            onTap: () => openAddExpense(expense: expense),
                            onWhatsApp: () => sendExpenseReminder(expense),
                            onDelete: expense.id == null ? null : () => confirmDelete(expense),
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }
}

class _ExpenseHeroCard extends StatelessWidget {
  const _ExpenseHeroCard({
    required this.totalAmount,
    required this.totalPaid,
    required this.totalBalance,
  });

  final double totalAmount;
  final double totalPaid;
  final double totalBalance;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF202B76), Color(0xFF5B6EF5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x225B6EF5),
            blurRadius: 24,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Expense Wallet',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'A cleaner look at what you spent, paid, and still owe.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.82),
                ),
          ),
          const SizedBox(height: 18),
          Text(
            'Total Tracked',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.72),
                ),
          ),
          const SizedBox(height: 4),
          Text(
            formatInr(totalAmount),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _ExpenseHeroMetric(
                  label: 'Paid',
                  value: formatInr(totalPaid),
                  bulletColor: const Color(0xFF2ED3A1),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ExpenseHeroMetric(
                  label: 'Balance',
                  value: formatInr(totalBalance),
                  bulletColor: const Color(0xFFFFC857),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ExpenseHeroMetric extends StatelessWidget {
  const _ExpenseHeroMetric({
    required this.label,
    required this.value,
    required this.bulletColor,
  });

  final String label;
  final String value;
  final Color bulletColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: bulletColor,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
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

class _ExpensePremiumCard extends StatelessWidget {
  const _ExpensePremiumCard({
    required this.expense,
    required this.statusColor,
    required this.meta,
    required this.onTap,
    required this.onWhatsApp,
    required this.onDelete,
  });

  final ExpenseModel expense;
  final Color statusColor;
  final String meta;
  final VoidCallback onTap;
  final VoidCallback onWhatsApp;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final paidRatio = expense.amount <= 0
        ? 0.0
        : ((expense.paidAmount / expense.amount).clamp(0.0, 1.0) as num).toDouble();

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(Icons.receipt_long_outlined, color: statusColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          expense.title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        if ((expense.shopkeeperName ?? '').trim().isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            expense.shopkeeperName!.trim(),
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                        const SizedBox(height: 4),
                        Text(
                          meta,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        formatInr(expense.amount),
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 8),
                      _StatusBadge(
                        label: expense.paymentStatus,
                        color: statusColor,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  minHeight: 10,
                  value: paidRatio,
                  backgroundColor: statusColor.withValues(alpha: 0.12),
                  valueColor: AlwaysStoppedAnimation(statusColor),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _ExpenseValueBlock(
                      label: 'Paid',
                      value: formatInr(expense.paidAmount),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ExpenseValueBlock(
                      label: 'Balance',
                      value: formatInr(expense.balanceAmount),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton.filledTonal(
                    tooltip: 'Send WhatsApp reminder',
                    onPressed: onWhatsApp,
                    icon: const Icon(Icons.send_outlined),
                  ),
                  if (onDelete != null) ...[
                    const SizedBox(width: 10),
                    IconButton.filledTonal(
                      tooltip: 'Delete expense',
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ExpenseValueBlock extends StatelessWidget {
  const _ExpenseValueBlock({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FC),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFF5B6EF5).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.receipt_long_outlined,
              color: Color(0xFF5B6EF5),
              size: 34,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No expenses found',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try changing your filters or add a new expense to start tracking your spending.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
