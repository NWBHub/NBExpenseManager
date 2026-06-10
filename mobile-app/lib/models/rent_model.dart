class RentModel {
  const RentModel({
    required this.id,
    required this.propertyName,
    required this.propertyType,
    required this.tenantName,
    required this.tenantPhone,
    required this.monthlyRent,
    required this.paidAmount,
    required this.balanceAmount,
    required this.paymentStatus,
    required this.rentMonth,
    required this.dueDate,
    required this.reminderDate,
    required this.notes,
  });

  final String id;
  final String propertyName;
  final String propertyType;
  final String tenantName;
  final String tenantPhone;
  final double monthlyRent;
  final double paidAmount;
  final double balanceAmount;
  final String paymentStatus;
  final DateTime? rentMonth;
  final DateTime? dueDate;
  final DateTime? reminderDate;
  final String notes;

  factory RentModel.fromJson(Map<String, dynamic> json) => RentModel(
        id: json['_id'] as String? ?? '',
        propertyName: json['propertyName'] as String? ?? '',
        propertyType: json['propertyType'] as String? ?? 'Shop',
        tenantName: json['tenantName'] as String? ?? '',
        tenantPhone: json['tenantPhone'] as String? ?? '',
        monthlyRent: (json['monthlyRent'] as num?)?.toDouble() ?? 0,
        paidAmount: (json['paidAmount'] as num?)?.toDouble() ?? 0,
        balanceAmount: (json['balanceAmount'] as num?)?.toDouble() ?? 0,
        paymentStatus: json['paymentStatus'] as String? ?? 'Pending',
        rentMonth: DateTime.tryParse(json['rentMonth'] as String? ?? ''),
        dueDate: DateTime.tryParse(json['dueDate'] as String? ?? ''),
        reminderDate: DateTime.tryParse(json['reminderDate'] as String? ?? ''),
        notes: json['notes'] as String? ?? '',
      );

  Map<String, dynamic> toJsonWithId() => {
        '_id': id,
        'propertyName': propertyName,
        'propertyType': propertyType,
        'tenantName': tenantName,
        'tenantPhone': tenantPhone,
        'monthlyRent': monthlyRent,
        'paidAmount': paidAmount,
        'balanceAmount': balanceAmount,
        'paymentStatus': paymentStatus,
        'rentMonth': rentMonth?.toIso8601String(),
        'dueDate': dueDate?.toIso8601String(),
        'reminderDate': reminderDate?.toIso8601String(),
        'notes': notes,
      };
}
