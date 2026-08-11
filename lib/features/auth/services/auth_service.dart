import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/notifications/notification_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Auth state listener
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  User? get currentUser => _supabase.auth.currentUser;

  Session? get currentSession => _supabase.auth.currentSession;

  // Sign Up
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
    required String username,
  }) async {
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {
        'full_name': fullName,
        'username': username,
      },
    );
    if (response.user != null) {
      _registerFCMToken();
    }
    return response;
  }

  // Verify OTP
  Future<AuthResponse> verifyOtp({
    required String email,
    required String token,
    required OtpType type,
  }) async {
    final response = await _supabase.auth.verifyOTP(
      email: email,
      token: token,
      type: type,
    );
    if (response.session != null) {
      _registerFCMToken();
    }
    return response;
  }

  // Resend OTP
  Future<void> resendOtp({
    required String email,
    required OtpType type,
  }) async {
    await _supabase.auth.resend(
      email: email,
      type: type,
    );
  }

  // Sign In
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
    if (response.session != null) {
      _registerFCMToken();
    }
    return response;
  }

  // Sign Out
  Future<void> signOut() async {
    await NotificationService().removeToken();
    await _supabase.auth.signOut();
  }

  Future<void> _registerFCMToken() async {
    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      // NotificationService handles the Supabase persistence
      // We trigger it here to ensure it's saved after login
      NotificationService().initialize(); 
    }
  }

  // Reset Password
  Future<void> sendPasswordReset(String email) async {
    await _supabase.auth.resetPasswordForEmail(email);
  }

  // Update Password
  Future<UserResponse> updatePassword(String newPassword) async {
    return await _supabase.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }
}
