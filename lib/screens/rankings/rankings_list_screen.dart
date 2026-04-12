import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_strings.dart';
import '../../models/ranking.dart';
import '../../providers/locale_provider.dart';
import '../../services/ranking_service.dart';
import 'ranking_athlete_search_sheet.dart';
import 'ranking_detail_screen.dart';

class RankingsListScreen extends StatefulWidget {
  const RankingsListScreen({super.key});

  @override
  State<RankingsListScreen> createState() => _RankingsListScreenState();
}

class _RankingsListScreenState extends State<RankingsListScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final RankingService _service = RankingService();
  List<RankingMaster> _allRankings = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Años disponibles
  List<int> _years = [];
  int? _selectedYear;

  // Orden deseado de categorías
  static const List<String> _categoryOrder = ['U18', 'U20', 'MAYORES'];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );
    _loadData();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final rankings = await _service.getRankings();
      // Extraer años únicos ordenados desc
      final yearsSet = rankings.map((r) => r.year).toSet().toList()
        ..sort((a, b) => b.compareTo(a));
      final currentYear = DateTime.now().year;
      int? defaultYear = yearsSet.contains(currentYear)
          ? currentYear
          : (yearsSet.isNotEmpty ? yearsSet.first : null);

      if (mounted) {
        setState(() {
          _allRankings = rankings;
          _years = yearsSet;
          _selectedYear = defaultYear;
          _isLoading = false;
        });
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) {
            _fadeController.forward();
            _slideController.forward();
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = AppStrings.es.errorLoadingRanking(e.toString());
        });
      }
    }
  }

  /// Rankings filtrados por el año seleccionado
  List<RankingMaster> get _filteredRankings {
    if (_selectedYear == null) return _allRankings;
    return _allRankings.where((r) => r.year == _selectedYear).toList();
  }

  /// Busca el ranking para un combo gender+category dentro de los filtrados
  RankingMaster? _findRanking(String gender, String category) {
    try {
      return _filteredRankings.firstWhere(
        (r) => r.gender == gender && r.category == category,
      );
    } catch (_) {
      return null;
    }
  }

  void _navigateToDetail(RankingMaster ranking) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, _) =>
            RankingDetailScreen(ranking: ranking),
        transitionDuration: const Duration(milliseconds: 500),
        reverseTransitionDuration: const Duration(milliseconds: 400),
        transitionsBuilder: (context, animation, _, child) {
          final slide = Tween(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));
          final fade = Tween<double>(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(
                  parent: animation,
                  curve: const Interval(0.2, 1.0, curve: Curves.easeOut)));
          return SlideTransition(
              position: slide,
              child: FadeTransition(opacity: fade, child: child));
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFF040512),
        body: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFE74C3C),
                        strokeWidth: 2,
                      ),
                    )
                  : _errorMessage != null
                      ? _buildError()
                      : FadeTransition(
                          opacity: _fadeAnimation,
                          child: SlideTransition(
                            position: _slideAnimation,
                            child: _buildBody(),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/botom3.jpg'),
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
        ),
      ),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xE8040512),
              Color(0xFF040512),
            ],
            stops: [0.0, 0.85],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nav bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: Colors.white.withOpacity(0.12)),
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new,
                          color: Colors.white70,
                          size: 16,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        // Año selector inline — discreto
                        if (_years.isNotEmpty) _buildYearSelector(),
                        const SizedBox(width: 8),
                        // Botón de búsqueda de atletas en rankings
                        GestureDetector(
                          onTap: () => showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) => const RankingAthleteSearchSheet(),
                          ),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.12)),
                            ),
                            child: const Icon(
                              Icons.person_search,
                              color: Colors.white70,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Etiqueta superior
                Text(
                  context.read<LocaleProvider>().strings.federationNameFull,
                  style: TextStyle(
                    color: const Color(0xFFE74C3C).withOpacity(0.7),
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2.0,
                  ),
                ),
                const SizedBox(height: 4),
                // Título principal en una sola línea elegante
                Text(
                  context.read<LocaleProvider>().strings.nationalRankings,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                // Subtítulo descriptivo
                Text(
                  _selectedYear != null
                      ? context.read<LocaleProvider>().strings.rankingSeason(_selectedYear!)
                      : context.read<LocaleProvider>().strings.rankingAllSeasons,
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildYearSelector() {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: _years.map((year) {
          final isSelected = year == _selectedYear;
          return GestureDetector(
            onTap: () => setState(() => _selectedYear = year),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withOpacity(0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(7),
              ),
              child: Text(
                '$year',
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white38,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBody() {
    final s = context.read<LocaleProvider>().strings;
    if (_allRankings.isEmpty) {
      return _buildEmptyState(s.noRankingsAvailable);
    }
    if (_filteredRankings.isEmpty && _selectedYear != null) {
      return _buildEmptyState(s.rankingNotPublished(_selectedYear!));
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: const Color(0xFFE74C3C),
      backgroundColor: const Color(0xFF1A1A2E),
      strokeWidth: 2.5,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          _buildGenderSection('F', s.women, Icons.female),
          const SizedBox(height: 20),
          _buildGenderSection('M', s.men, Icons.male),
        ],
      ),
    );
  }

  Widget _buildGenderSection(String gender, String label, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Encabezado de género — limpio y tipográfico
        Row(
          children: [
            Text(
              label.toUpperCase(),
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 2.5,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                height: 1,
                color: Colors.white.withOpacity(0.07),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Categorías como lista compacta dentro de un contenedor
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0C0D15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.07)),
          ),
          child: Column(
            children: _categoryOrder.asMap().entries.map((entry) {
              final idx = entry.key;
              final cat = entry.value;
              final ranking = _findRanking(gender, cat);
              return _buildCategoryRow(
                ranking, gender, cat,
                isFirst: idx == 0,
                isLast: idx == _categoryOrder.length - 1,
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryRow(
      RankingMaster? ranking, String gender, String category, {
      required bool isFirst,
      required bool isLast,
  }) {
    final bool isAvailable = ranking != null;
    final categoryLabel = _categoryLabelOf(category);

    return Column(
      children: [
        if (!isFirst)
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            color: Colors.white.withOpacity(0.06),
          ),
        InkWell(
          onTap: isAvailable ? () => _navigateToDetail(ranking!) : null,
          borderRadius: BorderRadius.vertical(
            top: isFirst ? const Radius.circular(12) : Radius.zero,
            bottom: isLast ? const Radius.circular(12) : Radius.zero,
          ),
          splashColor: Colors.white.withOpacity(0.04),
          highlightColor: Colors.white.withOpacity(0.02),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                // Tag de categoría — reemplaza el ícono
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isAvailable
                        ? const Color(0xFFE74C3C).withOpacity(0.1)
                        : Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isAvailable
                          ? const Color(0xFFE74C3C).withOpacity(0.25)
                          : Colors.white.withOpacity(0.07),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    _categoryCode(category),
                    style: TextStyle(
                      color: isAvailable
                          ? const Color(0xFFE74C3C)
                          : Colors.white24,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                // Nombre
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        categoryLabel,
                        style: TextStyle(
                          color: isAvailable ? Colors.white : Colors.white30,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isAvailable
                            ? ranking!.formattedPublishedAt
                            : _selectedYear != null
                                ? context.read<LocaleProvider>().strings.rankingNoDataForYear(_selectedYear!)
                                : context.read<LocaleProvider>().strings.notAvailable,
                        style: const TextStyle(
                          color: Colors.white30,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                // Status + chevron
                if (isAvailable) ...[  
                  _buildStatusBadge(ranking!),
                  const SizedBox(width: 10),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.white24,
                    size: 18,
                  ),
                ] else
                  Icon(
                    Icons.remove,
                    color: Colors.white.withOpacity(0.1),
                    size: 16,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(RankingMaster ranking) {
    final s = context.read<LocaleProvider>().strings;
    final isArchived = ranking.isArchived;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 5,
          height: 5,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isArchived ? Colors.white24 : const Color(0xFF2ECC71),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          isArchived ? s.rankingHistoric : s.rankingActive,
          style: TextStyle(
            color: isArchived ? Colors.white30 : const Color(0xFF2ECC71),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildError() {
    final s = context.read<LocaleProvider>().strings;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off_rounded,
                color: Colors.white24, size: 56),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? s.unknownError,
              style: const TextStyle(color: Colors.white54, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(s.retry),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE74C3C),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.emoji_events_outlined,
                color: Colors.white.withOpacity(0.15), size: 64),
            const SizedBox(height: 16),
            Text(
              message,
              style:
                  const TextStyle(color: Colors.white38, fontSize: 15),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _categoryLabelOf(String category) {
    switch (category) {
      case 'U18':
        return 'Sub 18';
      case 'U20':
        return 'Sub 20';
      case 'MAYORES':
        return 'Mayores';
      default:
        return category;
    }
  }

  String _categoryCode(String category) {
    switch (category) {
      case 'U18': return 'U18';
      case 'U20': return 'U20';
      case 'MAYORES': return 'MAY';
      default: return category;
    }
  }
}
