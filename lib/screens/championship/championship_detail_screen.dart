import 'package:flutter/material.dart';
import '../results/result_detail_screen_type1.dart';
import '../results/result_detail_screen_type2.dart';
import '../results/result_detail_screen_type3.dart';
import '../../services/event_service.dart';
import '../../models/jornada.dart';
import '../../config/environment.dart';

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
  
  // Estado para jornadas de la API
  final EventService _eventService = EventService();
  List<Jornada> _jornadas = [];
  bool _isLoadingJornadas = true;
  
  // Estado para el evento (incluye información sobre si es histórico)
  Map<String, dynamic>? _eventData;
  bool get _isHistoricalEvent => _eventData?['oldHistory'] == true;
  String get _eventId => _eventData?['id'] ?? widget.eventId ?? '';
  
  // Animaciones escalonadas para los elementos
  late Animation<double> _headerFadeAnimation;
  late Animation<Offset> _headerSlideAnimation;
  late Animation<double> _titleFadeAnimation;
  late Animation<Offset> _titleSlideAnimation;
  late Animation<double> _searchFadeAnimation;
  late Animation<Offset> _searchSlideAnimation;
  late Animation<double> _jornadasFadeAnimation;
  late Animation<Offset> _jornadasSlideAnimation;

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

    // Iniciar animaciones con delay
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        _fadeController.forward();
        _slideController.forward();
        _staggeredController.forward();
      }
    });
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
          _isLoadingJornadas = false;
        });
        
        // Log información del evento para debugging
        if (Environment.enableLogs) {
          print('📋 Event loaded: ${_eventData?['shortName']} (oldHistory: ${_eventData?['oldHistory']})');
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
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 32),
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
                  const SizedBox(height: 40),
                  FadeTransition(
                    opacity: _titleFadeAnimation,
                    child: SlideTransition(
                      position: _titleSlideAnimation,
                      child: _buildTitleSection(),
                    ),
                  ),
                  const SizedBox(height: 30),
                  FadeTransition(
                    opacity: _searchFadeAnimation,
                    child: SlideTransition(
                      position: _searchSlideAnimation,
                      child: _buildSearchBox(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  FadeTransition(
                    opacity: _jornadasFadeAnimation,
                    child: SlideTransition(
                      position: _jornadasSlideAnimation,
                      child: _buildJornadasList(),
                    ),
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
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Federación Deportiva',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Peruana de Atletismo',
                  style: TextStyle(
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
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Título - 70%
            Expanded(
              flex: 7,
              child: Text(
                widget.title.replaceAll('\n', ' '),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
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
                    width: 64,
                    height: 42,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
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
                  const SizedBox(height: 8),
                  Text(
                    widget.location,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.end,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          widget.date,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 16,
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
            const Text(
              'Buscar atleta',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
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
            'No hay jornadas disponibles',
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
        
        // Si está expandida, agregar las pruebas debajo con animaciones
        if (isExpanded && jornada.tests.isNotEmpty) {
          widgets.addAll(
            jornada.tests.asMap().entries.map((testEntry) {
              final testIndex = testEntry.key;
              final test = testEntry.value;
              return _buildAnimatedTestCard(test, testIndex);
            }).toList()
          );
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
        padding: const EdgeInsets.all(28),
        margin: EdgeInsets.only(bottom: isExpanded ? 8 : 15),
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
          borderRadius: BorderRadius.circular(20),
          boxShadow: isExpanded ? [
            BoxShadow(
              color: const Color(0xFFC0392B).withOpacity(0.4),
              blurRadius: 24,
              offset: const Offset(0, 8),
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
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Transform.rotate(
                  angle: isExpanded ? 1.5708 : 0.0, // 90 grados en radianes
                  child: Icon(
                    Icons.chevron_right,
                    color: Colors.white.withOpacity(0.7),
                    size: 28,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  turno,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 17,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                Text(
                  fecha,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 17,
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

  Widget _buildAnimatedTestCard(ScheduledTest test, int index) {
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
                onTap: () {
                  // Determinar si es evento histórico
                  final isHistorical = _isHistoricalEvent || test.id.startsWith('hist-test-');
                  final eventIdToPass = isHistorical ? _eventId : null;
                  
                  if (Environment.enableLogs) {
                    print('🎯 Test clicked: ${test.test.commonName}');
                    print('   - Test ID: ${test.id}');
                    print('   - Is Historical: $isHistorical');
                    print('   - Event ID: $eventIdToPass');
                    print('   - Input Format: ${test.test.inputFormat}');
                  }
                  
                  // Navegar según el inputFormat de la prueba
                  // Para eventos históricos, usar lógica flexible con inputFormat texto
                  if (isHistorical) {
                    // Lógica específica para eventos históricos que pueden usar inputFormat como texto
                    if (test.test.inputFormat == 'tiempo' || test.test.inputFormat == '1' || test.test.type == 'track') {
                      // Carreras: 100m, 200m, 400m, etc.
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ResultDetailScreenType2(
                            eventTestId: test.id,
                            eventId: eventIdToPass, // eventId requerido para históricos
                          ),
                        ),
                      );
                    } else if (test.test.inputFormat == 'altura' || test.test.inputFormat == '2') {
                      // Pruebas de altura: salto alto, garrocha
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ResultDetailScreenType3(
                            eventTestId: test.id,
                            eventId: eventIdToPass, // eventId requerido para históricos
                          ),
                        ),
                      );
                    } else if (test.test.inputFormat == 'intentos' || test.test.inputFormat == '3' || test.test.type == 'field') {
                      // Lanzamientos/saltos con serie de intentos
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ResultDetailScreenType1(
                            eventTestId: test.id,
                            eventId: eventIdToPass, // eventId requerido para históricos
                            title: widget.title,
                            date: widget.date,
                            location: widget.location,
                            eventName: test.test.officialName,
                            category: test.categoriesFormatted,
                            resultDate: widget.date,
                          ),
                        ),
                      );
                    } else {
                      // Fallback para eventos históricos con formatos no reconocidos
                      if (test.test.type == 'track') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ResultDetailScreenType2(
                              eventTestId: test.id,
                              eventId: eventIdToPass,
                            ),
                          ),
                        );
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ResultDetailScreenType1(
                              eventTestId: test.id,
                              eventId: eventIdToPass,
                              title: widget.title,
                              date: widget.date,
                              location: widget.location,
                              eventName: test.test.officialName,
                              category: test.categoriesFormatted,
                              resultDate: widget.date,
                            ),
                          ),
                        );
                      }
                    }
                  } else {
                    // Lógica ORIGINAL para eventos actuales (no históricos)
                    // Mantener exactamente como estaba antes para compatibilidad
                    if (test.test.inputFormat == '1') {
                      // inputFormat 1: Carreras (100m, 200m, 400m, etc.)
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ResultDetailScreenType2(
                            eventTestId: test.id,
                            // NO pasar eventId para eventos actuales
                          ),
                        ),
                      );
                    } else if (test.test.inputFormat == '2') {
                      // inputFormat 2: Pruebas de altura (salto alto, garrocha)
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ResultDetailScreenType3(
                            eventTestId: test.id,
                            // NO pasar eventId para eventos actuales
                          ),
                        ),
                      );
                    } else if (test.test.inputFormat == '3') {
                      // inputFormat 3: Lanzamientos/saltos con serie de intentos
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ResultDetailScreenType1(
                            eventTestId: test.id,
                            eventId: null, // NO pasar eventId para eventos actuales
                            title: widget.title,
                            date: widget.date,
                            location: widget.location,
                            eventName: test.test.officialName,
                            category: test.categoriesFormatted,
                            resultDate: widget.date,
                          ),
                        ),
                      );
                    } else {
                      // Comportamiento original para eventos actuales
                      debugPrint('Test tapped: ${test.test.commonName} (type: ${test.test.type}, inputFormat: ${test.test.inputFormat})');
                    }
                  }
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(backgroundOpacity),
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
                    children: [
                      // Hora de la prueba
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE74C3C).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          test.time != null && test.time!.length >= 5 
                            ? test.time!.substring(0, 5) 
                            : (test.time ?? '--:--'), // HH:MM o --:-- si es null
                          style: const TextStyle(
                            color: Color(0xFFE74C3C),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Información de la prueba
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              test.test.commonName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              test.categoriesFormatted,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Género
                      Text(
                        _getGenderLabel(test.genders),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1D1F28),
        title: const Text(
          'Buscar Atleta',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Nombre del atleta...',
                hintStyle: const TextStyle(color: Colors.white54),
                filled: true,
                fillColor: Colors.white.withOpacity(0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE74C3C),
            ),
            child: const Text(
              'Buscar',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
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
              const Text(
                'Lista de eventos y horarios para esta jornada.',
                style: TextStyle(
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
                  child: const Text(
                    'Ver Detalles Completos',
                    style: TextStyle(
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