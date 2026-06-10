import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/currency_formatter.dart';
import '../../services/api_service.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key, this.initialData});

  final Map<String, dynamic>? initialData;

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final titleCtrl = TextEditingController();
  final shopkeeperNameCtrl = TextEditingController();
  final shopkeeperPhoneCtrl = TextEditingController();
  final amountCtrl = TextEditingController();
  final paidCtrl = TextEditingController();
  final notesCtrl = TextEditingController();

  String category = AppConstants.categories.first;
  String paymentMode = 'Cash';
  DateTime expenseDate = DateTime.now();
  DateTime? dueDate;
  DateTime? reminderDate;
  bool saving = false;

  bool get isEditing => widget.initialData?['_id'] != null;

  @override
  void initState() {
    super.initState();
    final data = widget.initialData;
    if (data != null) {
      titleCtrl.text = '${data['title'] ?? ''}';
      shopkeeperNameCtrl.text = '${data['shopkeeperName'] ?? ''}';
      shopkeeperPhoneCtrl.text = '${data['shopkeeperPhone'] ?? ''}';
      amountCtrl.text = '${data['amount'] ?? ''}';
      paidCtrl.text = '${data['paidAmount'] ?? 0}';
      notesCtrl.text = '${data['notes'] ?? ''}';
      category = '${data['category'] ?? category}';
      paymentMode = '${data['paymentMode'] ?? paymentMode}';
      expenseDate = DateTime.tryParse('${data['expenseDate'] ?? ''}') ?? DateTime.now();
      dueDate = data['dueDate'] == null ? null : DateTime.tryParse('${data['dueDate']}');
      reminderDate =
          data['reminderDate'] == null ? null : DateTime.tryParse('${data['reminderDate']}');
    }
  }

  @override
  void dispose() {
    titleCtrl.dispose();
    shopkeeperNameCtrl.dispose();
    shopkeeperPhoneCtrl.dispose();
    amountCtrl.dispose();
    paidCtrl.dispose();
    notesCtrl.dispose();
    super.dispose();
  }

  double get totalAmount => double.tryParse(amountCtrl.text.trim()) ?? 0;
  double get paidAmount => double.tryParse(paidCtrl.text.trim()) ?? 0;
  double get balanceAmount => (totalAmount - paidAmount).clamp(0, double.infinity).toDouble();

  Future<void> save() async {
    final title = titleCtrl.text.trim();
    final amount = totalAmount;
    final paid = paidAmount;
    final balance = balanceAmount;

    if (title.isEmpty || amount <= 0) {
      _show('Please enter a valid title and amount.');
      return;
    }

    if (paid > amount) {
      _show('Paid amount cannot be greater than total amount.');
      return;
    }

    setState(() => saving = true);

    try {
      final body = {
        'title': title,
        'shopkeeperName': shopkeeperNameCtrl.text.trim(),
        'shopkeeperPhone': shopkeeperPhoneCtrl.text.trim(),
        'category': category,
        'amount': amount,
        'paidAmount': paid,
        'balanceAmount': balance,
        'paymentMode': paymentMode,
        'expenseDate': expenseDate.toIso8601String(),
        if (dueDate != null) 'dueDate': dueDate!.toIso8601String(),
        if (reminderDate != null) 'reminderDate': reminderDate!.toIso8601String(),
        'notes': notesCtrl.text.trim(),
      };

      if (isEditing) {
        await ApiService().put('/expenses/${widget.initialData!['_id']}', body);
      } else {
        await ApiService().post('/expenses', body);
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      _show(e.toString());
    } finally {
      if (mounted) {
        setState(() => saving = false);
      }
    }
  }

  Future<void> sendWhatsAppReminder() async {
    final name = shopkeeperNameCtrl.text.trim();
    final phone = shopkeeperPhoneCtrl.text.trim();
    if (name.isEmpty || phone.isEmpty) {
      _show('Enter shopkeeper name and mobile number first.');
      return;
    }

    final message = '''
Hello $name,

This is a payment reminder from Smart Expense Manager.

Item: ${titleCtrl.text.trim().isEmpty ? 'Expense' : titleCtrl.text.trim()}
Total: ${formatInr(totalAmount)}
Paid: ${formatInr(paidAmount)}
Balance: ${formatInr(balanceAmount)}

Please review and settle the pending balance.
''';

    final cleanedPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final uri = Uri.parse('https://wa.me/$cleanedPhone?text=${Uri.encodeComponent(message)}');
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      _show('Could not open WhatsApp.');
    }
  }

  Future<void> pickDate({
    required DateTime initialDate,
    required ValueChanged<DateTime> onPicked,
  }) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      onPicked(picked);
    }
  }

  void _show(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy');

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Expense' : 'Add Expense'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                colors: [Color(0xFF1F2A77), Color(0xFF5B6EF5)],
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
                  isEditing ? 'Update expense record' : 'Create a premium expense record',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Track bill amount, shopkeeper details, due dates, and reminder status in one place.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.84),
                      ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: _HeroMetric(
                        label: 'Total',
                        value: formatInr(totalAmount),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _HeroMetric(
                        label: 'Balance',
                        value: formatInr(balanceAmount),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _SectionCard(
            title: 'Expense Details',
            child: Column(
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    hintText: 'Ex: Grocery bill, monthly vegetables',
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: category,
                  items: AppConstants.categories
                      .map((item) => DropdownMenuItem<String>(value: item, child: Text(item)))
                      .toList(),
                  onChanged: (value) => setState(() => category = value!),
                  decoration: const InputDecoration(labelText: 'Category'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Amount'),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: paidCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Paid Amount'),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: paymentMode,
                  items: const ['Cash', 'UPI', 'Card', 'Bank Transfer']
                      .map((item) => DropdownMenuItem<String>(value: item, child: Text(item)))
                      .toList(),
                  onChanged: (value) => setState(() => paymentMode = value!),
                  decoration: const InputDecoration(labelText: 'Payment Mode'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Shopkeeper Details',
            trailing: TextButton.icon(
              onPressed: sendWhatsAppReminder,
              icon: const Icon(Icons.send_outlined),
              label: const Text('WhatsApp'),
            ),
            child: Column(
              children: [
                TextField(
                  controller: shopkeeperNameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Shopkeeper Name',
                    hintText: 'Ex: Zalim Bakery',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: shopkeeperPhoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Shopkeeper Mobile Number',
                    hintText: '91XXXXXXXXXX',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Dates & Reminder',
            child: Column(
              children: [
                _DateTile(
                  label: 'Expense Date',
                  value: dateFormat.format(expenseDate),
                  onTap: () => pickDate(
                    initialDate: expenseDate,
                    onPicked: (value) => setState(() => expenseDate = value),
                  ),
                ),
                _DateTile(
                  label: 'Due Date',
                  value: dueDate == null ? 'Optional' : dateFormat.format(dueDate!),
                  onTap: () => pickDate(
                    initialDate: dueDate ?? expenseDate,
                    onPicked: (value) => setState(() => dueDate = value),
                  ),
                  onClear: dueDate == null ? null : () => setState(() => dueDate = null),
                ),
                _DateTile(
                  label: 'Reminder Date',
                  value: reminderDate == null ? 'Optional' : dateFormat.format(reminderDate!),
                  onTap: () => pickDate(
                    initialDate: reminderDate ?? expenseDate,
                    onPicked: (value) => setState(() => reminderDate = value),
                  ),
                  onClear: reminderDate == null ? null : () => setState(() => reminderDate = null),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Notes',
            child: TextField(
              controller: notesCtrl,
              minLines: 3,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Notes',
                hintText: 'Add payment details, item breakup, or follow-up notes',
              ),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: saving ? null : save,
            child: Text(
              saving ? 'Saving...' : (isEditing ? 'Update Expense' : 'Save Expense'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
    this.trailing,
  });

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({
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
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _DateTile extends StatelessWidget {
  const _DateTile({
    required this.label,
    required this.value,
    required this.onTap,
    this.onClear,
  });

  final String label;
  final String value;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      subtitle: Text(value),
      leading: const Icon(Icons.calendar_month_outlined),
      trailing: onClear == null
          ? const Icon(Icons.chevron_right)
          : IconButton(
              onPressed: onClear,
              icon: const Icon(Icons.clear),
            ),
      onTap: onTap,
    );
  }
}
