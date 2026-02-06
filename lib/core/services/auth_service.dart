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
    try {
      print('📝 Iniciando registro para: $email');
      
      final response = await _supabase.auth.signUp(
        email: email.trim().toLowerCase(),
        password: password,
        data: {'name': username.trim()},
      );

      if (response.user != null) {
        print('✅ Usuario creado en auth.users: ${response.user!.id}');
        
        // Crear perfil en la tabla users (compatible con tu esquema)
        await _supabase.from('users').insert({
          'auth_id': response.user!.id,
          'name': username.trim(),
          'email': email.trim().toLowerCase(),
          'points': 0,
          'predictions': 0,
          'correct': 0,
          'level': 1,
          'current_streak': 0,
          'best_streak': 0,
          'monthly_points': 0,
          'monthly_predictions': 0,
          'monthly_correct': 0,
          'monthly_championships': 0,
          'achievements': [],
          'titles': [],
          'is_admin': false,
          'last_monthly_reset': DateTime.now().toIso8601String(),
        });
        
        print('✅ Perfil creado en tabla users');
      } else {
        print('⚠️ Registro completado pero usuario es null');
      }

      return response;
    } catch (e) {
      print('❌ Error en signUp: $e');
      
      // Mensajes de error más específicos
      if (e.toString().contains('duplicate key')) {
        print('💡 El usuario ya existe. Puede ser:');
        print('   - Email duplicado en auth.users');
        print('   - Nombre de usuario duplicado en users (UNIQUE constraint)');
      }
      
      rethrow;
    }
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      print('🔐 Intentando login para: $email');
      
      final response = await _supabase.auth.signInWithPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );
      
      print('✅ Login exitoso: ${response.user?.id}');
      return response;
    } catch (e) {
      print('❌ Error en signIn: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      print('👋 Cerrando sesión...');
      await _supabase.auth.signOut();
      print('✅ Sesión cerrada');
    } catch (e) {
      print('❌ Error en signOut: $e');
      rethrow;
    }
  }

  Future<UserModel?> getUserProfile(String authId) async {
    try {
      print('📊 Obteniendo perfil para auth_id: $authId');
      
      final response = await _supabase
          .from('users')
          .select()
          .eq('auth_id', authId)
          .single();
      
      print('✅ Perfil obtenido: ${response['name']} (${response['email']})');
      print('📈 Stats: ${response['points']} pts | Nivel ${response['level']} | ${response['predictions']} predicciones');
      
      return UserModel.fromJson(response);
    } catch (e) {
      print('❌ Error obteniendo perfil de usuario: $e');
      print('🔍 Verifica que:');
      print('   1. La tabla "users" existe en Supabase');
      print('   2. Existe un registro con auth_id = $authId');
      print('   3. RLS permite SELECT al usuario autenticado');
      
      // Intentar obtener más información sobre el error
      if (e.toString().contains('JWT')) {
        print('⚠️ Problema con el token de autenticación');
      } else if (e.toString().contains('no rows')) {
        print('⚠️ No existe un registro en users para este auth_id');
        print('💡 Puede que el registro falló durante signUp');
      }
      
      return null;
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      print('🔑 Enviando email de recuperación a: $email');
      
      await _supabase.auth.resetPasswordForEmail(
        email.trim().toLowerCase(),
      );
      
      print('✅ Email de recuperación enviado');
    } catch (e) {
      print('❌ Error en resetPassword: $e');
      rethrow;
    }
  }

  // Método adicional: Actualizar perfil de usuario
  Future<bool> updateUserProfile({
    required String userId,
    String? bio,
    String? favoriteTeam,
    String? favoritePlayer,
    String? gender,
    String? nationality,
    String? avatarUrl,
  }) async {
    try {
      print('✏️ Actualizando perfil de usuario: $userId');
      
      final updateData = <String, dynamic>{};
      
      if (bio != null) updateData['bio'] = bio;
      if (favoriteTeam != null) updateData['favorite_team'] = favoriteTeam;
      if (favoritePlayer != null) updateData['favorite_player'] = favoritePlayer;
      if (gender != null) updateData['gender'] = gender;
      if (nationality != null) updateData['nationality'] = nationality;
      if (avatarUrl != null) updateData['avatar_url'] = avatarUrl;
      
      if (updateData.isEmpty) {
        print('⚠️ No hay datos para actualizar');
        return false;
      }
      
      await _supabase
          .from('users')
          .update(updateData)
          .eq('id', userId);
      
      print('✅ Perfil actualizado exitosamente');
      return true;
    } catch (e) {
      print('❌ Error actualizando perfil: $e');
      return false;
    }
  }
}