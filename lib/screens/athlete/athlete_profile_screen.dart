import 'package:flutter/material.dart';
import '../../models/athlete_profile.dart';
import '../../services/athlete_service.dart';

class AthleteProfileScreen extends StatefulWidget {
  final String athleteId;
  final String name;

  const AthleteProfileScreen({
    super.key,
    required this.athleteId,
    required this.name,
  });

  @override
  State<AthleteProfileScreen> createState() => _AthleteProfileScreenState();
}

class _AthleteProfileScreenState extends State<AthleteProfileScreen> {
  final _service = AthleteService();
  AthleteProfile? _profile;
  bool _loading = true;
  bool _notFound = false;

  static const _bg     = Color(0xFF040512);
  static const _card   = Color(0xFF1A1B2E);
  static const _accent = Color(0xFFE74C3C);
  static const _green = Color(0xFF4CAF93);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final p = await _service.getProfile(widget.name);
      if (mounted) setState(() { _profile = p; _loading = false; });
    } on AthleteNotFoundException {
      if (mounted) setState(() { _notFound = true; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _loading = false; });
    }
  }

  // ── helpers ───────────────────────────────────────────────────────────────

  String _titleCase(String s) => s
      .split(' ')
      .map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1).toLowerCase())
      .join(' ');

  String _shortDiscipline(String d) {
    final n = d.toUpperCase();
    if (n.contains('100') && n.contains('VALLA')) return '100V';
    if (n.contains('110') && n.contains('VALLA')) return '110V';
    if (n.contains('400') && n.contains('VALLA')) return '400V';
    if (n.contains('60'))   return '60M';
    if (n.contains('100'))  return '100M';
    if (n.contains('200'))  return '200M';
    if (n.contains('400'))  return '400M';
    if (n.contains('800'))  return '800M';
    if (n.contains('1500')) return '1500M';
    if (n.contains('5000')) return '5KM';
    if (n.contains('10000'))return '10KM';
    if (n.contains('LONGITUD') || n.contains('LARGO')) return 'SL';
    if (n.contains('GARROCHA') || n.contains('PÉRTIGA')) return 'SG';
    if (n.contains('ALTURA') || n.contains('ALTO')) return 'SA';
    if (n.contains('TRIPLE')) return 'ST';
    if (n.contains('BALA') || n.contains('IMPULS')) return 'IB';
    if (n.contains('DISCO')) return 'DIS';
    if (n.contains('JABALINA')) return 'JAB';
    if (n.contains('MARTILLO')) return 'MAR';
    return d.length > 5 ? d.substring(0, 5) : d;
  }

  String _formatShortDate(String raw) {
    try {
      final d = DateTime.parse(raw);
      final m = d.month.toString().padLeft(2, '0');
      final day = d.day.toString().padLeft(2, '0');
      return '$day/$m/${d.year.toString().substring(2)}';
    } catch (_) { return raw; }
  }

  String _formatFullDate(String raw) {
    try {
      final d = DateTime.parse(raw);
      const months = ['ene','feb','mar','abr','may','jun','jul','ago','sep','oct','nov','dic'];
      return '${d.day} ${months[d.month - 1]} ${d.year}';
    } catch (_) { return raw; }
  }

  int _calcAge(DateTime birth) {
    final t = DateTime.now();
    int a = t.year - birth.year;
    if (t.month < birth.month || (t.month == birth.month && t.day < birth.day)) a--;
    return a;
  }

  String _genderLabel(String? g) => g == 'F' ? 'Damas' : g == 'M' ? 'Varones' : '';

  String _flagEmoji(String code) {
    const flags = {
      'PER': '🇵🇪', 'COL': '🇨🇴', 'VEN': '🇻🇪', 'ECU': '🇪🇨',
      'CHI': '🇨🇱', 'BOL': '🇧🇴', 'ARG': '🇦🇷', 'BRA': '🇧🇷',
      'URU': '🇺🇾', 'PAR': '🇵🇾', 'USA': '🇺🇸', 'ESP': '🇪🇸',
    };
    return flags[code] ?? code;
  }

  Widget _buildFlagWidget(String country) {
    Widget inner;
    switch (country) {
      case 'PER': // Rojo | Blanco | Rojo (vertical)
        inner = Row(children: [
          Expanded(child: Container(color: const Color(0xFFD91023))),
          Expanded(child: Container(color: Colors.white)),
          Expanded(child: Container(color: const Color(0xFFD91023))),
        ]);
        break;
      case 'COL': case 'ECU': // Amarillo(50%) | Azul | Rojo (horizontal)
        inner = Column(children: [
          Expanded(flex: 2, child: Container(color: const Color(0xFFFCD116))),
          Expanded(child: Container(color: const Color(0xFF003087))),
          Expanded(child: Container(color: const Color(0xFFCE1126))),
        ]);
        break;
      case 'VEN': // Amarillo | Azul | Rojo (horizontal)
        inner = Column(children: [
          Expanded(child: Container(color: const Color(0xFFEFCC00))),
          Expanded(child: Container(color: const Color(0xFF00247D))),
          Expanded(child: Container(color: const Color(0xFFCF142B))),
        ]);
        break;
      case 'BOL': // Rojo | Amarillo | Verde (horizontal)
        inner = Column(children: [
          Expanded(child: Container(color: const Color(0xFFD52B1E))),
          Expanded(child: Container(color: const Color(0xFFF4C430))),
          Expanded(child: Container(color: const Color(0xFF007A3D))),
        ]);
        break;
      case 'ARG': // Celeste | Blanco | Celeste (horizontal)
        inner = Column(children: [
          Expanded(child: Container(color: const Color(0xFF74ACDF))),
          Expanded(child: Container(color: Colors.white)),
          Expanded(child: Container(color: const Color(0xFF74ACDF))),
        ]);
        break;
      default:
        inner = Center(child: Text(_flagEmoji(country), style: const TextStyle(fontSize: 42)));
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(width: 84, height: 62, child: inner),
    );
  }

  String _categoryShort(String? c) {
    const map = {'U18':'Sub 18','U20':'Sub 20','U23':'Sub 23','MAYORES':'Mayores','MASTER':'Máster'};
    return map[c] ?? (c ?? '');
  }

  Color _posColor(int pos) {
    if (pos == 1) return const Color(0xFFFFD700);
    if (pos == 2) return const Color(0xFFB0BEC5);
    if (pos == 3) return const Color(0xFFCD7F32);
    return Colors.white70;
  }

  // ── build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: _bg,
        body: Column(
          children: [
            _buildHeaderContainer(null),
            const Expanded(child: Center(child: CircularProgressIndicator(color: _accent))),
          ],
        ),
      );
    }
    if (_notFound) return _buildNotFound();
    return _buildContent();
  }

  Widget _buildContent() {
    final id = _profile?.identity;
    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        children: [
          _buildHeaderContainer(id),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(14, 14, 14, 24 + MediaQuery.of(context).padding.bottom),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if ((_profile?.bestMarks ?? []).isNotEmpty)
                    _buildStatsRow(),
                  if ((_profile?.nationalRecords ?? []).isNotEmpty)
                    _buildSection(
                      title: 'Récords nacionales',
                      accentColor: const Color(0xFFFFD700),
                      child: _buildNationalRecordsList(),
                    ),
                  if ((_profile?.bestMarks ?? []).isNotEmpty)
                    _buildSection(
                      title: 'Marcas personales',
                      accentColor: _green,
                      child: _buildBestMarksList(),
                    ),
                  if ((_profile?.rankings ?? []).isNotEmpty)
                    _buildSection(
                      title: 'Rankings nacionales',
                      accentColor: _accent,
                      child: _buildRankingsList(),
                    ),
                  if ((_profile?.timeline ?? []).isNotEmpty)
                    _buildTimelineSection(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeaderContainer(AthleteIdentity? id) {
    final displayName = id?.canonicalName ?? widget.name;
    final gender      = _genderLabel(id?.gender);
    final category    = _categoryShort(id?.ageCategory);
    final country     = id?.country ?? '';
    final club        = id?.club ?? '';

    // Split: first 2 words = nombres, rest = apellidos
    final words    = displayName.trim().split(RegExp(r'\s+'));
    final nameLine1 = _titleCase(words.take(2).join(' '));
    final nameLine2 = words.length > 2 ? _titleCase(words.skip(2).join(' ')) : '';

    int? age;
    String? birthStr;
    final birthRaw = id?.birthDate;
    if (birthRaw != null && birthRaw.isNotEmpty) {
      try {
        final d = DateTime.parse(birthRaw);
        age = _calcAge(d);
        const months = ['ene','feb','mar','abr','may','jun','jul','ago','sep','oct','nov','dic'];
        birthStr = '${d.day} ${months[d.month - 1]} ${d.year}';
      } catch (_) {}
    }

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/botomevent.jpg'),
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity(0.25),
              Colors.black.withOpacity(0.65),
              _bg,
            ],
            stops: const [0.0, 0.6, 1.0],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── top bar ──────────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 38, height: 38,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
                      ),
                    ),
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Image.asset('assets/images/fdpa_logo.png', width: 28, height: 34, fit: BoxFit.cover),
                        ),
                        const SizedBox(width: 8),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Federación Deportiva',   style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600, height: 1.2)),
                            Text('Peruana de Atletismo',   style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w400, height: 1.2)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                // ── nombre + bandera ──────────────────────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Izquierda: 2 nombres / 2 apellidos / nacimiento
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(nameLine1,
                              style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800, height: 1.05, letterSpacing: -0.5, decoration: TextDecoration.none)),
                          if (nameLine2.isNotEmpty)
                            Text(nameLine2,
                                style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800, height: 1.05, letterSpacing: -0.5, decoration: TextDecoration.none)),
                          if (birthStr != null) ...[
                            const SizedBox(height: 8),
                            Text('Nacimiento: $birthStr',
                                style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 12, fontWeight: FontWeight.w500)),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Derecha: bandera + club·país
                    if (country.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _buildFlagWidget(country),
                          const SizedBox(height: 5),
                          Text(
                            club.isNotEmpty ? '$club · $country' : country,
                            style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                  ],
                ),
                // ── categoría + género + edad ─────────────────────────────
                if (category.isNotEmpty || gender.isNotEmpty || age != null) ...[
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (category.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00BCD4),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            category.toUpperCase(),
                            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -0.3),
                          ),
                        ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (gender.isNotEmpty)
                            Text(gender, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                          if (age != null)
                            Text('$age años', style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 13)),
                        ],
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Stats row ─────────────────────────────────────────────────────────────

  Widget _buildMarkRow({required String label, required String mark, required Color color, double fontSize = 24}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 28,
          padding: const EdgeInsets.symmetric(vertical: 3),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(5),
          ),
          alignment: Alignment.center,
          child: Text(label, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.4)),
        ),
        const SizedBox(width: 8),
        Text(
          mark,
          style: TextStyle(color: color, fontSize: fontSize, fontWeight: FontWeight.w800, height: 1),
        ),
      ],
    );
  }

  Widget _buildStatsRow() {
    final marks = _profile?.bestMarks ?? [];
    if (marks.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: IntrinsicHeight(
        child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: marks.take(2).toList().asMap().entries.map((e) {
          final m   = e.value;
          final hasSb = m.sb != null && m.sb!.mark.isNotEmpty && m.sb!.mark != m.mark && m.sb!.mark != '-';
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(left: e.key == 0 ? 0 : 8),
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              decoration: BoxDecoration(
                color: _card,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: _green.withOpacity(0.18)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _titleCase(m.discipline),
                    style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 10),
                  if (hasSb)
                    Row(
                      children: [
                        _buildMarkRow(label: 'PB', mark: m.mark, color: _green),
                        Container(width: 1, height: 28, color: Colors.white.withOpacity(0.1), margin: const EdgeInsets.symmetric(horizontal: 12)),
                        _buildMarkRow(label: 'SB', mark: m.sb!.mark, color: const Color(0xFF64B5F6)),
                      ],
                    )
                  else
                    _buildMarkRow(label: 'PB', mark: m.mark, color: _green),
                ],
              ),
            ),
          );
        }).toList(),
        ),
      ),
    );
  }

  // ── Section wrapper ───────────────────────────────────────────────────────

  Widget _buildSection({
    required String title,
    Color? accentColor,
    required Widget child,
  }) {
    final dot = accentColor ?? _accent;
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 4, height: 22, decoration: BoxDecoration(color: dot, borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 10),
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(18)),
            clipBehavior: Clip.hardEdge,
            child: child,
          ),
        ],
      ),
    );
  }

  // ── Marcas personales ─────────────────────────────────────────────────────

  Widget _buildBestMarksList() {
    final marks = _profile!.bestMarks;
    return Column(
      children: marks.asMap().entries.map((e) {
        final m    = e.value;
        final even = e.key.isEven;
        final wind = (m.wind != null && m.wind!.isNotEmpty && m.wind != '0' && m.wind != 'null') ? m.wind! : null;
        return Container(
          color: even ? const Color(0xFF1E2036) : const Color(0xFF161726),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_titleCase(m.discipline),
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(
                      [if (m.competition != null) m.competition!, if (m.date != null) _formatFullDate(m.date!)].join(' · '),
                      style: TextStyle(color: Colors.white.withOpacity(0.38), fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildMarkRow(label: 'PB', mark: m.mark, color: _green, fontSize: 17),
                  if (wind != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(wind, style: const TextStyle(color: Color(0xFF4CAF93), fontSize: 11, fontWeight: FontWeight.w600)),
                    ),
                  if (m.sb != null && m.sb!.mark.isNotEmpty && m.sb!.mark != '-') ...[
                    const SizedBox(height: 6),
                    _buildMarkRow(label: 'SB', mark: m.sb!.mark, color: const Color(0xFF64B5F6), fontSize: 17),
                    if (m.sb!.wind != null && m.sb!.wind!.isNotEmpty && m.sb!.wind != 'null')
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(m.sb!.wind!, style: const TextStyle(color: Color(0xFF64B5F6), fontSize: 11, fontWeight: FontWeight.w600)),
                      ),
                  ],
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ── Rankings ──────────────────────────────────────────────────────────────

  Widget _buildRankingsList() {
    final rankings = _profile!.rankings;
    return Column(
      children: rankings.asMap().entries.map((e) {
        final r    = e.value;
        final even = e.key.isEven;
        final c    = _posColor(r.position);
        return Container(
          color: even ? const Color(0xFF1E2036) : const Color(0xFF161726),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(color: c.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                child: Center(child: Text('${r.position}°', style: TextStyle(color: c, fontSize: 13, fontWeight: FontWeight.w800))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_titleCase(r.discipline), style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 3),
                    Text('${r.category} · ${r.year}', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(r.mark, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ── Récords nacionales ────────────────────────────────────────────────────

  Widget _buildNationalRecordsList() {
    final records = _profile!.nationalRecords;
    return Column(
      children: records.asMap().entries.map((e) {
        final r    = e.value;
        final even = e.key.isEven;
        final wind = (r.wind != null && r.wind!.isNotEmpty && r.wind != '0' && r.wind != 'null') ? r.wind! : null;
        return Container(
          color: even ? const Color(0xFF1E2036) : const Color(0xFF161726),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_titleCase(r.discipline),
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(
                      '${r.category}${r.place != null ? ' · ${r.place}' : ''}${r.date != null ? ' · ${_formatFullDate(r.date!)}' : ''}',
                      style: TextStyle(color: Colors.white.withOpacity(0.38), fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(r.mark, style: const TextStyle(color: Color(0xFFFFD700), fontSize: 28, fontWeight: FontWeight.w800, height: 1)),
                  if (wind != null)
                    Text(wind, style: const TextStyle(color: Color(0xFFFFD700), fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ── Timeline ──────────────────────────────────────────────────────────────

  Widget _buildTimelineSection() {
    final entries = (_profile?.timeline ?? []).take(10).toList();
    final pbMarks = {for (final m in _profile?.bestMarks ?? []) m.discipline: m.mark};

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 4, height: 22, decoration: BoxDecoration(color: _accent, borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 10),
              const Text('Historial de competencias', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(18)),
            clipBehavior: Clip.hardEdge,
            child: Column(
              children: entries.asMap().entries.map((e) {
                final t         = e.value;
                final isLast    = e.key == entries.length - 1;
                final isPB      = pbMarks[t.discipline] == t.mark;
                final hasStatus = t.status != null && t.status!.isNotEmpty;
                final windText  = (t.wind != null && t.wind!.isNotEmpty && t.wind != 'null')
                    ? t.wind! : '';
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 52,
                            child: Text(_formatShortDate(t.date),
                                style: TextStyle(color: Colors.white.withOpacity(0.38), fontSize: 11)),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_titleCase(t.discipline),
                                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                                if (t.competition != null && t.competition!.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(t.competition!,
                                      style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 11),
                                      maxLines: 1, overflow: TextOverflow.ellipsis),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (isPB && !hasStatus)
                                    Container(
                                      margin: const EdgeInsets.only(right: 6),
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(color: _accent, borderRadius: BorderRadius.circular(5)),
                                      child: const Text('PB', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800)),
                                    ),
                                  Text(
                                    hasStatus ? (t.status ?? '–') : t.mark,
                                    style: TextStyle(
                                      color: hasStatus ? Colors.white38 : Colors.white,
                                      fontSize: 14, fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                              if (windText.isNotEmpty)
                                Text(windText, style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 10)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (!isLast) Divider(color: Colors.white.withOpacity(0.06), height: 1),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ── Not found ─────────────────────────────────────────────────────────────

  Widget _buildNotFound() {
    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        children: [
          _buildHeaderContainer(null),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.person_search, color: Colors.white24, size: 56),
                    const SizedBox(height: 16),
                    const Text('Perfil no encontrado',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Text(
                      'No se encontraron registros para este atleta.',
                      style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat {
  final String label;
  final String value;
  final Color color;
  const _Stat(this.label, this.value, this.color);
}

