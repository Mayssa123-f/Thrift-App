import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../utils/token_storage.dart';
import '../services/google_auth_service.dart';

class AuthController {
  final AuthService _authService = AuthService();

  final GoogleAuthService _googleAuthService = GoogleAuthService();

  Future<UserModel> continueWithGoogle() async {
    final idToken = await _googleAuthService.getGoogleIdToken();

    if (idToken == null) {
      throw Exception("Google sign-in cancelled");
    }

    return await _authService.loginWithGoogle(idToken);
  }

  Future<UserModel> login(String email, String password) async {
    if (email.trim().isEmpty || password.isEmpty) {
      throw Exception('Email and password are required');
    }

    return await _authService.login(email: email, password: password);
  }

  Future<UserModel> register(
    String fullName,
    String email,
    String password,
  ) async {
    if (fullName.trim().isEmpty || email.trim().isEmpty || password.isEmpty) {
      throw Exception('All fields are required');
    }

    if (password.length < 6) {
      throw Exception('Password must be at least 6 characters');
    }

    return await _authService.register(
      fullName: fullName,
      email: email,
      password: password,
    );
  }

  Future<UserModel> getProfile() async {
    return await _authService.getProfile();
  }

  Future<UserModel> updateProfile({
    required String fullName,
    String? bio,
    String? location,
    String? profileImageUrl,
  }) async {
    if (fullName.trim().isEmpty) {
      throw Exception('Full name is required');
    }

    return await _authService.updateProfile(
      fullName: fullName,
      bio: bio,
      location: location,
      profileImageUrl: profileImageUrl,
    );
  }

  Future<void> logout() async {
  await _authService.logout();
}
  Future<void> forgotPassword(String email) async {
    if (email.trim().isEmpty) {
      throw Exception('Email is required');
    }

    await _authService.forgotPassword(email);
  }

  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    if (email.trim().isEmpty || code.trim().isEmpty || newPassword.isEmpty) {
      throw Exception('All fields are required');
    }

    if (newPassword.length < 6) {
      throw Exception('Password must be at least 6 characters');
    }

    await _authService.resetPassword(
      email: email,
      code: code,
      newPassword: newPassword,
    );
  }
}
