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

  String _getErrorMessage(String error) {
    if (error.contains('Invalid login credentials')) {
      return 'Correo o contraseña incorrectos';
    } else if (error.contains('Email not confirmed')) {
      return 'Por favor verifica tu correo antes de iniciar sesión';
    } else if (error.contains('User not found')) {
      return 'Esta cuenta no existe. Por favor regístrate primero';
    } else if (error.contains('already registered')) {
      return 'Este correo ya está registrado';
    } else {
      return 'Error al procesar tu solicitud';
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}