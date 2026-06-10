class ReminderModel {
  const ReminderModel({
    required this.id,
    required this.title,
    required this.type,
    required this.amount,
    required this.dueDate,
    required this.reminderDate,
    required this.isCompleted,
    required this.notes,
  });

  final String id;
  final String title;
  final String type;
  final double amount;
  final DateTime? dueDate;
  final DateTime? reminderDate;
  final bool isCompleted;
  final String notes;

  factory ReminderModel.fromJson(Map<String, dynamic> json) => ReminderModel(
        id: json['_id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        type: json['type'] as String? ?? 'Reminder',
        amount: (json['amount'] as num?)?.toDouble() ?? 0,
        dueDate: DateTime.tryParse(json['dueDate'] as String? ?? ''),
        reminderDate: DateTime.tryParse(json['reminderDate'] as String? ?? ''),
        isCompleted: json['isCompleted'] as bool? ?? false,
        notes: json['notes'] as String? ?? '',
      );

  Map<String, dynamic> toJsonWithId() => {
        '_id': id,
        'title': title,
        'type': type,
        'amount': amount,
        'dueDate': dueDate?.toIso8601String(),
        'reminderDate': reminderDate?.toIso8601String(),
        'isCompleted': isCompleted,
        'notes': notes,
      };
}
