class LoanModel {
  const LoanModel({
    required this.id,
    required this.loanName,
    required this.bankName,
    required this.totalLoanAmount,
    required this.emiAmount,
    required this.paidAmount,
    required this.remainingAmount,
    required this.interestRate,
    required this.startDate,
    required this.dueDate,
    required this.paymentStatus,
    required this.reminderDate,
  });

  final String id;
  final String loanName;
  final String bankName;
  final double totalLoanAmount;
  final double emiAmount;
  final double paidAmount;
  final double remainingAmount;
  final double interestRate;
  final DateTime? startDate;
  final DateTime? dueDate;
  final String paymentStatus;
  final DateTime? reminderDate;

  factory LoanModel.fromJson(Map<String, dynamic> json) => LoanModel(
        id: json['_id'] as String? ?? '',
        loanName: json['loanName'] as String? ?? '',
        bankName: json['bankName'] as String? ?? '',
        totalLoanAmount: (json['totalLoanAmount'] as num?)?.toDouble() ?? 0,
        emiAmount: (json['emiAmount'] as num?)?.toDouble() ?? 0,
        paidAmount: (json['paidAmount'] as num?)?.toDouble() ?? 0,
        remainingAmount: (json['remainingAmount'] as num?)?.toDouble() ?? 0,
        interestRate: (json['interestRate'] as num?)?.toDouble() ?? 0,
        startDate: DateTime.tryParse(json['startDate'] as String? ?? ''),
        dueDate: DateTime.tryParse(json['dueDate'] as String? ?? ''),
        paymentStatus: json['paymentStatus'] as String? ?? 'Pending',
        reminderDate: DateTime.tryParse(json['reminderDate'] as String? ?? ''),
      );

  Map<String, dynamic> toJsonWithId() => {
        '_id': id,
        'loanName': loanName,
        'bankName': bankName,
        'totalLoanAmount': totalLoanAmount,
        'emiAmount': emiAmount,
        'paidAmount': paidAmount,
        'remainingAmount': remainingAmount,
        'interestRate': interestRate,
        'startDate': startDate?.toIso8601String(),
        'dueDate': dueDate?.toIso8601String(),
        'paymentStatus': paymentStatus,
        'reminderDate': reminderDate?.toIso8601String(),
      };
}
