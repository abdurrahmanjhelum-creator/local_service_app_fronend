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

  Future<List<UserModel>> getProviders({
    String? category,
    double? minPrice,
    double? maxPrice,
    double? minRating,
    bool? isAvailable,
    bool? isVerified,
    String? sortBy,
    double? latitude,
    double? longitude,
    double? distanceKm,
  }) async {
    var url = ApiConstants.services;
    final queryParams = <String, String>{};
    
    if (category != null && category.isNotEmpty) {
      queryParams['category'] = category;
    }
    if (minPrice != null) {
      queryParams['minPrice'] = minPrice.toString();
    }
    if (maxPrice != null) {
      queryParams['maxPrice'] = maxPrice.toString();
    }
    if (minRating != null) {
      queryParams['minRating'] = minRating.toString();
    }
    if (isAvailable != null) {
      queryParams['isAvailable'] = isAvailable.toString();
    }
    if (isVerified != null) {
      queryParams['isVerified'] = isVerified.toString();
    }
    if (sortBy != null) {
      queryParams['sortBy'] = sortBy;
    }
    if (latitude != null) {
      queryParams['latitude'] = latitude.toString();
    }
    if (longitude != null) {
      queryParams['longitude'] = longitude.toString();
    }
    if (distanceKm != null) {
      queryParams['distance'] = distanceKm.toString();
    }

    if (queryParams.isNotEmpty) {
      url = '$url?${Uri(queryParameters: queryParams).query}';
    }

    final response = await _api.get(url);
    
    // Handle both list response and paginated response
    if (response is Map && response['providers'] is List) {
      return (response['providers'] as List)
          .map((item) => UserModel.fromJson(asMap(item)))
          .toList();
    }
    
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
