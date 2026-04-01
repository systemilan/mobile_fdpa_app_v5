import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_strings.dart';
import '../../models/ranking.dart';
import '../../providers/locale_provider.dart';
import '../../services/ranking_service.dart';

class RankingDetailScreen extends StatefulWidget {
  /// Cabecera con metadata del ranking (para mostrar header inmediatamente)
  final RankingMaster ranking;

  const RankingDetailScreen({super.key, required this.ranking});

  @override
  State<RankingDetailScreen> createState() => _RankingDetailScreenState();
}

class _RankingDetailScreenState extends State<RankingDetailScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final RankingService _service = RankingService();
  RankingDetail? _detail;
  bool _isLoading = true;
  String? _errorMessage;

  // Búsqueda de atletas
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Control de disciplinas expandidas/colapsadas
  final Set<int> _expandedDisciplines = {};
  bool _allExpanded = false;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _loadDetail();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final detail = await _service.getRankingDetail(widget.ranking.id);
      if (mounted) {
        // Expandir la primera disciplina por defecto
        final expanded = <int>{};
        if (detail.disciplines.isNotEmpty) {
          expanded.add(0);
        }
        setState(() {
          _detail = detail;
          _expandedDisciplines.addAll(expanded);
          _isLoading = false;
        });
        _fadeController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  // ─── Filtrado por búsqueda ───────────────────────────────────────────────

  /// Retorna disciplinas filtradas según [_searchQuery]
  List<RankingDiscipline> get _filteredDisciplines {
    if (_detail == null) return [];
    final q = _searchQuery.trim().toLowerCase();
    if (q.isEmpty) return _detail!.disciplines;

    // Tokenized: el usuario puede escribir "Milan Ditxon" → tokens ["milan","ditxon"]
    final tokens = q.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();

    return _detail!.disciplines
        .map((d) {
          final matchedEntries = d.entries.where((e) {
            final name = e.athleteName.toLowerCase();
            return tokens.every((t) => name.contains(t));
          }).toList();
          return RankingDiscipline(
            name: d.name,
            disciplineOrder: d.disciplineOrder,
            entries: matchedEntries,
          );
        })
        .where((d) => d.entries.isNotEmpty)
        .toList();
  }

  bool get _isSearching => _searchQuery.trim().length >= 2;

  // ─── Build ───────────────────────────────────────────────────────────────

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
                          child: _buildBody(),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Header ─────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    final r = widget.ranking;
    final isArchived = r.isArchived;
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        minHeight: MediaQuery.of(context).size.height * 0.20,
        maxHeight: MediaQuery.of(context).size.height * 0.32,
      ),
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/botom3.jpg'),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xCC040512),
              Color(0xF5040512),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back + acciones
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(19),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new,
                            color: Colors.white, size: 18),
                      ),
                    ),
                    if (_detail != null)
                      GestureDetector(
                        onTap: _toggleAllDisciplines,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.12)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _allExpanded
                                    ? Icons.unfold_less_rounded
                                    : Icons.unfold_more_rounded,
                                color: Colors.white60,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _allExpanded
                                    ? context.read<LocaleProvider>().strings.collapse
                                    : context.read<LocaleProvider>().strings.expandAll,
                                style: const TextStyle(
                                  color: Colors.white60,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                // Badge status
                Row(
                  children: [
                    _buildHeaderBadge(
                      '${r.genderLabel} · ${r.categoryLabel}',
                      const Color(0xFFE74C3C),
                    ),
                    const SizedBox(width: 6),
                    _buildHeaderBadge(
                      isArchived
                          ? context.read<LocaleProvider>().strings.rankingHistoric
                          : context.read<LocaleProvider>().strings.rankingActive,
                      isArchived ? Colors.white38 : const Color(0xFF2ECC71),
                      filled: false,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // Año
                Text(
                  '${r.year}',
                  style: const TextStyle(
                    color: Color(0xFFE74C3C),
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    height: 1,
                    letterSpacing: -1,
                  ),
                ),
                Flexible(
                  child: Text(
                    r.label,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  context.read<LocaleProvider>().strings.rankingPublishedOn(r.formattedPublishedAt),
                  style: const TextStyle(
                    color: Colors.white30,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderBadge(String text, Color color, {bool filled = true}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: filled ? color.withOpacity(0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.4), width: 1),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  // ─── Body ────────────────────────────────────────────────────────────────

  Widget _buildBody() {
    return Column(
      children: [
        _buildSearchBar(),
        Expanded(child: _buildDisciplinesList()),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            const Icon(Icons.search, color: Colors.white38, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: context.read<LocaleProvider>().strings.searchAthleteHint,
                  hintStyle: TextStyle(
                      color: Colors.white.withOpacity(0.3), fontSize: 13),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                onChanged: (v) => setState(() => _searchQuery = v),
              ),
            ),
            if (_searchQuery.isNotEmpty)
              GestureDetector(
                onTap: () {
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                },
                child: const Icon(Icons.clear, color: Colors.white38, size: 18),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDisciplinesList() {
    final disciplines = _filteredDisciplines;

    if (disciplines.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off_rounded,
                color: Colors.white24, size: 48),
            const SizedBox(height: 14),
            Text(
              _isSearching
                  ? context.read<LocaleProvider>().strings.noAthletesForQuery(_searchQuery)
                  : context.read<LocaleProvider>().strings.noDisciplinesAvailable,
              style:
                  const TextStyle(color: Colors.white38, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Contador de resultados en búsqueda
    int totalEntries = disciplines.fold(0, (s, d) => s + d.entries.length);

    return RefreshIndicator(
      onRefresh: _loadDetail,
      color: const Color(0xFFE74C3C),
      backgroundColor: const Color(0xFF1A1A2E),
      strokeWidth: 2.5,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: disciplines.length + (_isSearching ? 1 : 0),
        itemBuilder: (context, index) {
          // Mostrar contador cuando hay búsqueda activa
          if (_isSearching && index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                context.read<LocaleProvider>().strings.rankingResultsSummary(totalEntries, disciplines.length),
                style: const TextStyle(
                  color: Color(0xFFE74C3C),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }
          final dIndex = _isSearching ? index - 1 : index;
          final discipline = disciplines[dIndex];
          return _buildDisciplineSection(discipline, dIndex);
        },
      ),
    );
  }

  Widget _buildDisciplineSection(RankingDiscipline discipline, int index) {
    final isExpanded = _isSearching || _expandedDisciplines.contains(index);
    final entryCount = discipline.entries.length;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0E1018),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        children: [
          // Encabezado de disciplina (tap para expandir/colapsar)
          GestureDetector(
            onTap: _isSearching
                ? null
                : () {
                    setState(() {
                      if (_expandedDisciplines.contains(index)) {
                        _expandedDisciplines.remove(index);
                      } else {
                        _expandedDisciplines.add(index);
                      }
                      _allExpanded = false;
                    });
                  },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.vertical(
                  top: const Radius.circular(14),
                  bottom: isExpanded ? Radius.zero : const Radius.circular(14),
                ),
              ),
              child: Row(
                children: [
                  // Número de disciplina
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE74C3C).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Color(0xFFE74C3C),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      discipline.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Contador
                  Text(
                    context.read<LocaleProvider>().strings.athleteCount(entryCount),
                    style: const TextStyle(
                      color: Colors.white30,
                      fontSize: 11,
                    ),
                  ),
                  if (!_isSearching) ...[
                    const SizedBox(width: 6),
                    Icon(
                      isExpanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: Colors.white30,
                      size: 20,
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Entradas
          if (isExpanded) ...[
            Container(
              height: 1,
              color: Colors.white.withOpacity(0.05),
            ),
            // Cabecera de columnas
            _buildColumnHeader(discipline),
            // Filas de atletas
            ...discipline.entries.asMap().entries.map((e) =>
                _buildEntryRow(e.value, e.key, discipline.entries.length)),
            const SizedBox(height: 6),
          ],
        ],
      ),
    );
  }

  Widget _buildColumnHeader(RankingDiscipline discipline) {
    // Detectar si alguna entrada tiene viento
    final hasWind = discipline.entries.any((e) => e.wind != null);
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
      child: Row(
        children: [
          // POS
          SizedBox(
            width: 32,
            child: Text(context.read<LocaleProvider>().strings.rankingPos.toUpperCase(),
                style: _colHeaderStyle(), textAlign: TextAlign.center),
          ),
          const SizedBox(width: 8),
          // ATLETA
          Expanded(
            child: Text(context.read<LocaleProvider>().strings.rankingAthleta.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white24,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                )),
          ),
          // MARCA
          SizedBox(
            width: 68,
            child: Text(context.read<LocaleProvider>().strings.rankingMark.toUpperCase(),
                style: _colHeaderStyle(), textAlign: TextAlign.right),
          ),
          if (hasWind) ...[
            const SizedBox(width: 6),
            SizedBox(
              width: 52,
              child: Text(context.read<LocaleProvider>().strings.rankingWind.toUpperCase(),
                  style: _colHeaderStyle(), textAlign: TextAlign.right),
            ),
          ],
        ],
      ),
    );
  }

  TextStyle _colHeaderStyle() => const TextStyle(
        color: Colors.white24,
        fontSize: 9,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
      );

  Widget _buildEntryRow(RankingEntry entry, int index, int total) {
    // Detectar si la disciplina padre tiene viento
    // (llamado desde _buildDisciplineSection que ya sabe la disciplina)
    final pos = entry.rankPosition;
    final isFirst = pos == 1;
    final isSecond = pos == 2;
    final isThird = pos == 3;

    final Color posColor;
    if (isFirst) {
      posColor = const Color(0xFFFFD700); // oro
    } else if (isSecond) {
      posColor = const Color(0xFFC0C0C0); // plata
    } else if (isThird) {
      posColor = const Color(0xFFCD7F32); // bronce
    } else {
      posColor = Colors.white30;
    }

    final bool isLastRow = index == total - 1;

    return Column(
      children: [
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isFirst
                ? const Color(0xFFFFD700).withOpacity(0.04)
                : Colors.transparent,
          ),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // POS badge
                  SizedBox(
                    width: 32,
                    child: Center(
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: posColor.withOpacity(
                              (isFirst || isSecond || isThird) ? 0.15 : 0.06),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Center(
                          child: Text(
                            '$pos',
                            style: TextStyle(
                              color: posColor,
                              fontSize:
                                  (isFirst || isSecond || isThird) ? 13 : 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Atleta + club
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.athleteNameFormatted,
                          style: TextStyle(
                            color: isFirst ? Colors.white : Colors.white.withOpacity(0.87),
                            fontSize: 13,
                            fontWeight: isFirst
                                ? FontWeight.w700
                                : FontWeight.w500,
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (entry.club != null && entry.club!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            entry.club!,
                            style: const TextStyle(
                              color: Colors.white30,
                              fontSize: 10,
                              height: 1.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // MARCA
                  SizedBox(
                    width: 68,
                    child: Text(
                      _formatMark(entry.mark),
                      style: TextStyle(
                        color: isFirst
                            ? const Color(0xFFFFD700)
                            : Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        fontFeatures: const [
                          FontFeature.tabularFigures(),
                        ],
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                  // VIENTO (solo si tiene valor)
                  if (entry.wind != null) ...[
                    const SizedBox(width: 6),
                    SizedBox(
                      width: 52,
                      child: _buildWindBadge(entry.wind!),
                    ),
                  ],
                ],
              ),
              // Segunda línea: campeonato + fecha (si existen)
              if (entry.competitionName != null ||
                  entry.formattedCompetitionDate != null)
                Padding(
                  padding: const EdgeInsets.only(top: 5, left: 40),
                  child: Row(
                    children: [
                      const Icon(Icons.emoji_events_outlined,
                          color: Colors.white24, size: 11),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          [
                            if (entry.competitionName != null)
                              entry.competitionName!,
                            if (entry.formattedCompetitionDate != null)
                              entry.formattedCompetitionDate!,
                          ].join(' · '),
                          style: const TextStyle(
                            color: Colors.white24,
                            fontSize: 10,
                            height: 1.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // isManual badge
                      if (!entry.isManual) ...[
                        const SizedBox(width: 4),
                        _buildAutoIcon(),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        ),
        if (!isLastRow)
          Container(
            height: 1,
            color: Colors.white.withOpacity(0.04),
          ),
      ],
    );
  }

  Widget _buildWindBadge(String wind) {
    // Normalizar: quitar la palabra VIENTO/viento y espacios extra
    final normalized = wind
        .replaceAll(RegExp(r'viento\s*', caseSensitive: false), '')
        .replaceAll(',', '.')
        .trim();

    // Determinar si el viento es favorable o no
    double? val;
    try {
      val = double.tryParse(normalized);
    } catch (_) {}

    final bool isInvalid = val != null && val.abs() > 2.0;
    final Color windColor = isInvalid
        ? Colors.orangeAccent
        : (val != null && val > 0)
            ? const Color(0xFF5DCA88)
            : Colors.white54;

    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        decoration: BoxDecoration(
          color: windColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: windColor.withOpacity(0.3), width: 1),
        ),
        child: Text(
          normalized,
          style: TextStyle(
            color: windColor,
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }

  Widget _buildAutoIcon() {
    return Tooltip(
      message: context.read<LocaleProvider>().strings.generatedFromEvents,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Icon(Icons.auto_awesome_rounded,
            color: Colors.blue, size: 9),
      ),
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
              onPressed: _loadDetail,
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

  // ─── Acciones ────────────────────────────────────────────────────────────

  /// Formatea la marca siempre con 2 decimales.
  /// Si el valor es numérico (ej: "14.5" → "14.50", "1:23.4" → sin cambio).
  String _formatMark(String mark) {
    // Marcas con formato tiempo (hh:mm:ss o mm:ss.xx) no se tocan
    if (mark.contains(':')) return mark;
    final val = double.tryParse(mark.replaceAll(',', '.'));
    if (val != null) return val.toStringAsFixed(2);
    return mark;
  }

  void _toggleAllDisciplines() {
    if (_detail == null) return;
    setState(() {
      if (_allExpanded) {
        _expandedDisciplines.clear();
        _allExpanded = false;
      } else {
        _expandedDisciplines
            .addAll(List.generate(_detail!.disciplines.length, (i) => i));
        _allExpanded = true;
      }
    });
  }
}
