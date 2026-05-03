import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../results/result_detail_screen_type1.dart';
import '../results/result_detail_screen_type2.dart';
import '../results/result_detail_screen_type3.dart';
import '../../services/event_service.dart';
import '../../services/socket_service.dart';
import '../../models/jornada.dart';
import '../../config/environment.dart';
import '../../l10n/app_strings.dart';
import '../../providers/locale_provider.dart';
import 'athlete_search_sheet.dart';

/// Agrupación de ScheduledTests que comparten la misma prueba (test.id)
class _TestGroup {
  final String key;
  final List<ScheduledTest> tests;
  const _TestGroup({required this.key, required this.tests});

  /// Se muestra como grupo colapsable si hay más de 2 instancias
  bool get isGrouped => tests.length > 2;
  ScheduledTest get first => tests.first;
}

class ChampionshipDetailScreen extends StatefulWidget {
  final String? eventId;
  final String title;
  final String date;
  final String location;

  const ChampionshipDetailScreen({
    super.key,
    this.eventId,
    required this.title,
    required this.date,
    required this.location,
  });

  @override
  State<ChampionshipDetailScreen> createState() => _ChampionshipDetailScreenState();
}

class _ChampionshipDetailScreenState extends State<ChampionshipDetailScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _staggeredController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  // Estado de expansión de jornadas
  int? _expandedJornadaIndex;

  // Grupos de pruebas expandidos dentro de una jornada. Clave: "${jornadaIdx}_${testId}"
  final Set<String> _expandedTestGroups = {};

  // Suscripciones realtime
  final List<StreamSubscription<Map<String, dynamic>>> _socketSubs = [];

  // Estado para jornadas de la API
  final EventService _eventService = EventService();
  List<Jornada> _jornadas = [];
  bool _isLoadingJornadas = true;
  
  // Estado para el evento (incluye información sobre si es histórico)
  Map<String, dynamic>? _eventData;
  bool get _isHistoricalEvent => _eventData?['oldHistory'] == true;
  String get _eventId => _eventData?['id'] ?? widget.eventId ?? '';

  // Resúmenes de pruebas combinadas (decatlón, heptatlón, etc.)
  List<CombinedSummary> _combinedSummaries = [];

  // Animaciones escalonadas para los elementos
  late Animation<double> _headerFadeAnimation;
  late Animation<Offset> _headerSlideAnimation;
  late Animation<double> _titleFadeAnimation;
  late Animation<Offset> _titleSlideAnimation;
  late Animation<double> _searchFadeAnimation;
  late Animation<Offset> _searchSlideAnimation;
  late Animation<double> _jornadasFadeAnimation;
  late Animation<Offset> _jornadasSlideAnimation;

  AppStrings get s => context.read<LocaleProvider>().strings;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _staggeredController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    // Animaciones escalonadas
    _headerFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _staggeredController,
        curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
      ),
    );
    _headerSlideAnimation = Tween<Offset>(begin: const Offset(0, -0.5), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _staggeredController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOutBack),
      ),
    );

    _titleFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _staggeredController,
        curve: const Interval(0.2, 0.5, curve: Curves.easeOut),
      ),
    );
    _titleSlideAnimation = Tween<Offset>(begin: const Offset(-0.3, 0), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _staggeredController,
        curve: const Interval(0.2, 0.6, curve: Curves.easeOutCubic),
      ),
    );

    _searchFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _staggeredController,
        curve: const Interval(0.4, 0.7, curve: Curves.easeOut),
      ),
    );
    _searchSlideAnimation = Tween<Offset>(begin: const Offset(0.3, 0), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _staggeredController,
        curve: const Interval(0.4, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    _jornadasFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _staggeredController,
        curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
      ),
    );
    _jornadasSlideAnimation = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _staggeredController,
        curve: const Interval(0.6, 1.0, curve: Curves.easeOutBack),
      ),
    );

    // Cargar jornadas si hay eventId
    if (widget.eventId != null) {
      _loadJornadas();
    } else {
      setState(() {
        _isLoadingJornadas = false;
      });
    }

    // Suscribir a eventos realtime
    _subscribeToSocket();

    // Iniciar animaciones con delay
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        _fadeController.forward();
        _slideController.forward();
        _staggeredController.forward();
      }
    });
  }

  /// Suscribirse a eventos realtime: recarga jornadas cuando el backend
  /// notifica cambios en pruebas o jornadas de este evento.
  void _subscribeToSocket() {
    final eventId = widget.eventId;
    if (eventId == null) return;
    final socket = SocketService();
    _socketSubs
      ..add(socket.on('eventTest:created').listen((d) {
        if (mounted && d['eventId'] == eventId) _loadJornadas();
      }))
      ..add(socket.on('eventTest:updated').listen((d) {
        if (mounted && d['eventId'] == eventId) _loadJornadas();
      }))
      ..add(socket.on('eventTest:deleted').listen((d) {
        if (mounted) _loadJornadas();
      }))
      ..add(socket.on('eventTest:nameUpdated').listen((d) {
        if (mounted) _loadJornadas();
      }))
      ..add(socket.on('eventJornada:created').listen((d) {
        if (mounted && d['eventId'] == eventId) _loadJornadas();
      }))
      ..add(socket.on('eventJornada:deleted').listen((d) {
        if (mounted) _loadJornadas();
      }));
  }

  /// Cargar jornadas de la API
  Future<void> _loadJornadas() async {
    if (widget.eventId == null) return;
    
    try {
      final response = await _eventService.getEventJornadas(widget.eventId!);
      
      if (mounted) {
        setState(() {
          _jornadas = response.data.jornadas;
          _eventData = response.data.event; // Guardar datos del evento
          _combinedSummaries = response.data.combinedSummaries;
          _isLoadingJornadas = false;
        });
        
        // Log información del evento para debugging
        if (Environment.enableLogs) {
          print('📋 Event loaded: ${_eventData?['shortName']} (oldHistory: ${_eventData?['oldHistory']}, combinedSummaries: ${_combinedSummaries.length})');
        }
      }
    } catch (e) {
      debugPrint('Error cargando jornadas: $e');
      if (mounted) {
        setState(() {
          _isLoadingJornadas = false;
        });
      }
    }
  }

  @override
  void dispose() {
    for (final s in _socketSubs) {
      s.cancel();
    }
    _socketSubs.clear();
    _fadeController.dispose();
    _slideController.dispose();
    _staggeredController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF040512),
      body: SafeArea(
        top: false,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Zona con imagen de fondo ──
                  Stack(
                    children: [
                      // Imagen de fondo
                      SizedBox(
                        width: double.infinity,
                        height: 190 + MediaQuery.of(context).padding.top,
                        child: Image.asset(
                          'assets/images/botomevent.jpg',
                          fit: BoxFit.cover,
                        ),
                      ),
                      // Overlay degradado de abajo hacia arriba
                      Container(
                        height: 190 + MediaQuery.of(context).padding.top,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            stops: [0.0, 0.4, 1.0],
                            colors: [
                              Color(0xCC040512),
                              Color(0xAA040512),
                              Color(0xFF040512),
                            ],
                          ),
                        ),
                      ),
                      // Contenido encima de la imagen
                      SafeArea(
                        bottom: false,
                        child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            FadeTransition(
                              opacity: _headerFadeAnimation,
                              child: SlideTransition(
                                position: _headerSlideAnimation,
                                child: _buildHeader(),
                              ),
                            ),
                            const SizedBox(height: 8),
                            FadeTransition(
                              opacity: _titleFadeAnimation,
                              child: SlideTransition(
                                position: _titleSlideAnimation,
                                child: _buildTitleSection(),
                              ),
                            ),
                            const SizedBox(height: 16),
                            FadeTransition(
                              opacity: _searchFadeAnimation,
                              child: SlideTransition(
                                position: _searchSlideAnimation,
                                child: _buildSearchBox(),
                              ),
                            ),
                          ],
                        ),
                        ),
                      ),
                    ],
                  ),
                  // ── Jornadas (sin imagen) ──
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 10, 10, 20),
                    child: FadeTransition(
                      opacity: _jornadasFadeAnimation,
                      child: SlideTransition(
                        position: _jornadasSlideAnimation,
                        child: _buildJornadasList(),
                      ),
                    ),
                  ),
                  // ── Resúmenes de pruebas combinadas ──
                  if (_combinedSummaries.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(10, 0, 10, 24),
                      child: _buildCombinedSummariesSection(),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: () {
            Navigator.of(context).pop();
          },
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.arrow_back_ios_new,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
        Row(
          children: [
            Container(
              width: 35,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.asset(
                  'assets/images/fdpa_logo.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.federationLine1,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  s.federationLine2,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTitleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Título - 70%
            Expanded(
              flex: 7,
              child: Text(
                widget.title.replaceAll('\n', ' '),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                  letterSpacing: -0.5,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 15),
            // Bandera y ubicación - 30%
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 48,
                    height: 30,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(color: const Color(0xFFD91023)),
                          ),
                          Expanded(
                            child: Container(color: Colors.white),
                          ),
                          Expanded(
                            child: Container(color: const Color(0xFFD91023)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.location,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.end,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          widget.date,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBox() {
    return GestureDetector(
      onTap: () {
        _showSearchDialog();
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            const Icon(
              Icons.search,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(width: 15),
            Text(
              s.enterNameSurname,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJornadasList() {
    // Mostrar loading si está cargando
    if (_isLoadingJornadas) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE74C3C)),
          ),
        ),
      );
    }

    // Si no hay jornadas cargadas, mostrar mensaje
    if (_jornadas.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Text(
            s.noSessionsAvailable,
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 16,
            ),
          ),
        ),
      );
    }

    return Column(
      children: _jornadas.asMap().entries.expand((entry) {
        final index = entry.key;
        final jornada = entry.value;
        final isExpanded = _expandedJornadaIndex == index;
        
        List<Widget> widgets = [
          _buildJornadaCard(
            index,
            jornada.longName,
            jornada.shortName,
            jornada.dateFormatted,
            jornada.tests,
          )
        ];
        
        // Si está expandida, agrupar pruebas por tipo y mostrarlas
        if (isExpanded && jornada.tests.isNotEmpty) {
          final groups = _groupTestsByPrueba(jornada.tests);
          var displayIndex = 0;
          for (final group in groups) {
            final groupKey = '${index}_${group.key}';
            if (group.isGrouped) {
              // Tarjeta colapsable para pruebas con más de 2 categorías
              widgets.add(_buildGroupedTestCard(
                group, displayIndex++,
                groupKey: groupKey,
                jornadaDate: jornada.date,
              ));
              if (_expandedTestGroups.contains(groupKey)) {
                widgets.addAll(
                  group.tests.asMap().entries.map((e) =>
                    _buildTestSubItemRow(e.value, e.key, jornadaDate: jornada.date),
                  ),
                );
              }
            } else {
              // Mostrar individualmente si son 1 o 2 instancias
              for (final t in group.tests) {
                widgets.add(_buildAnimatedTestCard(t, displayIndex++, jornadaDate: jornada.date));
              }
            }
          }
        }
        
        return widgets;
      }).toList(),
    );
  }

  Widget _buildJornadaCard(int index, String titulo, String turno, String fecha, List<ScheduledTest> tests) {
    final isExpanded = _expandedJornadaIndex == index;
    final testCount = tests.length;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isExpanded) {
            _expandedJornadaIndex = null;
          } else {
            _expandedJornadaIndex = index;
          }
        });
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        margin: EdgeInsets.only(bottom: isExpanded ? 5 : 8),
        decoration: BoxDecoration(
          color: isExpanded ? null : Colors.white.withOpacity(0.06),
          gradient: isExpanded 
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFA93226),
                  Color(0xFFC0392B),
                  Color(0xFFE74C3C),
                ],
              )
            : null,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isExpanded ? [
            BoxShadow(
              color: const Color(0xFFC0392B).withOpacity(0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ] : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    titulo,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Transform.rotate(
                  angle: isExpanded ? 1.5708 : 0.0, // 90 grados en radianes
                  child: Icon(
                    Icons.chevron_right,
                    color: Colors.white.withOpacity(0.7),
                    size: 20,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  turno,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                Text(
                  fecha,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Navegación centralizada para reutilizar en cards individuales y sub-items
  // ─────────────────────────────────────────────────────────────────────────

  void _navigateToTest(ScheduledTest test, String jornadaDate) {
    final isHistorical = _isHistoricalEvent || test.id.startsWith('hist-test-');
    final eventIdToPass = isHistorical ? _eventId : null;

    if (Environment.enableLogs) {
      print('🎯 Test clicked: ${test.test.commonName}');
      print('   - Test ID: ${test.id}');
      print('   - Is Historical: $isHistorical');
      print('   - Event ID: $eventIdToPass');
      print('   - Input Format: ${test.test.inputFormat}');
    }

    if (isHistorical) {
      if (test.test.inputFormat == 'tiempo' || test.test.inputFormat == '1' || test.test.type == 'track') {
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => ResultDetailScreenType2(
            eventTestId: test.id, eventId: eventIdToPass, eventDate: jornadaDate)));
      } else if (test.test.inputFormat == 'altura' || test.test.inputFormat == '2') {
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => ResultDetailScreenType3(
            eventTestId: test.id, eventId: eventIdToPass, eventDate: jornadaDate)));
      } else if (test.test.inputFormat == 'intentos' || test.test.inputFormat == '3' || test.test.type == 'field') {
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => ResultDetailScreenType1(
            eventTestId: test.id, eventId: eventIdToPass,
            title: widget.title, date: widget.date, location: widget.location,
            eventName: test.test.officialName, category: test.categoriesFormatted,
            resultDate: widget.date)));
      } else {
        if (test.test.type == 'track') {
          Navigator.push(context, MaterialPageRoute(
            builder: (_) => ResultDetailScreenType2(eventTestId: test.id, eventId: eventIdToPass)));
        } else {
          Navigator.push(context, MaterialPageRoute(
            builder: (_) => ResultDetailScreenType1(
              eventTestId: test.id, eventId: eventIdToPass,
              title: widget.title, date: widget.date, location: widget.location,
              eventName: test.test.officialName, category: test.categoriesFormatted,
              resultDate: widget.date)));
        }
      }
    } else {
      if (test.test.inputFormat == '1') {
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => ResultDetailScreenType2(eventTestId: test.id, eventDate: jornadaDate)));
      } else if (test.test.inputFormat == '2') {
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => ResultDetailScreenType3(eventTestId: test.id, eventDate: jornadaDate)));
      } else if (test.test.inputFormat == '3') {
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => ResultDetailScreenType1(
            eventTestId: test.id, eventId: null,
            title: widget.title, date: widget.date, location: widget.location,
            eventName: test.test.officialName, category: test.categoriesFormatted,
            resultDate: widget.date)));
      } else {
        debugPrint('⚠️ inputFormat desconocido: ${test.test.inputFormat} para ${test.test.commonName}');
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => test.test.type == '2'
              ? ResultDetailScreenType1(
                  eventTestId: test.id, eventId: null,
                  title: widget.title, date: widget.date, location: widget.location,
                  eventName: test.test.officialName, category: test.categoriesFormatted,
                  resultDate: widget.date)
              : ResultDetailScreenType2(eventTestId: test.id, eventDate: jornadaDate)));
      }
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Agrupación de tests
  // ─────────────────────────────────────────────────────────────────────────

  /// Agrupa los ScheduledTests por test.id preservando el orden original.
  List<_TestGroup> _groupTestsByPrueba(List<ScheduledTest> tests) {
    final Map<String, List<ScheduledTest>> map = {};
    for (final t in tests) {
      final key = t.test.id.isNotEmpty ? t.test.id : t.test.officialName;
      (map[key] ??= []).add(t);
    }
    return map.entries.map((e) => _TestGroup(key: e.key, tests: e.value)).toList();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Tarjeta colapsable para grupos con más de 2 categorías
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildGroupedTestCard(
    _TestGroup group,
    int index, {
    required String groupKey,
    String jornadaDate = '',
  }) {
    final isExpanded = _expandedTestGroups.contains(groupKey);
    final first = group.first;
    final count = group.tests.length;

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 200 + (index * 70)),
      tween: Tween<double>(begin: 0.0, end: 1.0),
      curve: Curves.easeOutBack,
      builder: (context, value, _) {
        final v = value.clamp(0.0, 1.0);
        return Transform.translate(
          offset: Offset(0, (1 - v) * 24),
          child: Opacity(
            opacity: v,
            child: Transform.scale(
              scale: 0.85 + 0.15 * v,
              child: GestureDetector(
                onTap: () => setState(() {
                  isExpanded
                      ? _expandedTestGroups.remove(groupKey)
                      : _expandedTestGroups.add(groupKey);
                }),
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 6),
                  decoration: BoxDecoration(
                    color: isExpanded
                        ? const Color(0xFFE74C3C).withOpacity(0.10)
                        : Colors.white.withOpacity(0.06 * v),
                    borderRadius: BorderRadius.circular(16),
                    border: isExpanded
                        ? Border.all(
                            color: const Color(0xFFE74C3C).withOpacity(0.35),
                            width: 1,
                          )
                        : null,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: Row(
                      children: [
                        // Hora
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE74C3C).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            first.time != null && first.time!.length >= 5
                                ? first.time!.substring(0, 5)
                                : '--:--',
                            style: const TextStyle(
                              color: Color(0xFFE74C3C),
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        // Nombre + contador de categorías
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                first.displayedName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE74C3C).withOpacity(0.18),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      '$count categorías',
                                      style: const TextStyle(
                                        color: Color(0xFFE74C3C),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  Builder(builder: (_) {
                                    final ceLongName = group.tests
                                        .map((t) => _getCombinedEventLongName(t.combinedEvent))
                                        .firstWhere((s) => s != null, orElse: () => null);
                                    if (ceLongName == null) return const SizedBox.shrink();
                                    return Padding(
                                      padding: const EdgeInsets.only(left: 6),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFFB300).withOpacity(0.18),
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(
                                            color: const Color(0xFFFFB300).withOpacity(0.55),
                                            width: 1,
                                          ),
                                        ),
                                        child: Text(
                                          ceLongName,
                                          style: const TextStyle(
                                            color: Color(0xFFFFB300),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 0.4,
                                          ),
                                        ),
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Chevron animado
                        AnimatedRotation(
                          turns: isExpanded ? 0.25 : 0,
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeInOut,
                          child: Icon(
                            Icons.chevron_right,
                            color: Colors.white.withOpacity(0.65),
                            size: 22,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Fila individual dentro de un grupo expandido
  Widget _buildTestSubItemRow(ScheduledTest test, int index, {String jornadaDate = ''}) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 120 + (index * 45)),
      tween: Tween<double>(begin: 0.0, end: 1.0),
      curve: Curves.easeOut,
      builder: (context, value, _) {
        final v = value.clamp(0.0, 1.0);
        return Opacity(
          opacity: v,
          child: Transform.translate(
            offset: Offset(16 * (1 - v), 0),
            child: GestureDetector(
              onTap: () => _navigateToTest(test, jornadaDate),
              child: Container(
                margin: const EdgeInsets.only(left: 20, bottom: 5),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.07),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    // Chip categoría
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF13142A),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.12),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        test.categoriesFormatted,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _getGenderLabel(test.genders),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.65),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (test.combinedEvent != null) ...[  
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFB300).withOpacity(0.18),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFFFFB300).withOpacity(0.55),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          _getCombinedEventLongName(test.combinedEvent) ?? '',
                          style: const TextStyle(
                            color: Color(0xFFFFB300),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    ],
                    const Spacer(),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white.withOpacity(0.28),
                      size: 13,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnimatedEventoCard(Map<String, String> evento, int index) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 200 + (index * 80)), // Animación escalonada rápida
      tween: Tween<double>(begin: 0.0, end: 1.0),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        // Asegurar que los valores estén en rango válido
        final clampedValue = value.clamp(0.0, 1.0);
        final opacityValue = clampedValue.clamp(0.0, 1.0);
        final backgroundOpacity = (0.06 * clampedValue).clamp(0.0, 1.0);
        final shadowOpacity = (0.1 * clampedValue).clamp(0.0, 1.0);
        
        return Transform.translate(
          offset: Offset(0, (1 - clampedValue) * 30), // Slide desde abajo
          child: Opacity(
            opacity: opacityValue,
            child: Transform.scale(
              scale: 0.8 + (0.2 * clampedValue), // Scale suave
              child: GestureDetector(
                onTap: () {
                  if (evento['estado'] == 'Resultados cargados') {
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) {
                          if (evento['nombre'] == '800 Metros planos') {
                            return ResultDetailScreenType2(
                              eventTestId: 'static-event-id', // ID temporal para datos estáticos
                              eventId: widget.eventId,
                            );
                          } else if (evento['nombre'] == 'Salto largo') {
                            return ResultDetailScreenType3(
                              eventTestId: 'static-event-id', // ID temporal para datos estáticos
                              eventId: widget.eventId,
                            );
                          } else {
                            // Nota: Este código es para datos estáticos antiguos
                            // TODO: Migrar completamente a la API
                            return ResultDetailScreenType1(
                              eventTestId: 'static-event-id', // ID temporal para datos estáticos
                              eventId: widget.eventId,
                              title: widget.title,
                              date: widget.date,
                              location: widget.location,
                              eventName: evento['nombre']!,
                              category: evento['categoria']!,
                              resultDate: evento['fecha_resultado']!,
                            );
                          }
                        },
                        transitionDuration: const Duration(milliseconds: 800),
                        reverseTransitionDuration: const Duration(milliseconds: 600),
                        transitionsBuilder: (context, animation, secondaryAnimation, child) {
                          // Animación de entrada para la nueva pantalla
                          const slideBegin = Offset(1.0, 0.0);
                          const slideEnd = Offset.zero;
                          const slideCurve = Curves.easeOutCubic;
                          
                          final slideAnimation = Tween(
                            begin: slideBegin,
                            end: slideEnd,
                          ).animate(CurvedAnimation(
                            parent: animation,
                            curve: slideCurve,
                          ));
                          
                          // Animación de fade para la nueva pantalla
                          final fadeAnimation = Tween(
                            begin: 0.0,
                            end: 1.0,
                          ).animate(CurvedAnimation(
                            parent: animation,
                            curve: const Interval(0.2, 1.0, curve: Curves.easeInOut),
                          ));
                          
                          return SlideTransition(
                            position: slideAnimation,
                            child: FadeTransition(
                              opacity: fadeAnimation,
                              child: child,
                            ),
                          );
                        },
                      ),
                    );
                  }
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(backgroundOpacity), // Fade del fondo
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(shadowOpacity),
                        blurRadius: 8 * clampedValue,
                        offset: Offset(0, 4 * clampedValue),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              evento['nombre']!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              evento['categoria']!,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.75),
                                fontSize: 15,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            evento['estado']!,
                            style: TextStyle(
                              color: evento['estado'] == 'Resultados cargados' 
                                ? const Color(0xFF5DCA88)
                                : Colors.white70,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            evento['fecha_resultado']!,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnimatedTestCard(ScheduledTest test, int index, {String jornadaDate = ''}) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 200 + (index * 80)),
      tween: Tween<double>(begin: 0.0, end: 1.0),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        final clampedValue = value.clamp(0.0, 1.0);
        final opacityValue = clampedValue.clamp(0.0, 1.0);
        final backgroundOpacity = (0.06 * clampedValue).clamp(0.0, 1.0);
        final shadowOpacity = (0.1 * clampedValue).clamp(0.0, 1.0);
        
        return Transform.translate(
          offset: Offset(0, (1 - clampedValue) * 30),
          child: Opacity(
            opacity: opacityValue,
            child: Transform.scale(
              scale: 0.8 + (0.2 * clampedValue),
              child: GestureDetector(
                onTap: () => _navigateToTest(test, jornadaDate),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  margin: const EdgeInsets.only(bottom: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(backgroundOpacity),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(shadowOpacity),
                        blurRadius: 8 * clampedValue,
                        offset: Offset(0, 4 * clampedValue),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Hora de la prueba
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE74C3C).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          test.time != null && test.time!.length >= 5 
                            ? test.time!.substring(0, 5) 
                            : (test.time ?? '--:--'), // HH:MM o --:-- si es null
                          style: const TextStyle(
                            color: Color(0xFFE74C3C),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Información de la prueba
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              test.displayedName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              test.categoriesFormatted,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Género + chip combinedEvent encima
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (test.combinedEvent != null) ...[  
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFB300).withOpacity(0.18),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: const Color(0xFFFFB300).withOpacity(0.55),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                _getCombinedEventLongName(test.combinedEvent) ?? '',
                                style: const TextStyle(
                                  color: Color(0xFFFFB300),
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                            const SizedBox(height: 2),
                          ],
                          Text(
                            _getGenderLabel(test.genders),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Obtener shortName de combinedEvent (DEC, TET, etc.)
  String? _getCombinedEventShortName(dynamic combinedEvent) {
    if (combinedEvent == null) return null;
    if (combinedEvent is Map<String, dynamic>) {
      return combinedEvent['shortName'] as String?;
    }
    return null;
  }

  /// Obtener longName de combinedEvent (Decatlón, Tetratlón, etc.)
  String? _getCombinedEventLongName(dynamic combinedEvent) {
    if (combinedEvent == null) return null;
    if (combinedEvent is Map<String, dynamic>) {
      return combinedEvent['longName'] as String?;
    }
    return null;
  }

  /// Obtener el label del género
  String _getGenderLabel(List<Gender> genders) {
    if (genders.isEmpty) return 'N/A';
    if (genders.length == 1) {
      return genders.first.longName; // "Varones" o "Damas"
    }
    return 'Mixto'; // Cuando hay más de un género
  }

  /// Obtener el color según el género
  Color _getGenderColor(List<Gender> genders) {
    if (genders.isEmpty) return Colors.grey;
    if (genders.length == 1) {
      final gender = genders.first.shortName;
      if (gender == 'M') return Colors.blue;
      if (gender == 'F') return Colors.pink;
    }
    return Colors.purple; // Mixto
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Sección de resúmenes de pruebas combinadas (Decatlón / Heptatlón)
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildCombinedSummariesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _combinedSummaries
          .map((summary) => _buildOneCombinedSummary(summary))
          .toList(),
    );
  }

  Widget _buildOneCombinedSummary(CombinedSummary summary) {
    const double posW = 34.0;
    const double minNameW = 162.0;
    final bool showCountry = summary.athletes.any((a) => a.country.isNotEmpty);
    final double countryW = showCountry ? 46.0 : 0.0;
    const double discW = 54.0;
    const double totalW = 68.0;
    const double rowH = 50.0;
    const double headerH = 34.0;

    Color medalColor(int pos) {
      if (pos == 1) return const Color(0xFFFFD700);
      if (pos == 2) return const Color(0xFFB0BEC5);
      if (pos == 3) return const Color(0xFFCD7F32);
      return Colors.white;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1D1F28),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Título de sección ──
          Container(
            color: const Color(0xFF252836),
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 18,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE74C3C),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'RESULTADOS ${summary.longName.toUpperCase()}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE74C3C).withOpacity(0.18),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: const Color(0xFFE74C3C).withOpacity(0.4),
                    ),
                  ),
                  child: Text(
                    summary.shortName,
                    style: const TextStyle(
                      color: Color(0xFFE74C3C),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // ── Tabla scrollable horizontalmente ──
          LayoutBuilder(
            builder: (context, constraints) {
              final double fixedW = posW + countryW + discW * summary.subTests.length + totalW;
              final double nameW = (constraints.maxWidth - fixedW).clamp(minNameW, double.infinity);
              final double tableW = posW + nameW + countryW + discW * summary.subTests.length + totalW;
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: tableW,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildCombinedTableHeader(
                        summary,
                        posW: posW,
                        nameW: nameW,
                        countryW: countryW,
                        discW: discW,
                        totalW: totalW,
                        height: headerH,
                      ),
                      const Divider(color: Colors.white12, height: 1, thickness: 1),
                      ...summary.athletes.map(
                        (athlete) => _buildCombinedAthleteRow(
                          athlete,
                          summary.subTests,
                          medalColor(athlete.finalPosition),
                          posW: posW,
                          nameW: nameW,
                          countryW: countryW,
                          discW: discW,
                          totalW: totalW,
                          height: rowH,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildCombinedTableHeader(
    CombinedSummary summary, {
    required double posW,
    required double nameW,
    required double countryW,
    required double discW,
    required double totalW,
    required double height,
  }) {
    const style = TextStyle(
      color: Colors.white60,
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.3,
    );

    Widget cell(String text, double w, {TextAlign align = TextAlign.center}) =>
        SizedBox(
          width: w,
          height: height,
          child: Center(
            child: Text(text, style: style, textAlign: align),
          ),
        );

    return Container(
      color: const Color(0xFF1A1C24),
      child: Row(
        children: [
          cell('#', posW),
          SizedBox(
            width: nameW,
            height: height,
            child: const Padding(
              padding: EdgeInsets.only(left: 6),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('ATLETA', style: style),
              ),
            ),
          ),
          if (countryW > 0) cell('PAÍS', countryW),
          ...summary.subTests.map(
            (st) => cell(st.shortLabel, discW),
          ),
          cell('TOTAL', totalW),
        ],
      ),
    );
  }

  Widget _buildCombinedAthleteRow(
    CombinedAthlete athlete,
    List<CombinedSubTest> subTests,
    Color posColor, {
    required double posW,
    required double nameW,
    required double countryW,
    required double discW,
    required double totalW,
    required double height,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.06)),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Posición
          SizedBox(
            width: posW,
            height: height,
            child: Center(
              child: Text(
                '${athlete.finalPosition}',
                style: TextStyle(
                  color: posColor,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          // Nombre
          SizedBox(
            width: nameW,
            height: height,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    athlete.nameFormatted,
                    style: TextStyle(
                      color: posColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (athlete.team.isNotEmpty && athlete.team != athlete.country)
                    Text(
                      athlete.team,
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 10,
                      ),
                    ),
                ],
              ),
            ),
          ),
          // País
          if (countryW > 0)
            SizedBox(
              width: countryW,
              height: height,
              child: Center(
                child: Text(
                  athlete.country,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          // Celdas de disciplina
          ...subTests.map((st) {
            final result = athlete.subResults[st.eventTestId];
            final hasPoints = result?.points != null;
            final hasMark = result?.mark != null && result!.mark!.isNotEmpty;
            return SizedBox(
              width: discW,
              height: height,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    hasPoints ? '${result!.points}' : '–',
                    style: TextStyle(
                      color: hasPoints ? Colors.white : Colors.white24,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    hasMark ? result!.mark! : '–',
                    style: TextStyle(
                      color: hasMark ? Colors.white38 : Colors.white12,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            );
          }),
          // Total
          SizedBox(
            width: totalW,
            height: height,
            child: Center(
              child: Text(
                '${athlete.totalPoints}',
                style: TextStyle(
                  color: posColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventoCard(Map<String, String> evento) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  evento['nombre']!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  evento['categoria']!,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.75),
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                evento['estado']!,
                style: TextStyle(
                  color: evento['estado'] == 'Resultados cargados' 
                    ? const Color(0xFF5DCA88)
                    : Colors.white70,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                evento['fecha_resultado']!,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showSearchDialog() {
    if (_eventId.isEmpty) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AthleteSearchSheet(
        eventId: _eventId,
        eventService: _eventService,
      ),
    );
  }

  void _showJornadaDetails(String titulo, String turno, String fecha) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1D1F28),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: Container(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titulo,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                turno,
                style: const TextStyle(
                  color: Color(0xFFE74C3C),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                fecha,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                s.sessionSchedule,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE74C3C),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    s.viewFullDetails,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}