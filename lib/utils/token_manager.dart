import 'package:shared_preferences/shared_preferences.dart';

class TokenManager {
  // Key identifier for storing the token string in shared preferences storage
  static const String _keyToken = 'auth_token';

  // Fast in-memory token cache to prevent frequent and slow disk read/write cycles
  static String? _inMemoryToken;

  // Token Save karne ke liye (Saves token to both memory cache and disk)
  static Future<void> saveToken(String token) async {
    // Set token in fast memory storage instantly
    _inMemoryToken = token;
    // Open shared preferences database instance
    final prefs = await SharedPreferences.getInstance();
    // Persist the token to physical disk storage safely
    await prefs.setString(_keyToken, token);
  }

  // Saved Token Read karne ke liye (Reads from memory if available, else from disk)
  static Future<String?> getToken() async {
    // If token exists in memory cache, return it instantly to save processor time
    if (_inMemoryToken != null) return _inMemoryToken;
    // Open shared preferences database instance
    final prefs = await SharedPreferences.getInstance();
    // Retrieve stored token from physical disk storage
    _inMemoryToken = prefs.getString(_keyToken);
    // Return the fetched token or null if it does not exist
    return _inMemoryToken;
  }

  // Logout ke waqt Token Delete karne ke liye (Wipes token from memory and disk)
  static Future<void> clearToken() async {
    // Reset in-memory cache reference immediately to null
    _inMemoryToken = null;
    // Open shared preferences database instance
    final prefs = await SharedPreferences.getInstance();
    // Delete the token entry from physical disk storage
    await prefs.remove(_keyToken);
  }
}