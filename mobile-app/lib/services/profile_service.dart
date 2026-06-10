import '../models/user_model.dart';
import 'api_service.dart';
import 'auth_service.dart';

class ProfileService {
  const ProfileService();

  Future<UserModel> syncUser({
    String? firstName,
    String? lastName,
    String? phone,
    String? photoUrl,
    String? currency,
  }) async {
    final response = await ApiService().post('/auth/sync-user', {
      if (firstName != null) 'firstName': firstName,
      if (lastName != null) 'lastName': lastName,
      if (phone != null) 'phone': phone,
      if (photoUrl != null) 'photoUrl': photoUrl,
      if (currency != null) 'currency': currency,
    });

    return UserModel.fromJson((response['data'] as Map<String, dynamic>?) ?? {});
  }

  Future<UserModel> getProfile() async {
    final response = await ApiService().get('/auth/me');
    return UserModel.fromJson((response['data'] as Map<String, dynamic>?) ?? {});
  }

  Future<UserModel> updateProfile({
    required String firstName,
    required String lastName,
    required String phone,
    required String photoUrl,
    required String currency,
  }) async {
    final response = await ApiService().put('/auth/me', {
      'firstName': firstName,
      'lastName': lastName,
      'phone': phone,
      'photoUrl': photoUrl,
      'currency': currency,
    });

    return UserModel.fromJson((response['data'] as Map<String, dynamic>?) ?? {});
  }

  Future<void> deleteAccount() async {
    await ApiService().delete('/auth/me');
    await AuthService.instance.logout();
  }
}
