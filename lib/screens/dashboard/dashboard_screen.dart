import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/matches_provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _activeTab = 'matches'; // matches, leagues, awards
  String _leagueFilter = 'all';
  String _sortOption = 'date-asc';
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final matchesProvider = context.read<MatchesProvider>();
    await matchesProvider.loadMatches();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final matchesProvider = context.watch<MatchesProvider>();
    final currentUser = authProvider.currentUser;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(
          child: Text('Error: Usuario no encontrado'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('GlobalScore'),
        actions: [
          // Tema toggle
          IconButton(
            icon: const Icon(Icons.brightness_6),
            onPressed: () {
              // TODO: Implementar toggle de tema
            },
          ),
          // Notificaciones
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // TODO: Ir a notificaciones
            },
          ),
          // Stats (solo desktop)
          if (MediaQuery.of(context).size.width > 768)
            IconButton(
              icon: const Icon(Icons.bar_chart),
              onPressed: () {
                // TODO: Ir a estadísticas
              },
            ),
          // Logout
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authProvider.signOut();
              if (!context.mounted) return;
              Navigator.of(context).pushReplacementNamed('/login');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Navigation Tabs
          _buildNavigationTabs(),
          
          // Filters Header
          if (_activeTab == 'matches') _buildFiltersHeader(matchesProvider),
          
          // Content
          Expanded(
            child: _buildContent(matchesProvider, currentUser.id),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ============================================
  // NAVIGATION TABS
  // ============================================
  Widget _buildNavigationTabs() {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.purple.withOpacity(0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.purple.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildTab('matches', Icons.sports_soccer, 'Partidos'),
          _buildTab('leagues', Icons.emoji_events, 'Ligas'),
          _buildTab('awards', Icons.military_tech, 'Premios'),
        ],
      ),
    );
  }

  Widget _buildTab(String key, IconData icon, String label) {
    final isActive = _activeTab == key;
    
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeTab = key),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          decoration: BoxDecoration(
            gradient: isActive
                ? const LinearGradient(
                    colors: [AppColors.purple, AppColors.purpleDark],
                  )
                : null,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isActive ? Colors.white : AppColors.gray600,
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                  color: isActive ? Colors.white : AppColors.gray600,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================
  // FILTERS HEADER
  // ============================================
  Widget _buildFiltersHeader(MatchesProvider matchesProvider) {
    final pendingCount = matchesProvider.pendingMatches.length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(
          bottom: BorderSide(
            color: AppColors.gray200,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Badge con contador
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.purple, AppColors.purpleDark],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.sports_soccer, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Text(
                  '$pendingCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          // Botones de Sort y Filter
          Row(
            children: [
              _buildFilterButton(
                icon: Icons.sort,
                label: 'Ordenar',
                onTap: () {
                  // TODO: Implementar sort modal
                },
              ),
              const SizedBox(width: 8),
              _buildFilterButton(
                icon: Icons.filter_list,
                label: 'Filtrar',
                onTap: () {
                  setState(() => _showFilters = !_showFilters);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: AppColors.gray300,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: AppColors.gray600),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================
  // CONTENT
  // ============================================
  Widget _buildContent(MatchesProvider matchesProvider, String userId) {
    if (matchesProvider.loading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.purple),
        ),
      );
    }

    if (matchesProvider.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              matchesProvider.error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => matchesProvider.loadMatches(),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (_activeTab == 'matches') {
      final matches = matchesProvider.pendingMatches;
      
      if (matches.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '⚽',
                style: TextStyle(
                  fontSize: 48,
                  color: AppColors.gray400.withOpacity(0.3),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Sin partidos disponibles',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: matches.length,
        itemBuilder: (context, index) {
          final match = matches[index];
          
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(20),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Liga y Fecha
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      match['league'] ?? 'Liga',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      match['date'] ?? '',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Equipos
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        match['home_team'] ?? '',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const Text(
                      'vs',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.gray400,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        match['away_team'] ?? '',
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Inputs de predicción
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // TODO: Implementar inputs de predicción
                    const Text('TODO: Inputs de predicción'),
                  ],
                ),
              ],
            ),
          );
        },
      );
    }

    // TODO: Implementar tabs de leagues y awards
    return Center(
      child: Text(
        'Tab: $_activeTab\n(En construcción)',
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 16,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  // ============================================
  // BOTTOM NAVIGATION
  // ============================================
  Widget _buildBottomNav() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      backgroundColor: AppColors.purple,
      selectedItemColor: Colors.white,
      unselectedItemColor: Colors.white70,
      currentIndex: 0,
      onTap: (index) {
        // TODO: Implementar navegación
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Perfil',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.emoji_events),
          label: 'Ranking',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Inicio',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.bar_chart),
          label: 'Stats',
        ),
      ],
    );
  }
}