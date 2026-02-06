import 'package:flutter/material.dart';
import '../../core/services/matches_service.dart';
import '../../models/user_model.dart';

class MatchesProvider with ChangeNotifier {
  final MatchesService _service = MatchesService();
  
  List<Map<String, dynamic>> _matches = [];
  bool _loading = false;
  String? _error;

  List<Map<String, dynamic>> get matches => _matches;
  bool get loading => _loading;
  String? get error => _error;

  // Hacer predicción
  Future<bool> makePrediction({
    required UserModel currentUser,
    required String matchId,
    required int homeScore,
    required int awayScore,
    String? advancingTeam,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      print('🎯 MatchesProvider: Guardando predicción...');
      
      final updatedMatches = await _service.makePrediction(
        userId: currentUser.id,
        matchId: matchId,
        homeScore: homeScore,
        awayScore: awayScore,
        advancingTeam: advancingTeam,
      );

      _matches = updatedMatches;
      _loading = false;
      notifyListeners();
      
      print('✅ MatchesProvider: Predicción guardada');
      return true;
    } catch (e) {
      _error = 'Error al guardar predicción: $e';
      _loading = false;
      notifyListeners();
      
      print('❌ MatchesProvider: Error - $e');
      return false;
    }
  }

  // Cargar todos los partidos
  Future<void> loadMatches() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      print('📊 MatchesProvider: Cargando partidos...');
      
      _matches = await _service.getMatches();
      _loading = false;
      notifyListeners();
      
      print('✅ MatchesProvider: ${_matches.length} partidos cargados');
    } catch (e) {
      _error = 'Error al cargar partidos: $e';
      _loading = false;
      notifyListeners();
      
      print('❌ MatchesProvider: Error - $e');
    }
  }

  // Obtener predicción del usuario para un partido
  Future<Map<String, dynamic>?> getUserPrediction({
    required String userId,
    required String matchId,
  }) async {
    try {
      return await _service.getUserPrediction(
        userId: userId,
        matchId: matchId,
      );
    } catch (e) {
      print('❌ Error obteniendo predicción: $e');
      return null;
    }
  }

  // Finalizar partido (solo admin)
  Future<Map<String, dynamic>?> finishMatch({
    required String matchId,
    required int homeScore,
    required int awayScore,
    String? advancingTeam,
  }) async {
    _loading = true;
    notifyListeners();

    try {
      print('🎯 MatchesProvider: Finalizando partido...');
      
      final result = await _service.finishMatch(
        matchId: matchId,
        homeScore: homeScore,
        awayScore: awayScore,
        advancingTeam: advancingTeam,
      );

      // Recargar partidos
      await loadMatches();
      
      _loading = false;
      notifyListeners();
      
      print('✅ MatchesProvider: Partido finalizado');
      return result;
    } catch (e) {
      _error = 'Error al finalizar partido: $e';
      _loading = false;
      notifyListeners();
      
      print('❌ MatchesProvider: Error - $e');
      return null;
    }
  }

  // Filtrar partidos por estado
  List<Map<String, dynamic>> getMatchesByStatus(String status) {
    return _matches.where((m) => m['status'] == status).toList();
  }

  // Filtrar partidos por liga
  List<Map<String, dynamic>> getMatchesByLeague(String league) {
    return _matches.where((m) => m['league'] == league).toList();
  }

  // Obtener partidos pendientes
  List<Map<String, dynamic>> get pendingMatches {
    return _matches.where((m) => m['status'] == 'pending').toList();
  }

  // Obtener partidos finalizados
  List<Map<String, dynamic>> get finishedMatches {
    return _matches.where((m) => m['status'] == 'finished').toList();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}