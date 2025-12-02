import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';

class AuthService {
  AuthService({required AppConfig config, SupabaseClient? supabaseClient})
      : _supabase = supabaseClient ?? Supabase.instance.client,
        _emailRedirectUrl = config.emailRedirectUrl;

  final SupabaseClient _supabase;
  final String _emailRedirectUrl;

  Future<void> signUp({
    required String email,
    required String password,
  }) async {
    await _supabase.auth.signUp(
      email: email,
      password: password,
      emailRedirectTo: _emailRedirectUrl,
    );
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  Future<void> sendPasswordReset({
    required String email,
    String? redirectTo,
  }) async {
    await _supabase.auth.resetPasswordForEmail(
      email,
      redirectTo: redirectTo ?? _emailRedirectUrl,
    );
  }

  User? getCurrentUser() {
    return _supabase.auth.currentUser;
  }

  Stream<AuthState> authStateChanges() {
    return _supabase.auth.onAuthStateChange;
  }
}
