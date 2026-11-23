
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepositoryImpl {
  final SupabaseClient _supabase =
      Supabase.instance.client;

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    await _supabase.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  User? get currentUser =>
      _supabase.auth.currentUser;
}
 