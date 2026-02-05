import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/user_model.dart';

class AuthService {
  final _supabase = Supabase.instance.client;

  User? get currentUser => _supabase.auth.currentUser;
  
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String username,
  }) async {
    final response = await _supabase.auth.signUp(
      email: email.trim().toLowerCase(),
      password: password,
      data: {'name': username.trim()},
    );

    if (response.user != null) {
      await _supabase.from('users').insert({
        'auth_id': response.user!.id,
        'email': email.trim().toLowerCase(),
        'name': username.trim(),
        'points': 0,
        'predictions': 0,
        'correct': 0,
        'monthly_points': 0,
        'monthly_predictions': 0,
        'monthly_correct': 0,
        'current_streak': 0,
        'best_streak': 0,
        'level': 1,
        'monthly_championships': 0,
      });
    }

    return response;
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _supabase.auth.signInWithPassword(
      email: email.trim().toLowerCase(),
      password: password,
    );
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  Future<UserModel?> getUserProfile(String authId) async {
    try {
      final response = await _supabase
          .from('users')
          .select()
          .eq('auth_id', authId)
          .single();
      
      return UserModel.fromJson(response);
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }

  Future<void> resetPassword(String email) async {
    await _supabase.auth.resetPasswordForEmail(email);
  }
}