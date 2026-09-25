import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../utils/token_manager.dart';

/// Optimized ApiService layer with persistent connection pooling for high performance.
class ApiService {
  static const _timeout = Duration(seconds: 20);
  final http.Client _client = http.Client();

  Future<Map<String, String>> _headers({bool json = true}) async {
    final token = await TokenManager.getToken();
    final headers = <String, String>{};
    if (json) headers['Content-Type'] = 'application/json';
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Never _connectionError(Object error) {
    final text = error.toString().toLowerCase();
    if (text.contains('socket') ||
        text.contains('connection') ||
        text.contains('timed out') ||
        text.contains('timeout') ||
        text.contains('failed host lookup')) {
      throw Exception('Cannot connect to server. Start the backend on port 5000.');
    }
    throw Exception(error.toString().replaceAll('Exception: ', ''));
  }

  dynamic _read(http.Response response) {
    if (response.body.isEmpty) {
      if (response.statusCode >= 200 && response.statusCode < 300) return <String, dynamic>{};
      throw Exception('Server Error (${response.statusCode})');
    }

    dynamic data;
    try {
      data = jsonDecode(response.body);
    } catch (_) {
      throw Exception('Cannot connect to server. Invalid response format.');
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      // Ensure we never return null for successful responses
      return data ?? <String, dynamic>{};
    }

    final message = data is Map ? data['message'] : null;
    throw Exception(message ?? 'Server Error (${response.statusCode})');
  }

  Future<http.Response> _send(Future<http.Response> request) async {
    try {
      return await request.timeout(_timeout);
    } catch (e) {
      _connectionError(e);
    }
  }

  Future<dynamic> get(String url) async {
    final response = await _send(_client.get(Uri.parse(url), headers: await _headers()));
    return _read(response);
  }

  Future<dynamic> post(String url, Map<String, dynamic> body) async {
    final response = await _send(_client.post(Uri.parse(url), headers: await _headers(), body: jsonEncode(body)));
    return _read(response);
  }

  Future<dynamic> put(String url, Map<String, dynamic> body) async {
    final response = await _send(_client.put(Uri.parse(url), headers: await _headers(), body: jsonEncode(body)));
    return _read(response);
  }

  Future<dynamic> delete(String url) async {
    final response = await _send(_client.delete(Uri.parse(url), headers: await _headers()));
    return _read(response);
  }

  Future<dynamic> sendForm({
    required String url,
    required String method,
    required Map<String, String> fields,
    dynamic image,
  }) async {
    try {
      final request = http.MultipartRequest(method, Uri.parse(url));
      final token = await TokenManager.getToken();
      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      request.fields.addAll(fields);
      if (image != null) {
        if (kIsWeb) {
          final ext = image.name.split('.').last.toLowerCase();
          String type = 'image/jpeg';
          if (ext == 'png') type = 'image/png';
          if (ext == 'webp') type = 'image/webp';
          if (ext == 'gif') type = 'image/gif';

          request.files.add(http.MultipartFile.fromBytes(
            'image',
            await image.readAsBytes(),
            filename: image.name,
            contentType: MediaType.parse(type),
          ));
        } else {
          request.files.add(await http.MultipartFile.fromPath('image', image.path));
        }
      }
      final streamed = await _client.send(request).timeout(_timeout);
      final response = await http.Response.fromStream(streamed);
      return _read(response);
    } catch (e) {
      if (e.toString().contains('Server Error') || e.toString().contains('Exception:')) rethrow;
      _connectionError(e);
    }
  }
}

/// Ensures that any dynamic value is safely returned as a map.
/// This prevents "Null is not a subtype of Map" crashes on Flutter Web.
Map<String, dynamic> asMap(dynamic value) {
  if (value == null) return <String, dynamic>{};
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return <String, dynamic>{};
}
