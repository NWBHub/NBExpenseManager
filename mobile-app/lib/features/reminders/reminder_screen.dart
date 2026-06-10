import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/utils/currency_formatter.dart';
import '../../models/reminder_model.dart';
import '../../services/api_service.dart';
import '../../shared/widgets/app_sidebar_drawer.dart';

class ReminderScreen extends StatefulWidget {
  const ReminderScreen({super.key});

  @override
  State<ReminderScreen> createState() => _ReminderScreenState();
}

class _ReminderScreenState extends State<ReminderScreen> {
  List<ReminderModel> reminders = [];
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final res = await ApiService().get('/reminders');
      final list = (res['data'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(ReminderModel.fromJson)
          .toList();

      if (!mounted) return;
      setState(() => reminders = list);
    } catch (e) {
      if (!mounted) return;
      setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> openEditor({ReminderModel? reminder}) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ReminderEditorScreen(initialData: reminder?.toJsonWithId()),
      ),
    );

    if (changed == true) {
      await load();
    }
  }

  Future<void> deleteReminder(ReminderModel reminder) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete reminder?'),
        content: Text('This will remove "${reminder.title}".'),
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

    if (confirmed != true) return;

    try {
      await ApiService().delete('/reminders/${reminder.id}');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reminder deleted')),
      );
      await load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> toggleReminder(ReminderModel reminder) async {
    try {
      await ApiService().put('/reminders/${reminder.id}', {
        'title': reminder.title,
        'type': reminder.type,
        'amount': reminder.amount,
        'isCompleted': !reminder.isCompleted,
        'notes': reminder.notes,
        if (reminder.dueDate != null) 'dueDate': reminder.dueDate!.toIso8601String(),
        if (reminder.reminderDate != null)
          'reminderDate': reminder.reminderDate!.toIso8601String(),
      });
      await load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppSidebarDrawer(),
      appBar: AppBar(
        title: const Text('Reminders'),
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
        heroTag: 'reminders_add_fab',
        onPressed: () => openEditor(),
        icon: const Icon(Icons.add_alert_outlined),
        label: const Text('Add Reminder'),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? _ErrorState(message: error!, onRetry: load)
              : RefreshIndicator(
                  onRefresh: load,
                  child: reminders.isEmpty
                      ? const _EmptyState(
                          title: 'No reminders yet',
                          subtitle: 'Create reminders for bill due dates, loan payments, and follow-ups.',
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: reminders.length,
                          itemBuilder: (_, index) {
                            final reminder = reminders[index];
                            final dueDate = reminder.dueDate == null
                                ? 'No due date'
                                : DateFormat('dd MMM yyyy').format(reminder.dueDate!);

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: CheckboxListTile(
                                value: reminder.isCompleted,
                                onChanged: (_) => toggleReminder(reminder),
                                controlAffinity: ListTileControlAffinity.leading,
                                title: Text(reminder.title),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text('${reminder.type} - Due $dueDate'),
                                    if (reminder.amount > 0)
                                      Text('Amount ${formatInr(reminder.amount)}'),
                                    if (reminder.notes.isNotEmpty) Text(reminder.notes),
                                  ],
                                ),
                                secondary: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      onPressed: () => openEditor(reminder: reminder),
                                      icon: const Icon(Icons.edit_outlined),
                                    ),
                                    IconButton(
                                      onPressed: () => deleteReminder(reminder),
                                      icon: const Icon(Icons.delete_outline),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
    );
  }
}

class ReminderEditorScreen extends StatefulWidget {
  const ReminderEditorScreen({super.key, this.initialData});

  final Map<String, dynamic>? initialData;

  @override
  State<ReminderEditorScreen> createState() => _ReminderEditorScreenState();
}

class _ReminderEditorScreenState extends State<ReminderEditorScreen> {
  final titleCtrl = TextEditingController();
  final amountCtrl = TextEditingController();
  final notesCtrl = TextEditingController();

  String type = 'Bill';
  DateTime? dueDate;
  DateTime? reminderDate;
  bool isCompleted = false;
  bool saving = false;

  bool get isEditing => widget.initialData?['_id'] != null;

  @override
  void initState() {
    super.initState();
    final data = widget.initialData;
    if (data != null) {
      titleCtrl.text = '${data['title'] ?? ''}';
      amountCtrl.text = '${data['amount'] ?? 0}';
      notesCtrl.text = '${data['notes'] ?? ''}';
      type = '${data['type'] ?? type}';
      isCompleted = data['isCompleted'] as bool? ?? false;
      dueDate = data['dueDate'] == null ? null : DateTime.tryParse('${data['dueDate']}');
      reminderDate =
          data['reminderDate'] == null ? null : DateTime.tryParse('${data['reminderDate']}');
    }
  }

  @override
  void dispose() {
    titleCtrl.dispose();
    amountCtrl.dispose();
    notesCtrl.dispose();
    super.dispose();
  }

  Future<void> save() async {
    final title = titleCtrl.text.trim();
    final amount = double.tryParse(amountCtrl.text.trim()) ?? 0;

    if (title.isEmpty) {
      _show('Enter a reminder title.');
      return;
    }

    setState(() => saving = true);

    try {
      final body = {
        'title': title,
        'type': type,
        'amount': amount,
        'isCompleted': isCompleted,
        'notes': notesCtrl.text.trim(),
        if (dueDate != null) 'dueDate': dueDate!.toIso8601String(),
        if (reminderDate != null) 'reminderDate': reminderDate!.toIso8601String(),
      };

      if (isEditing) {
        await ApiService().put('/reminders/${widget.initialData!['_id']}', body);
      } else {
        await ApiService().post('/reminders', body);
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      _show(e.toString());
    } finally {
      if (mounted) setState(() => saving = false);
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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy');

    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Edit Reminder' : 'Add Reminder')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: titleCtrl,
            decoration: const InputDecoration(labelText: 'Title'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: type,
            items: const [
              DropdownMenuItem(value: 'Bill', child: Text('Bill')),
              DropdownMenuItem(value: 'Loan', child: Text('Loan')),
              DropdownMenuItem(value: 'Credit Card', child: Text('Credit Card')),
              DropdownMenuItem(value: 'Debt', child: Text('Debt')),
              DropdownMenuItem(value: 'Other', child: Text('Other')),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() => type = value);
              }
            },
            decoration: const InputDecoration(labelText: 'Type'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: amountCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Amount'),
          ),
          const SizedBox(height: 12),
          _DateTile(
            label: 'Due Date',
            value: dueDate == null ? 'Optional' : dateFormat.format(dueDate!),
            onTap: () => pickDate(
              initialDate: dueDate ?? DateTime.now(),
              onPicked: (value) => setState(() => dueDate = value),
            ),
            onClear: dueDate == null ? null : () => setState(() => dueDate = null),
          ),
          _DateTile(
            label: 'Reminder Date',
            value: reminderDate == null ? 'Optional' : dateFormat.format(reminderDate!),
            onTap: () => pickDate(
              initialDate: reminderDate ?? DateTime.now(),
              onPicked: (value) => setState(() => reminderDate = value),
            ),
            onClear: reminderDate == null ? null : () => setState(() => reminderDate = null),
          ),
          CheckboxListTile(
            value: isCompleted,
            onChanged: (value) => setState(() => isCompleted = value ?? false),
            contentPadding: EdgeInsets.zero,
            title: const Text('Mark as completed'),
          ),
          TextField(
            controller: notesCtrl,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(labelText: 'Notes'),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: saving ? null : save,
            child: Text(saving ? 'Saving...' : (isEditing ? 'Update Reminder' : 'Save Reminder')),
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
      leading: const Icon(Icons.calendar_month_outlined),
      title: Text(label),
      subtitle: Text(value),
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

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const SizedBox(height: 120),
        Icon(Icons.notifications_off_outlined, size: 56, color: Theme.of(context).colorScheme.outline),
        const SizedBox(height: 16),
        Center(child: Text(title, style: Theme.of(context).textTheme.titleMedium)),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(subtitle, textAlign: TextAlign.center),
        ),
      ],
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
