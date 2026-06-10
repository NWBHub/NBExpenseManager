import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/utils/currency_formatter.dart';
import '../../models/expense_model.dart';
import '../../services/api_service.dart';

class ShopkeeperStatementScreen extends StatefulWidget {
  const ShopkeeperStatementScreen({super.key});

  @override
  State<ShopkeeperStatementScreen> createState() => _ShopkeeperStatementScreenState();
}

class _ShopkeeperStatementScreenState extends State<ShopkeeperStatementScreen> {
  late DateTime selectedMonth;
  bool loading = true;
  String? error;
  List<ExpenseModel> expenses = [];

  @override
  void initState() {
    super.initState();
    selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
    load();
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      error = null;
    });

    final start = DateTime(selectedMonth.year, selectedMonth.month, 1);
    final end = DateTime(selectedMonth.year, selectedMonth.month + 1, 0, 23, 59, 59);

    try {
      final res = await ApiService().get(
        '/expenses',
        query: {
          'from': start.toIso8601String(),
          'to': end.toIso8601String(),
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
      if (mounted) setState(() => loading = false);
    }
  }

  void changeMonth(int offset) {
    setState(() {
      selectedMonth = DateTime(selectedMonth.year, selectedMonth.month + offset);
    });
    load();
  }

  Map<String, List<ExpenseModel>> get groupedExpenses {
    final grouped = <String, List<ExpenseModel>>{};
    for (final expense in expenses) {
      final key = (expense.shopkeeperName ?? '').trim().isNotEmpty
          ? expense.shopkeeperName!.trim()
          : (expense.title.trim().isEmpty ? 'Unknown Shopkeeper' : expense.title.trim());
      grouped.putIfAbsent(key, () => []).add(expense);
    }
    return grouped;
  }

  String shopkeeperPhone(List<ExpenseModel> vendorExpenses) {
    for (final expense in vendorExpenses) {
      final phone = (expense.shopkeeperPhone ?? '').trim();
      if (phone.isNotEmpty) {
        return phone;
      }
    }
    return '';
  }

  String buildStatementText(String vendor, List<ExpenseModel> vendorExpenses) {
    final total = vendorExpenses.fold<double>(0, (sum, item) => sum + item.amount);
    final paid = vendorExpenses.fold<double>(0, (sum, item) => sum + item.paidAmount);
    final balance = vendorExpenses.fold<double>(0, (sum, item) => sum + item.balanceAmount);
    final buffer = StringBuffer()
      ..writeln('Monthly Ledger Statement')
      ..writeln('Shopkeeper: $vendor')
      ..writeln('Period: ${DateFormat('MMMM yyyy').format(selectedMonth)}')
      ..writeln('')
      ..writeln('Statement Details:')
      ..writeln('');

    for (final expense in vendorExpenses) {
      buffer
        ..writeln(
          '- ${DateFormat('dd MMM yyyy').format(expense.expenseDate)} | ${expense.category} | ${formatInr(expense.amount)}',
        )
        ..writeln('  Paid: ${formatInr(expense.paidAmount)} | Balance: ${formatInr(expense.balanceAmount)}');
      if ((expense.notes ?? '').trim().isNotEmpty) {
        buffer.writeln('  Note: ${expense.notes!.trim()}');
      }
      buffer.writeln('');
    }

    buffer
      ..writeln('Total: ${formatInr(total)}')
      ..writeln('Paid: ${formatInr(paid)}')
      ..writeln('Balance: ${formatInr(balance)}');

    return buffer.toString();
  }

  Future<void> shareToWhatsApp(String vendor, List<ExpenseModel> vendorExpenses) async {
    final message = buildStatementText(vendor, vendorExpenses);
    final phone = shopkeeperPhone(vendorExpenses).replaceAll(RegExp(r'[^0-9]'), '');
    final uri = phone.isEmpty
        ? Uri.parse('https://wa.me/?text=${Uri.encodeComponent(message)}')
        : Uri.parse('https://wa.me/$phone?text=${Uri.encodeComponent(message)}');
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open WhatsApp sharing.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final vendorEntries = groupedExpenses.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return Scaffold(
      appBar: AppBar(title: const Text('Shopkeeper Statements')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? _ErrorState(message: error!, onRetry: load)
              : RefreshIndicator(
                  onRefresh: load,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              IconButton(
                                onPressed: () => changeMonth(-1),
                                icon: const Icon(Icons.chevron_left),
                              ),
                              Expanded(
                                child: Text(
                                  DateFormat('MMMM yyyy').format(selectedMonth),
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                              ),
                              IconButton(
                                onPressed: () => changeMonth(1),
                                icon: const Icon(Icons.chevron_right),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(22),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1F2A77), Color(0xFF5B6EF5)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Monthly Billing Center',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Generate monthly shopkeeper statements and share them over WhatsApp.',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.85),
                                  ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      if (vendorEntries.isEmpty)
                        const Card(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Text('No shopkeeper statements available for this month.'),
                          ),
                        )
                      else
                        ...vendorEntries.map((entry) {
                          final vendor = entry.key;
                          final vendorExpenses = entry.value;
                          final total =
                              vendorExpenses.fold<double>(0, (sum, item) => sum + item.amount);
                          final paid =
                              vendorExpenses.fold<double>(0, (sum, item) => sum + item.paidAmount);
                          final balance = vendorExpenses.fold<double>(
                            0,
                            (sum, item) => sum + item.balanceAmount,
                          );
                          final phone = shopkeeperPhone(vendorExpenses);

                          return Card(
                            margin: const EdgeInsets.only(bottom: 14),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          vendor,
                                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                      ),
                                      FilledButton.tonalIcon(
                                        onPressed: () => shareToWhatsApp(vendor, vendorExpenses),
                                        icon: const Icon(Icons.send_outlined),
                                        label: const Text('WhatsApp'),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Text('${vendorExpenses.length} entr${vendorExpenses.length == 1 ? 'y' : 'ies'}'),
                                  const SizedBox(height: 10),
                                  if (phone.isNotEmpty) ...[
                                    Text('Mobile: $phone'),
                                    const SizedBox(height: 4),
                                  ],
                                  Text('Total: ${formatInr(total)}'),
                                  Text('Paid: ${formatInr(paid)}'),
                                  Text('Balance: ${formatInr(balance)}'),
                                  const SizedBox(height: 12),
                                  OutlinedButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => ShopkeeperStatementDetailScreen(
                                            vendor: vendor,
                                            month: selectedMonth,
                                            expenses: vendorExpenses,
                                            statementText: buildStatementText(vendor, vendorExpenses),
                                          ),
                                        ),
                                      );
                                    },
                                    child: const Text('View Statement'),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                    ],
                  ),
                ),
    );
  }
}

