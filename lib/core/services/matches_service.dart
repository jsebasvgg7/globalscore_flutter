import 'package:supabase_flutter/supabase_flutter.dart';

class MatchesService {
  final _supabase = Supabase.instance.client;

  // ⚡ Hacer predicción (equivalente a makePrediction de React)
  Future<List<Map<String, dynamic>>> makePrediction({
    required String userId,
    required String matchId,
    required int homeScore,
    required int awayScore,
    String? advancingTeam,
  }) async {
    try {
      print('🎯 Guardando predicción: $matchId - $homeScore:$awayScore');

      final predictionData = {
        'match_id': matchId,
        'user_id': userId,
        'home_score': homeScore,
        'away_score': awayScore,
      };

      // ⚡ Solo agregar advancing_team si existe
      if (advancingTeam != null) {
        predictionData['predicted_advancing_team'] = advancingTeam;
      }

      final response = await _supabase
          .from('predictions')
          .upsert(predictionData, onConflict: 'match_id,user_id')
          .select();

      if (response.isEmpty) {
        throw Exception('No se pudo guardar la predicción');
      }

      print('✅ Predicción guardada: $response');

      // Recargar lista de partidos
      final matchList = await _supabase
          .from('matches')
          .select('*, predictions(*)')
          .order('date', ascending: true);

      return matchList as List<Map<String, dynamic>>;
    } catch (e) {
      print('❌ Error al guardar predicción: $e');
      rethrow;
    }
  }

  // Obtener todos los partidos con predicciones
  Future<List<Map<String, dynamic>>> getMatches() async {
    try {
      print('📊 Obteniendo partidos...');

      final response = await _supabase
          .from('matches')
          .select('*, predictions(*)')
          .order('date', ascending: true);

      print('✅ ${response.length} partidos obtenidos');
      return response as List<Map<String, dynamic>>;
    } catch (e) {
      print('❌ Error obteniendo partidos: $e');
      rethrow;
    }
  }

  // Obtener predicción del usuario para un partido específico
  Future<Map<String, dynamic>?> getUserPrediction({
    required String userId,
    required String matchId,
  }) async {
    try {
      final response = await _supabase
          .from('predictions')
          .select()
          .eq('user_id', userId)
          .eq('match_id', matchId)
          .maybeSingle();

      return response;
    } catch (e) {
      print('❌ Error obteniendo predicción: $e');
      return null;
    }
  }

  // Finalizar partido (solo admin)
  Future<Map<String, dynamic>> finishMatch({
    required String matchId,
    required int homeScore,
    required int awayScore,
    String? advancingTeam,
  }) async {
    try {
      print('🎯 Finalizando partido $matchId: $homeScore-$awayScore');

      // 1. Actualizar resultado del partido
      final updateData = {
        'result_home': homeScore,
        'result_away': awayScore,
        'status': 'finished'
      };

      if (advancingTeam != null) {
        updateData['advancing_team'] = advancingTeam;
      }

      await _supabase
          .from('matches')
          .update(updateData)
          .eq('id', matchId);

      // 2. Obtener partido con predicciones
      final match = await _supabase
          .from('matches')
          .select('*, predictions(*)')
          .eq('id', matchId)
          .single();

      print('📊 Partido encontrado con ${match['predictions'].length} predicciones');

      // 3. Calcular y distribuir puntos
      final resultDiff = (homeScore - awayScore).sign;
      int exactPredictions = 0;
      int correctResults = 0;
      int correctAdvancing = 0;

      for (var prediction in match['predictions']) {
        final predDiff = (prediction['home_score'] - prediction['away_score']).sign;
        int pointsEarned = 0;
        int advancingPoints = 0;

        // Resultado exacto: 5 puntos
        if (prediction['home_score'] == homeScore && 
            prediction['away_score'] == awayScore) {
          pointsEarned = 5;
          exactPredictions++;
          print('✅ Usuario ${prediction['user_id']}: Resultado exacto (+5 pts)');
        }
        // Resultado correcto: 3 puntos
        else if (resultDiff == predDiff) {
          pointsEarned = 3;
          correctResults++;
          print('✅ Usuario ${prediction['user_id']}: Acertó resultado (+3 pts)');
        }
        else {
          print('❌ Usuario ${prediction['user_id']}: No acertó (0 pts)');
        }

        // ⚡ Puntos por advancing team
        if (match['is_knockout'] && advancingTeam != null && pointsEarned > 0) {
          if (prediction['predicted_advancing_team'] == advancingTeam) {
            advancingPoints = 2;
            correctAdvancing++;
            print('⚡ Usuario ${prediction['user_id']}: Acertó equipo que pasa (+2 pts)');
          }
        }

        final totalPoints = pointsEarned + advancingPoints;

        // Actualizar predicción
        await _supabase
            .from('predictions')
            .update({
              'points_earned': pointsEarned,
              'advancing_points': advancingPoints
            })
            .eq('id', prediction['id']);

        // Obtener datos del usuario
        final userData = await _supabase
            .from('users')
            .select('points, predictions, correct, best_streak, current_streak, monthly_points, monthly_predictions, monthly_correct')
            .eq('id', prediction['user_id'])
            .single();

        if (userData == null) continue;

        // Calcular nuevas estadísticas
        final newPoints = (userData['points'] ?? 0) + totalPoints;
        final newPredictions = (userData['predictions'] ?? 0) + 1;
        final newCorrect = (userData['correct'] ?? 0) + (totalPoints > 0 ? 1 : 0);

        final newMonthlyPoints = (userData['monthly_points'] ?? 0) + totalPoints;
        final newMonthlyPredictions = (userData['monthly_predictions'] ?? 0) + 1;
        final newMonthlyCorrect = (userData['monthly_correct'] ?? 0) + (totalPoints > 0 ? 1 : 0);

        int newCurrentStreak = userData['current_streak'] ?? 0;
        int newBestStreak = userData['best_streak'] ?? 0;

        if (totalPoints > 0) {
          newCurrentStreak = newCurrentStreak + 1;
          newBestStreak = newBestStreak > newCurrentStreak ? newBestStreak : newCurrentStreak;
        } else {
          newCurrentStreak = 0;
        }

        // Actualizar usuario
        await _supabase
            .from('users')
            .update({
              'points': newPoints,
              'predictions': newPredictions,
              'correct': newCorrect,
              'current_streak': newCurrentStreak,
              'best_streak': newBestStreak,
              'monthly_points': newMonthlyPoints,
              'monthly_predictions': newMonthlyPredictions,
              'monthly_correct': newMonthlyCorrect
            })
            .eq('id', prediction['user_id']);

        print('✅ Usuario ${prediction['user_id']} actualizado exitosamente');
      }

      print('✅ Partido finalizado: $exactPredictions exactos, $correctResults acertaron ganador');
      if (match['is_knockout']) {
        print('⚡ $correctAdvancing acertaron equipo que pasa');
      }

      return {
        'success': true,
        'exactPredictions': exactPredictions,
        'correctResults': correctResults,
        'correctAdvancing': correctAdvancing
      };
    } catch (e) {
      print('❌ Error al finalizar partido: $e');
      rethrow;
    }
  }
}