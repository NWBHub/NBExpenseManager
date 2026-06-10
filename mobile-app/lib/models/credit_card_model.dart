class CreditCardModel {
  const CreditCardModel({
    required this.id,
    required this.recordType,
    required this.cardName,
    required this.bankName,
    required this.creditLimit,
    required this.billAmount,
    required this.minimumDue,
    required this.paidAmount,
    required this.balanceAmount,
    required this.paymentStatus,
    required this.totalInstallments,
    required this.paidInstallments,
    required this.installmentAmount,
    required this.startDate,
    required this.completionDate,
    required this.notes,
    required this.dueDate,
    required this.reminderDate,
  });

  final String id;
  final String recordType;
  final String cardName;
  final String bankName;
  final double creditLimit;
  final double billAmount;
  final double minimumDue;
  final double paidAmount;
  final double balanceAmount;
  final String paymentStatus;
  final int totalInstallments;
  final int paidInstallments;
  final double installmentAmount;
  final DateTime? startDate;
  final DateTime? completionDate;
  final String notes;
  final DateTime? dueDate;
  final DateTime? reminderDate;

  int get remainingInstallments =>
      ((totalInstallments - paidInstallments).clamp(0, totalInstallments) as num).toInt();

  factory CreditCardModel.fromJson(Map<String, dynamic> json) => CreditCardModel(
        id: json['_id'] as String? ?? '',
        recordType: json['recordType'] as String? ?? 'Credit Card',
        cardName: json['cardName'] as String? ?? '',
        bankName: json['bankName'] as String? ?? '',
        creditLimit: (json['creditLimit'] as num?)?.toDouble() ?? 0,
        billAmount: (json['billAmount'] as num?)?.toDouble() ?? 0,
        minimumDue: (json['minimumDue'] as num?)?.toDouble() ?? 0,
        paidAmount: (json['paidAmount'] as num?)?.toDouble() ?? 0,
        balanceAmount: (json['balanceAmount'] as num?)?.toDouble() ?? 0,
        paymentStatus: json['paymentStatus'] as String? ?? 'Pending',
        totalInstallments: (json['totalInstallments'] as num?)?.toInt() ?? 0,
        paidInstallments: (json['paidInstallments'] as num?)?.toInt() ?? 0,
        installmentAmount: (json['installmentAmount'] as num?)?.toDouble() ?? 0,
        startDate: DateTime.tryParse(json['startDate'] as String? ?? ''),
        completionDate: DateTime.tryParse(json['completionDate'] as String? ?? ''),
        notes: json['notes'] as String? ?? '',
        dueDate: DateTime.tryParse(json['dueDate'] as String? ?? ''),
        reminderDate: DateTime.tryParse(json['reminderDate'] as String? ?? ''),
      );

  Map<String, dynamic> toJsonWithId() => {
        '_id': id,
        'recordType': recordType,
        'cardName': cardName,
        'bankName': bankName,
        'creditLimit': creditLimit,
        'billAmount': billAmount,
        'minimumDue': minimumDue,
        'paidAmount': paidAmount,
        'balanceAmount': balanceAmount,
        'paymentStatus': paymentStatus,
        'totalInstallments': totalInstallments,
        'paidInstallments': paidInstallments,
        'installmentAmount': installmentAmount,
        'startDate': startDate?.toIso8601String(),
        'completionDate': completionDate?.toIso8601String(),
        'notes': notes,
        'dueDate': dueDate?.toIso8601String(),
        'reminderDate': reminderDate?.toIso8601String(),
      };
}