class ShopkeeperStatementDetailScreen extends StatelessWidget {
  const ShopkeeperStatementDetailScreen({
    super.key,
    required this.vendor,
    required this.month,
    required this.expenses,
    required this.statementText,
  });

  final String vendor;
  final DateTime month;
  final List<ExpenseModel> expenses;
  final String statementText;

  Future<void> shareToWhatsApp(BuildContext context) async {
    final uri = Uri.parse('https://wa.me/?text=${Uri.encodeComponent(statementText)}');
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open WhatsApp sharing.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = expenses.fold<double>(0, (sum, item) => sum + item.amount);
    final paid = expenses.fold<double>(0, (sum, item) => sum + item.paidAmount);
    final balance = expenses.fold<double>(0, (sum, item) => sum + item.balanceAmount);

    return Scaffold(
      appBar: AppBar(title: Text(vendor)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Statement Preview',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 6),
                  Text(DateFormat('MMMM yyyy').format(month)),
                  const SizedBox(height: 12),
                  Text('Total: ${formatInr(total)}'),
                  Text('Paid: ${formatInr(paid)}'),
                  Text('Balance: ${formatInr(balance)}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          ...expenses.map(
            (expense) => Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                title: Text(expense.category),
                subtitle: Text(
                  '${DateFormat('dd MMM yyyy').format(expense.expenseDate)}\nPaid ${formatInr(expense.paidAmount)} | Balance ${formatInr(expense.balanceAmount)}${(expense.notes ?? '').trim().isEmpty ? '' : '\n${expense.notes!.trim()}'}',
                ),
                isThreeLine: true,
                trailing: Text(formatInr(expense.amount)),
              ),
            ),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: () => shareToWhatsApp(context),
            icon: const Icon(Icons.send_outlined),
            label: const Text('Send Full Statement to WhatsApp'),
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
