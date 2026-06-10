class ExpenseModel {
  final String? id;
  final String title;
  final String? shopkeeperName;
  final String? shopkeeperPhone;
  final String category;
  final double amount;
  final double paidAmount;
  final double balanceAmount;
  final String paymentStatus;
  final String paymentMode;
  final DateTime expenseDate;
  final DateTime? dueDate;
  final DateTime? reminderDate;
  final String? notes;

  ExpenseModel({
    this.id,
    required this.title,
    this.shopkeeperName,
    this.shopkeeperPhone,
    required this.category,
    required this.amount,
    required this.paidAmount,
    required this.balanceAmount,
    required this.paymentStatus,
    required this.paymentMode,
    required this.expenseDate,
    this.dueDate,
    this.reminderDate,
    this.notes,
  });

  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    return ExpenseModel(
      id: json['_id'],
      title: json['title'] ?? '',
      shopkeeperName: json['shopkeeperName'],
      shopkeeperPhone: json['shopkeeperPhone'],
      category: json['category'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      paidAmount: (json['paidAmount'] ?? 0).toDouble(),
      balanceAmount: (json['balanceAmount'] ?? 0).toDouble(),
      paymentStatus: json['paymentStatus'] ?? 'Pending',
      paymentMode: json['paymentMode'] ?? 'Cash',
      expenseDate: DateTime.tryParse('${json['expenseDate'] ?? ''}') ?? DateTime.now(),
      dueDate: json['dueDate'] == null ? null : DateTime.tryParse('${json['dueDate']}'),
      reminderDate: json['reminderDate'] == null ? null : DateTime.tryParse('${json['reminderDate']}'),
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'shopkeeperName': shopkeeperName,
      'shopkeeperPhone': shopkeeperPhone,
      'category': category,
      'amount': amount,
      'paidAmount': paidAmount,
      'balanceAmount': balanceAmount,
      'paymentStatus': paymentStatus,
      'paymentMode': paymentMode,
      'expenseDate': expenseDate.toIso8601String(),
      'dueDate': dueDate?.toIso8601String(),
      'reminderDate': reminderDate?.toIso8601String(),
      'notes': notes,
    };
  }

  Map<String, dynamic> toJsonWithId() {
    return {
      '_id': id,
      ...toJson(),
    };
  }
}
