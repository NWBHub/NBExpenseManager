class UserModel {
  const UserModel({
    required this.userId,
    this.firstName,
    this.lastName,
    this.name,
    this.email,
    this.phone,
    this.photoUrl,
    this.currency = 'INR',
  });

  final String userId;
  final String? firstName;
  final String? lastName;
  final String? name;
  final String? email;
  final String? phone;
  final String? photoUrl;
  final String currency;

  String get displayName {
    final fullName = [firstName, lastName].where((part) => (part ?? '').trim().isNotEmpty).join(' ').trim();
    if (fullName.isNotEmpty) return fullName;
    if ((name ?? '').trim().isNotEmpty) return name!.trim();
    if ((email ?? '').trim().isNotEmpty) return email!.trim();
    return 'User';
  }

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        userId: json['userId'] as String? ?? '',
        firstName: json['firstName'] as String?,
        lastName: json['lastName'] as String?,
        name: json['name'] as String?,
        email: json['email'] as String?,
        phone: json['phone'] as String?,
        photoUrl: json['photoUrl'] as String?,
        currency: json['currency'] as String? ?? 'INR',
      );

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'firstName': firstName,
        'lastName': lastName,
        'name': name,
        'email': email,
        'phone': phone,
        'photoUrl': photoUrl,
        'currency': currency,
      };
}
