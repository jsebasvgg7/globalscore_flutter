import 'package:flutter/material.dart';
import '../core/services/auth_service.dart';
import '../models/user_model.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _error;
  bool _isInitialized = false;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null;
  bool get isAdmin => _currentUser?.isAdmin ?? false;
  bool get isInitialized => _isInitialized;

  AuthProvider() {
    _init();
  }

  Future<void> _init() async {
    // Escuchar cambios de autenticación
    _authService.authStateChanges.listen((data) {
      if (data.session != null) {
        _loadUserProfile(data.session!.user.id);
      } else {
        _currentUser = null;
        _isInitialized = true;
        notifyListeners();
      }
    });

    // Cargar usuario actual si existe sesión
    final user = _authService.currentUser;
    if (user != null) {
      await _loadUserProfile(user.id);
    } else {
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<void> _loadUserProfile(String authId) async {
    try {
      _currentUser = await _authService.getUserProfile(authId);
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      print('Error loading profile: $e');
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.signUp(
        email: email,
        password: password,
        username: name,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _getErrorMessage(e.toString());
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.signIn(email: email, password: password);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _getErrorMessage(e.toString());
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    _currentUser = null;
    notifyListeners();
  }

  Future<bool> resetPassword(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.resetPassword(email);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _getErrorMessage(e.toString());
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateProfile({
    String? bio,
    String? favoriteTeam,
    String? favoritePlayer,
    String? gender,
    String? nationality,
    String? avatarUrl,
  }) async {
    if (_currentUser == null) return false;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _authService.updateUserProfile(
        userId: _currentUser!.id,
        bio: bio,
        favoriteTeam: favoriteTeam,
        favoritePlayer: favoritePlayer,
        gender: gender,
        nationality: nationality,
        avatarUrl: avatarUrl,
      );

      if (success) {
        // Recargar el perfil después de actualizar
        await _loadUserProfile(_currentUser!.authId);
      }

      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _error = 'Error al actualizar el perfil';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  String _getErrorMessage(String error) {
    if (error.contains('Invalid login credentials')) {
      return 'Correo o contraseña incorrectos';
    } else if (error.contains('Email not confirmed')) {
      return 'Por favor verifica tu correo antes de iniciar sesión';
    } else if (error.contains('User not found')) {
      return 'Esta cuenta no existe. Por favor regístrate primero';
    } else if (error.contains('already registered') || error.contains('User already registered')) {
      return 'Este correo ya está registrado';
    } else if (error.contains('users_name_key') || error.contains('duplicate key')) {
      return 'Este nombre de usuario ya está en uso. Por favor elige otro';
    } else if (error.contains('violates unique constraint')) {
      return 'Este nombre de usuario ya está en uso';
    } else if (error.contains('violates row-level security policy')) {
      return 'Error de permisos. Contacta al administrador';
    } else if (error.contains('Network request failed')) {
      return 'Sin conexión a internet. Verifica tu conexión';
    } else if (error.contains('Password should be at least')) {
      return 'La contraseña debe tener al menos 6 caracteres';
    } else {
      return 'Error al procesar tu solicitud';
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}