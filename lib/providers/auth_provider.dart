import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/socket_service.dart';
import '../utils/helpers.dart';
import '../utils/token_manager.dart';

class AuthState {
  final UserModel? user;
  final bool isLoading;
  final bool isCheckingAuth;
  final String? errorMessage;

  AuthState({
    this.user,
    this.isLoading = false,
    this.isCheckingAuth = false,
    this.errorMessage,
  });
}

class AuthNotifier extends Notifier<AuthState> {
  final AuthService _authService = AuthService();

  @override
  AuthState build() {
    Future.microtask(checkAuthStatus);
    return AuthState(isCheckingAuth: true);
  }

  Future<void> _connectSocket(UserModel user) async {
    try {
      final socketService = SocketService();
      await socketService.connect();
      socketService.joinRoom(user.id);
    } catch (_) {}
  }

  Future<void> checkAuthStatus() async {
    final token = await TokenManager.getToken();
    if (token == null || token.isEmpty) {
      state = AuthState();
      return;
    }

    try {
      final user = await _authService.getProfile();
      state = AuthState(user: user);
      _connectSocket(user);
    } catch (_) {
      await TokenManager.clearToken();
      state = AuthState();
    }
  }

  Future<bool> login(String email, String password) async {
    state = AuthState(isLoading: true);
    try {
      final user = await _authService.login(email: email, password: password);
      state = AuthState(user: user);
      _connectSocket(user);
      return true;
    } catch (e) {
      state = AuthState(errorMessage: cleanError(e));
      return false;
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String role,
    dynamic imageFile,
    String? category,
    double? priceStarting,
    int? experienceYears,
  }) async {
    state = AuthState(isLoading: true);
    try {
      final user = await _authService.register(
        name: name,
        email: email,
        password: password,
        phone: phone,
        role: role,
        imageFile: imageFile,
        category: category,
        priceStarting: priceStarting,
        experienceYears: experienceYears,
      );
      state = AuthState(user: user);
      _connectSocket(user);
      return true;
    } catch (e) {
      state = AuthState(errorMessage: cleanError(e));
      return false;
    }
  }

  Future<bool> updateProfile({
    String? name,
    String? phone,
    String? category,
    double? priceStarting,
    int? experienceYears,
    bool? isAvailable,
    dynamic imageFile,
  }) async {
    state = AuthState(user: state.user, isLoading: true);
    try {
      final user = await _authService.updateProfile(
        name: name,
        phone: phone,
        category: category,
        priceStarting: priceStarting,
        experienceYears: experienceYears,
        isAvailable: isAvailable,
        imageFile: imageFile,
      );
      state = AuthState(user: user);
      _connectSocket(user);
      return true;
    } catch (e) {
      state = AuthState(user: state.user, errorMessage: cleanError(e));
      return false;
    }
  }

  Future<bool> deleteAccount() async {
    try {
      SocketService().disconnect();
      await _authService.deleteAccount();
      state = AuthState();
      return true;
    } catch (e) {
      state = AuthState(user: state.user, errorMessage: cleanError(e));
      return false;
    }
  }

  Future<void> logout() async {
    SocketService().disconnect();
    await _authService.logout();
    state = AuthState();
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
