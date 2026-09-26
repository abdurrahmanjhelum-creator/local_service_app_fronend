import '../models/user_model.dart';
import '../utils/api_constants.dart';
import '../utils/token_manager.dart';
import 'api_service.dart';

class AuthService {
  final ApiService _api = ApiService();

  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String role,
    dynamic imageFile,
    String? category,
    double? priceStarting,
    int? experienceYears,
    String? address,
    double? latitude,
    double? longitude,
  }) async {
    final fields = <String, String>{
      'name': name,
      'email': email,
      'password': password,
      'phone': phone,
      'role': role,
      'category': category ?? '',
    };
    if (priceStarting != null) fields['priceStarting'] = priceStarting.toString();
    if (experienceYears != null) fields['experienceYears'] = experienceYears.toString();
    if (address != null) fields['address'] = address;
    if (latitude != null) fields['latitude'] = latitude.toString();
    if (longitude != null) fields['longitude'] = longitude.toString();

    final response = await _api.sendForm(
      url: ApiConstants.register,
      method: 'POST',
      fields: fields,
      image: imageFile,
    );

    final user = UserModel.fromJson(asMap(response));
    if (user.token != null) {
      await TokenManager.saveToken(user.token!);
    }
    return user;
  }

  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final response = await _api.post(ApiConstants.login, {
      'email': email,
      'password': password,
    });

    final user = UserModel.fromJson(asMap(response));
    if (user.token != null) {
      await TokenManager.saveToken(user.token!);
    }
    return user;
  }

  Future<UserModel> getProfile() async {
    final response = await _api.get(ApiConstants.profile);
    return UserModel.fromJson(asMap(response));
  }

  Future<UserModel> updateProfile({
    String? name,
    String? phone,
    String? category,
    double? priceStarting,
    int? experienceYears,
    bool? isAvailable,
    dynamic imageFile,
  }) async {
    final fields = <String, String>{};
    if (name != null) fields['name'] = name;
    if (phone != null) fields['phone'] = phone;
    if (category != null) fields['category'] = category;
    if (priceStarting != null) fields['priceStarting'] = priceStarting.toString();
    if (experienceYears != null) {
      fields['experienceYears'] = experienceYears.toString();
    }
    if (isAvailable != null) fields['isAvailable'] = isAvailable.toString();

    final response = await _api.sendForm(
      url: ApiConstants.profile,
      method: 'PUT',
      fields: fields,
      image: imageFile,
    );
    return UserModel.fromJson(asMap(response));
  }

  Future<void> deleteAccount() async {
    await _api.delete(ApiConstants.profile);
    await TokenManager.clearToken();
  }

  Future<void> logout() async {
    await TokenManager.clearToken();
  }
}
