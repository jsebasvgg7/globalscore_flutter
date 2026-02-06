import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../../core/constants/app_colors.dart';
import '../../models/match_model.dart';

class MatchCard extends StatefulWidget {
  final MatchModel match;
  final PredictionModel? userPrediction;
  final Function(String matchId, int homeScore, int awayScore, String? advancingTeam) onPredict;

  const MatchCard({
    super.key,
    required this.match,
    this.userPrediction,
    required this.onPredict,
  });

  @override
  State<MatchCard> createState() => _MatchCardState();
}

class _MatchCardState extends State<MatchCard> with SingleTickerProviderStateMixin {
  late TextEditingController _homeScoreController;
  late TextEditingController _awayScoreController;
  String? _advancingTeam;
  bool _isSaved = false;
  bool _isSaving = false;
  Timer? _saveTimer;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    
    // Inicializar controladores con predicción existente
    _homeScoreController = TextEditingController(
      text: widget.userPrediction?.homeScore.toString() ?? '',
    );
    _awayScoreController = TextEditingController(
      text: widget.userPrediction?.awayScore.toString() ?? '',
    );
    _advancingTeam = widget.userPrediction?.predictedAdvancingTeam;
    _isSaved = widget.userPrediction != null;

    // Animación de pulso para el advancing team
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Listeners para auto-save
    _homeScoreController.addListener(_onScoreChanged);
    _awayScoreController.addListener(_onScoreChanged);
  }

  @override
  void didUpdateWidget(MatchCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Actualizar si la predicción cambió externamente
    if (widget.userPrediction != oldWidget.userPrediction) {
      _homeScoreController.text = widget.userPrediction?.homeScore.toString() ?? '';
      _awayScoreController.text = widget.userPrediction?.awayScore.toString() ?? '';
      _advancingTeam = widget.userPrediction?.predictedAdvancingTeam;
      _isSaved = widget.userPrediction != null;
    }
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    _homeScoreController.dispose();
    _awayScoreController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _onScoreChanged() {
    if (_isDisabled) return;

    // Cancelar timer anterior
    _saveTimer?.cancel();

    setState(() {
      _isSaved = false;
    });

    // Validar que ambos campos tengan valores
    final homeText = _homeScoreController.text;
    final awayText = _awayScoreController.text;

    if (homeText.isEmpty || awayText.isEmpty) return;

    final home = int.tryParse(homeText);
    final away = int.tryParse(awayText);

    if (home == null || away == null) return;

    // Verificar si es diferente a la predicción actual
    final isDifferent = home != widget.userPrediction?.homeScore ||
        away != widget.userPrediction?.awayScore ||
        _advancingTeam != widget.userPrediction?.predictedAdvancingTeam;

    if (!isDifferent) {
      setState(() => _isSaved = true);
      return;
    }

    // Auto-save después de 1 segundo
    _saveTimer = Timer(const Duration(seconds: 1), () {
      _savePrediction(home, away);
    });
  }

  Future<void> _savePrediction(int home, int away) async {
    if (_isDisabled) return;

    setState(() => _isSaving = true);

    try {
      await widget.onPredict(widget.match.id, home, away, _advancingTeam);
      
      if (mounted) {
        setState(() {
          _isSaved = true;
          _isSaving = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _toggleAdvancingTeam(String team) {
    if (_isDisabled || !widget.match.isKnockout) return;

    setState(() {
      _advancingTeam = _advancingTeam == team ? null : team;
      _isSaved = false;
    });

    _onScoreChanged();
  }

  bool get _isDisabled {
    if (widget.match.status != 'pending') return true;
    if (widget.match.deadline == null) return false;

    try {
      final deadline = DateTime.parse(widget.match.deadline!);
      return DateTime.now().isAfter(deadline);
    } catch (e) {
      return false;
    }
  }

  bool get _isPastDeadline => _isDisabled && widget.match.status == 'pending';

  String _formatDate(String dateStr) {
    if (dateStr.isEmpty) return '';
    
    try {
      // Si no es formato YYYY-MM-DD, retornar tal cual
      if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(dateStr)) {
        return dateStr;
      }

      final parts = dateStr.split('-');
      final date = DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = today.add(const Duration(days: 1));
      final matchDay = DateTime(date.year, date.month, date.day);

      if (matchDay == today) {
        return 'Hoy';
      } else if (matchDay == tomorrow) {
        return 'Mañana';
      } else {
        final months = ['', 'ene', 'feb', 'mar', 'abr', 'may', 'jun', 
                       'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];
        return '${date.day} ${months[date.month]}';
      }
    } catch (e) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gray200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildHeader(),
          _buildContent(),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.gray50,
            Colors.white,
          ],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
        border: Border(
          bottom: BorderSide(color: AppColors.gray100),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Liga
          Expanded(
            child: Row(
              children: [
                if (widget.match.leagueLogoUrl != null)
                  Image.network(
                    widget.match.leagueLogoUrl!,
                    width: 22,
                    height: 22,
                    errorBuilder: (_, __, ___) => Icon(
                      Icons.emoji_events,
                      size: 22,
                      color: AppColors.gray500,
                    ),
                  )
                else
                  Icon(
                    Icons.emoji_events,
                    size: 22,
                    color: AppColors.gray500,
                  ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.match.league,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.01,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          
          // Badges y fecha
          Row(
            children: [
              if (widget.match.isKnockout) ...[
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.08),
                    border: Border.all(
                      color: AppColors.warning.withOpacity(0.15),
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.bolt,
                    size: 16,
                    color: AppColors.warning,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.08),
                  border: Border.all(
                    color: AppColors.info.withOpacity(0.15),
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 12,
                      color: AppColors.info,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _formatDate(widget.match.date),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.info,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          // Equipo Local
          Expanded(child: _buildTeamSection('home')),
          
          // Predicción Central
          _buildPredictionSection(),
          
          // Equipo Visitante
          Expanded(child: _buildTeamSection('away')),
        ],
      ),
    );
  }

  Widget _buildTeamSection(String side) {
    final isHome = side == 'home';
    final teamName = isHome ? widget.match.homeTeam : widget.match.awayTeam;
    final teamLogoUrl = isHome ? widget.match.homeTeamLogoUrl : widget.match.awayTeamLogoUrl;
    final teamEmoji = isHome ? widget.match.homeTeamLogo : widget.match.awayTeamLogo;
    final isAdvancing = _advancingTeam == side;
    final canClick = widget.match.isKnockout && !_isDisabled;

    return Column(
      children: [
        GestureDetector(
          onTap: canClick ? () => _toggleAdvancingTeam(side) : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: isAdvancing 
                  ? AppColors.success.withOpacity(0.1)
                  : AppColors.gray50,
              border: Border.all(
                color: isAdvancing 
                    ? AppColors.success 
                    : AppColors.gray200,
                width: isAdvancing ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: isAdvancing ? [
                BoxShadow(
                  color: AppColors.success.withOpacity(0.3),
                  blurRadius: 12,
                  spreadRadius: 0,
                ),
              ] : null,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (teamLogoUrl != null)
                  Image.network(
                    teamLogoUrl,
                    width: 52,
                    height: 52,
                    errorBuilder: (_, __, ___) => Text(
                      teamEmoji ?? '⚽',
                      style: const TextStyle(fontSize: 48),
                    ),
                  )
                else
                  Text(
                    teamEmoji ?? '⚽',
                    style: const TextStyle(fontSize: 48),
                  ),
                
                if (isAdvancing && !_isDisabled)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: ScaleTransition(
                      scale: _pulseAnimation,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.success.withOpacity(0.4),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.check,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          teamName,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            height: 1.3,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildPredictionSection() {
    return Container(
      width: 140,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // Inputs de marcador
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildScoreInput(_homeScoreController),
              const SizedBox(width: 10),
              _buildScoreInput(_awayScoreController),
            ],
          ),
          const SizedBox(height: 12),
          
          // Hora del partido
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: AppColors.gray50,
              border: Border.all(color: AppColors.gray200),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.access_time,
                  size: 12,
                  color: AppColors.gray600,
                ),
                const SizedBox(width: 6),
                Text(
                  widget.match.time,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.gray600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreInput(TextEditingController controller) {
    final hasValue = controller.text.isNotEmpty;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        gradient: _isSaved && hasValue
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFD1FAE5), Color(0xFFA7F3D0)],
              )
            : null,
        color: _isSaved && hasValue ? null : AppColors.gray50,
        border: Border.all(
          color: _isSaved && hasValue 
              ? AppColors.success 
              : AppColors.gray200,
          width: _isSaved && hasValue ? 2 : 2,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: _isSaved && hasValue ? [
          BoxShadow(
            color: AppColors.success.withOpacity(0.15),
            blurRadius: 8,
          ),
        ] : [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          TextField(
            controller: controller,
            enabled: !_isDisabled,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(2),
            ],
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: _isSaved && hasValue 
                  ? const Color(0xFF065F46)
                  : AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: '—',
              hintStyle: TextStyle(
                color: AppColors.gray300,
                fontWeight: FontWeight.w400,
              ),
              contentPadding: EdgeInsets.zero,
            ),
            onChanged: (value) {
              if (value.isNotEmpty) {
                final numValue = int.tryParse(value);
                if (numValue != null && numValue > 20) {
                  controller.text = '20';
                  controller.selection = TextSelection.fromPosition(
                    TextPosition(offset: controller.text.length),
                  );
                }
              }
            },
          ),
          
          if (_isSaved && hasValue && !_isDisabled)
            Positioned(
              top: -7,
              right: -7,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFD1FAE5),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.success.withOpacity(0.3),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.check,
                  size: 12,
                  color: AppColors.success,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            AppColors.gray50,
            Colors.white,
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
        border: Border(
          top: BorderSide(color: AppColors.gray100),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildStatusMessage(),
          
          if (widget.match.isKnockout && !_isDisabled) ...[
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.08),
                border: Border.all(
                  color: AppColors.warning.withOpacity(0.2),
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.emoji_events,
                    size: 12,
                    color: AppColors.warning,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Toca el escudo del equipo que pasa (+2 pts)',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.warning.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusMessage() {
    IconData icon;
    String text;
    Color backgroundColor;
    Color borderColor;
    Color textColor;

    if (_isPastDeadline) {
      icon = Icons.access_time;
      text = 'Predicción cerrada';
      backgroundColor = AppColors.error.withOpacity(0.08);
      borderColor = AppColors.error.withOpacity(0.2);
      textColor = AppColors.error;
    } else if (_isSaving) {
      icon = Icons.sync;
      text = 'Guardando...';
      backgroundColor = AppColors.warning.withOpacity(0.08);
      borderColor = AppColors.warning.withOpacity(0.2);
      textColor = AppColors.warning;
    } else if (_isSaved) {
      icon = Icons.check_circle;
      text = 'Predicción guardada';
      backgroundColor = AppColors.success.withOpacity(0.08);
      borderColor = AppColors.success.withOpacity(0.2);
      textColor = AppColors.success;
    } else {
      icon = Icons.info_outline;
      text = 'Predicción pendiente';
      backgroundColor = AppColors.warning.withOpacity(0.08);
      borderColor = AppColors.warning.withOpacity(0.2);
      textColor = AppColors.warning;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isSaving)
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(textColor),
              ),
            )
          else
            Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}