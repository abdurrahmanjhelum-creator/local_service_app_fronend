import '../models/category_model.dart';
import '../models/review_model.dart';
import '../models/user_model.dart';
import '../utils/api_constants.dart';
import '../utils/helpers.dart';
import 'api_service.dart';

class ServiceApi {
  final ApiService _api = ApiService();

  Future<List<CategoryModel>> getCategories() async {
    final response = await _api.get(ApiConstants.categories);
    if (response is! List) return [];
    return response.map((item) => CategoryModel.fromJson(asMap(item))).toList();
  }

  Future<List<String>> getCategoryNames() async {
    try {
      final list = await getCategories();
      if (list.isNotEmpty) {
        return list.map((item) => item.name).toList();
      }
    } catch (_) {}
    return defaultCategories;
  }

  Future<List<UserModel>> getProviders({String? category}) async {
    var url = ApiConstants.services;
    if (category != null && category.isNotEmpty) {
      url = '$url?category=${Uri.encodeQueryComponent(category)}';
    }

    final response = await _api.get(url);
    if (response is! List) return [];
    return response.map((item) => UserModel.fromJson(asMap(item))).toList();
  }

  Future<UserModel> getProvider(String id) async {
    final response = await _api.get('${ApiConstants.services}/$id');
    return UserModel.fromJson(asMap(response));
  }

  Future<List<ReviewModel>> getReviews(String providerId) async {
    final response = await _api.get('${ApiConstants.reviews}/provider/$providerId');
    if (response is! List) return [];
    return response.map((item) => ReviewModel.fromJson(asMap(item))).toList();
  }

  Future<dynamic> addReview({
    required String provider,
    required int rating,
    required String comment,
    required String bookingId, 
  }) async {
    final response = await _api.post(ApiConstants.reviews, {
      'provider': provider,
      'rating': rating,
      'comment': comment,
      'bookingId': bookingId,
    });
    return response;
  }
}
