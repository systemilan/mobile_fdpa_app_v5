import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_strings.dart';
import '../../models/ranking.dart';
import '../../providers/locale_provider.dart';
import '../../services/ranking_service.dart';

class RankingAthleteSearchSheet extends StatefulWidget {
  const RankingAthleteSearchSheet({super.key});

  @override
  State<RankingAthleteSearchSheet> createState() =>
      _RankingAthleteSearchSheetState();
}

class _RankingAthleteSearchSheetState
    extends State<RankingAthleteSearchSheet> {
  final RankingService _service = RankingService();
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  List<RankingAthleteSearchResult> _results = [];
  bool _isLoading = false;
  bool _hasSearched = false;
  String _error = '';

  // Filtros
  String? _filterYear;
  String? _filterGender; // 'F' | 'M' | null
  List<String> _availableYears = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // ─── Filtrado local sobre los resultados ya cargados ────────────────────

  List<RankingAthleteSearchResult> get _filteredResults {
    var list = _results;
    if (_filterYear != null) {
      final y = int.tryParse(_filterYear!);
      if (y != null) list = list.where((r) => r.year == y).toList();
    }
    if (_filterGender != null) {
      list = list.where((r) => r.gender == _filterGender).toList();
    }
    return list;
  }

  // ─── API call ───────────────────────────────────────────────────────────

  Future<void> _search() async {
    final query = _controller.text.trim();
    if (query.length < 2) return;

    final s = context.read<LocaleProvider>().strings;
    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      _hasSearched = true;
      _error = '';
    });

    try {
      final results = await _service.searchAthletes(query, limit: 200);

      if (mounted) {
        // Extraer años únicos desc
        final yearsSet = results.map((r) => '${r.year}').toSet().toList()
          ..sort((a, b) => b.compareTo(a));

        // Auto-seleccionar año actual si está disponible
        final currentYear = '${DateTime.now().year}';
        final defaultYear =
            yearsSet.contains(currentYear) ? currentYear : null;

        setState(() {
          _results = results;
          _availableYears = yearsSet;
          _filterYear ??= defaultYear;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = s.searchError;
          _isLoading = false;
        });
      }
    }
  }

  // ─── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 0.92,
      decoration: const BoxDecoration(
        color: Color(0xFF0D0F1A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          _buildHeader(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final s = context.read<LocaleProvider>().strings;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0F1A),
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.06)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Título
          Row(
            children: [
              const Icon(Icons.emoji_events_rounded,
                  color: Color(0xFFE74C3C), size: 22),
              const SizedBox(width: 10),
              Text(
                s.searchInRankings,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.close,
                      color: Colors.white54, size: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            s.searchAthleteInRankingsHint,
            style: TextStyle(
              color: Colors.white.withOpacity(0.35),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 14),

          // Campo de búsqueda
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.07),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                const Icon(Icons.search, color: Colors.white38, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: s.enterNameSurname,
                      hintStyle: TextStyle(
                          color: Colors.white.withOpacity(0.3), fontSize: 13),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onSubmitted: (_) => _search(),
                  ),
                ),
                if (_controller.text.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      _controller.clear();
                      setState(() {
                        _results = [];
                        _hasSearched = false;
                        _error = '';
                      });
                    },
                    child: const Padding(
                      padding: EdgeInsets.only(left: 8),
                      child: Icon(Icons.clear, color: Colors.white38, size: 18),
                    ),
                  ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _search,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE74C3C),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Text(
                      s.search,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFFE74C3C),
          strokeWidth: 2,
        ),
      );
    }

    if (_error.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wifi_off_rounded,
                  color: Colors.white24, size: 48),
              const SizedBox(height: 12),
              Text(_error,
                  style: const TextStyle(
                      color: Colors.white38, fontSize: 13),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }

    if (!_hasSearched) {
      return _buildIdleState();
    }

    final filtered = _filteredResults;

    if (filtered.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        // Filtros + contador
        _buildFiltersBar(filtered.length),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            itemCount: filtered.length,
            itemBuilder: (context, i) => _buildResultCard(filtered[i]),
          ),
        ),
      ],
    );
  }

  Widget _buildIdleState() {
    final s = context.read<LocaleProvider>().strings;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.emoji_events_outlined,
                color: Colors.white.withOpacity(0.12), size: 72),
            const SizedBox(height: 20),
            Text(
              s.searchInRankings,
              style: const TextStyle(
                color: Colors.white38,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              s.youCanType,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.2), fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final s = context.read<LocaleProvider>().strings;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off_rounded,
                color: Colors.white24, size: 56),
            const SizedBox(height: 14),
            Text(
              s.noRankingAthleteResults,
              style: const TextStyle(
                  color: Colors.white38,
                  fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFiltersBar(int count) {
    final s = context.read<LocaleProvider>().strings;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Contador
          Text(
            s.rankingAthleteResultsCount(count),
            style: const TextStyle(
              color: Color(0xFFE74C3C),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),

          // Chips de filtros
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Filtro año
                ..._availableYears.map((year) => _buildFilterChip(
                      label: year,
                      isSelected: _filterYear == year,
                      onTap: () => setState(() =>
                          _filterYear = _filterYear == year ? null : year),
                    )),
                if (_availableYears.isNotEmpty) const SizedBox(width: 8),
                // Filtro género
                _buildFilterChip(
                  label: s.women,
                  isSelected: _filterGender == 'F',
                  onTap: () => setState(() =>
                      _filterGender = _filterGender == 'F' ? null : 'F'),
                ),
                const SizedBox(width: 6),
                _buildFilterChip(
                  label: s.men,
                  isSelected: _filterGender == 'M',
                  onTap: () => setState(() =>
                      _filterGender = _filterGender == 'M' ? null : 'M'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(right: 6),
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFE74C3C).withOpacity(0.15)
              : Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFE74C3C).withOpacity(0.4)
                : Colors.white.withOpacity(0.1),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? const Color(0xFFE74C3C) : Colors.white54,
            fontSize: 12,
            fontWeight:
                isSelected ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  Widget _buildResultCard(RankingAthleteSearchResult r) {
    final windVal = r.wind != null ? double.tryParse(r.wind!) : null;
    final windIsInvalid = windVal != null && windVal.abs() > 2.0;
    final windColor = windIsInvalid
        ? Colors.orangeAccent
        : (windVal != null && windVal > 0)
            ? const Color(0xFF5DCA88)
            : Colors.white54;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0E1018),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Posición
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFFE74C3C).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: const Color(0xFFE74C3C).withOpacity(0.2)),
              ),
              child: Center(
                child: Text(
                  '#${r.rankPosition}',
                  style: const TextStyle(
                    color: Color(0xFFE74C3C),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Info principal
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nombre atleta
                  Text(
                    r.athleteNameFormatted,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),

                  // Club
                  if (r.club != null && r.club!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Text(
                        r.club!,
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 11,
                        ),
                      ),
                    ),

                  // Disciplina
                  Text(
                    r.discipline,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Ranking label (Damas · Mayores · 2026)
                  Row(
                    children: [
                      _buildMicroBadge(
                          r.genderLabel == 'Damas' ? 'F' : 'V',
                          const Color(0xFF5D9ECA)),
                      const SizedBox(width: 4),
                      _buildMicroBadge(r.categoryLabel, Colors.white30),
                      const SizedBox(width: 4),
                      _buildMicroBadge('${r.year}', Colors.white24),
                    ],
                  ),

                  // Competencia + fecha
                  if (r.competitionName != null ||
                      r.formattedCompetitionDate != null) ...[
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Icon(Icons.emoji_events_outlined,
                            color: Colors.white24, size: 11),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            [
                              r.competitionName,
                              r.formattedCompetitionDate
                            ]
                                .whereType<String>()
                                .join(' · '),
                            style: const TextStyle(
                              color: Colors.white30,
                              fontSize: 10,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // Marca + viento
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  r.displayMark,
                  style: TextStyle(
                    color: r.isWindAssisted
                        ? Colors.orangeAccent
                        : Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                if (r.wind != null) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: windColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(
                          color: windColor.withOpacity(0.3), width: 1),
                    ),
                    child: Text(
                      r.wind!,
                      style: TextStyle(
                        color: windColor,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMicroBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
