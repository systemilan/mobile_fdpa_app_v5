import 'dart:async';
import 'package:provider/provider.dart';
import '../../l10n/app_strings.dart';
import '../../providers/locale_provider.dart';
import 'package:flutter/material.dart';
import '../../models/result_type3.dart';
import '../../services/event_service.dart';
import '../../services/socket_service.dart';
import 'event_test_athlete_search_sheet.dart';

class ResultDetailScreenType3 extends StatefulWidget {
  final String eventTestId;
  final String? eventId; // Optional: event UUID for historical tests

  final String? eventDate; // Fecha ISO de la jornada para determinar si ya pasó

  const ResultDetailScreenType3({
    super.key,
    required this.eventTestId,
    this.eventId,
    this.eventDate,
  });

  @override
  _ResultDetailScreenType3State createState() => _ResultDetailScreenType3State();
}

class _ResultDetailScreenType3State extends State<ResultDetailScreenType3>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _staggeredController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  // Animaciones escalonadas para los elementos
  late Animation<double> _headerFadeAnimation;
  late Animation<Offset> _headerSlideAnimation;
  late Animation<double> _titleFadeAnimation;
  late Animation<Offset> _titleSlideAnimation;
  late Animation<double> _searchFadeAnimation;
  late Animation<Offset> _searchSlideAnimation;
  late Animation<double> _resultsFadeAnimation;
  late Animation<Offset> _resultsSlideAnimation;

  // API data
  ResultType3Data? _resultData;
  bool _isLoading = true;
  String? _errorMessage;
  final EventService _eventService = EventService();

  // Realtime
  final List<StreamSubscription<Map<String, dynamic>>> _socketSubs = [];
  Timer? _refreshDebounce;

  AppStrings get s => context.read<LocaleProvider>().strings;

  @override
  void initState() {
    super.initState();
    _loadResults();
    _subscribeToSocket();
    _initAnimations();
  }

  Future<void> _loadResults() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _eventService.getHeightEventResults(
        widget.eventTestId,
        eventId: widget.eventId,
      );
      setState(() {
        _resultData = response.data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = s.errorLoadingResults(e.toString());
        _isLoading = false;
      });
    }
  }

  void _initAnimations() {
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

    _resultsFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _staggeredController,
        curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
      ),
    );
    _resultsSlideAnimation = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _staggeredController,
        curve: const Interval(0.6, 1.0, curve: Curves.easeOutBack),
      ),
    );

    // Iniciar animaciones con delay
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        _fadeController.forward();
        _slideController.forward();
        _staggeredController.forward();
      }
    });
  }

  @override
  void dispose() {
    _refreshDebounce?.cancel();
    for (final s in _socketSubs) {
      s.cancel();
    }
    _socketSubs.clear();
    _fadeController.dispose();
    _slideController.dispose();
    _staggeredController.dispose();
    super.dispose();
  }

  /// Recarga silenciosa (sin spinner) para actualizaciones realtime
  Future<void> _silentRefresh() async {
    try {
      final response = await _eventService.getHeightEventResults(
        widget.eventTestId,
        eventId: widget.eventId,
      );
      if (mounted) setState(() => _resultData = response.data);
    } catch (_) {}
  }

  /// Suscribirse a eventos Socket.IO relevantes para esta pantalla
  void _subscribeToSocket() {
    final socket = SocketService();
    final eventTestId = widget.eventTestId;
    final eventId = widget.eventId;

    void debounced() {
      _refreshDebounce?.cancel();
      _refreshDebounce = Timer(const Duration(milliseconds: 600), () {
        if (mounted) _silentRefresh();
      });
    }

    _socketSubs
      ..add(socket.on('series:created').listen((d) {
        if (d['eventTestId'] == eventTestId) debounced();
      }))
      ..add(socket.on('series:updated').listen((_) { debounced(); }))
      ..add(socket.on('series:deleted').listen((_) { debounced(); }))
      ..add(socket.on('series:renamedAll').listen((d) {
        if (eventId == null || d['eventId'] == eventId) debounced();
      }))
      ..add(socket.on('lifData:uploaded').listen((_) { debounced(); }))
      ..add(socket.on('lifData:created').listen((_) { debounced(); }))
      ..add(socket.on('lifData:updated').listen((_) { debounced(); }))
      ..add(socket.on('lifData:deleted').listen((_) { debounced(); }))
      ..add(socket.on('lynx:import:complete').listen((_) { debounced(); }));
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFF040512),
        body: const Center(
          child: CircularProgressIndicator(
            color: Color(0xFFE74C3C),
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: const Color(0xFF040512),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 60),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadResults,
                child: Text(s.retry),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF040512),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Column(
            children: [
              // Header con imagen de fondo pegado arriba y lados
              Container(
                width: double.infinity,
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height * 0.13,
                  maxHeight: MediaQuery.of(context).size.height * 0.35,
                ),
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/imagen1.png'),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.3),
                        Colors.black.withOpacity(0.7),
                      ],
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 2),
                          Flexible(
                            child: FadeTransition(
                              opacity: _headerFadeAnimation,
                              child: SlideTransition(
                                position: _headerSlideAnimation,
                                child: _buildHeader(),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Flexible(
                            child: FadeTransition(
                              opacity: _titleFadeAnimation,
                              child: SlideTransition(
                                position: _titleSlideAnimation,
                                child: _buildTitleSection(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Contenido scrolleable
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(8, 8, 8, 24 + MediaQuery.of(context).padding.bottom),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SlideTransition(
                        position: _searchSlideAnimation,
                        child: FadeTransition(
                          opacity: _searchFadeAnimation,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: _buildSearchBox(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SlideTransition(
                        position: _resultsSlideAnimation,
                        child: FadeTransition(
                          opacity: _resultsFadeAnimation,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: _buildResultsSection(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
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
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 28,
              height: 34,
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
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
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  s.federationLine1,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                ),
                Text(
                  s.federationLine2,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    height: 1.2,
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
    // Si no hay datos, mostrar un título genérico
    if (_resultData == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            s.eventResults,
            style: TextStyle(
              color: Colors.white,
              fontSize: MediaQuery.of(context).size.width < 360 ? 14 : (MediaQuery.of(context).size.width < 400 ? 16 : 20),
              fontWeight: FontWeight.w800,
              height: 1.1,
              letterSpacing: -0.5,
            ),
          ),
        ],
      );
    }

    final eventTest = _resultData!.eventTest;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Título - 70%
            Expanded(
              flex: 7,
              child: Text(
                eventTest.displayedName,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: MediaQuery.of(context).size.width < 360 ? 14 : (MediaQuery.of(context).size.width < 400 ? 16 : 20),
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                  letterSpacing: -0.5,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 10),
            // Bandera y ubicación - 30%
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 50,
                    height: 32,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
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
                  const SizedBox(height: 6),
                  const Text(
                    'Perú',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.end,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        // Subtítulo solo si commonName es diferente al nombre mostrado
        if (eventTest.test.commonName.isNotEmpty &&
            eventTest.test.commonName != eventTest.displayedName) ...[
          const SizedBox(height: 2),
          Text(
            eventTest.test.commonName,
            style: const TextStyle(
              color: Color(0xFFE74C3C),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${eventTest.gendersFormatted} - ${eventTest.categoriesFormatted}',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
            Text(
              eventTest.time,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
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
              style: TextStyle(
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

  Widget _buildResultsSection() {
    // Si no hay datos o series vacías, mostrar mensaje
    if (_resultData == null || _resultData!.series.isEmpty) {
      return Center(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 40),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.info_outline,
                color: Colors.white.withOpacity(0.6),
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
              s.noResultsAvailable,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                s.resultsNotRegistered,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: _resultData!.series
          .where((serie) => serie.status)
          .map((serie) {
        return Column(
          children: [
            _buildSerieTitle(serie),
            const SizedBox(height: 12),
            _buildSerieResults(serie),
            const SizedBox(height: 18),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildSerieTitle(ResultSeries serie) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          serie.name,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (serie.wind != null && serie.wind!.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'Viento: ${serie.wind} M/S',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSerieResults(ResultSeries serie) {
    // Ordenar por displayOrder (ya viene ordenado del backend, esto es por seguridad)
    final sortedResults = List<HeightAthleteResult>.from(serie.results)
      ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));

    return Column(
      children: sortedResults.map((athlete) {
        return _buildAthleteCard(athlete);
      }).toList(),
    );
  }

  Widget _buildAthleteCard(HeightAthleteResult athlete) {
    final int position = athlete.position ?? 0;
    final bool isNoPosition = int.tryParse(athlete.positionText.replaceAll('°', '')) == null
        && athlete.positionText != '--';

    Color getPositionColor() {
      if (isNoPosition) return Colors.grey.withOpacity(0.4);
      switch (position) {
        case 1: return const Color(0xFF2ED573);
        case 2: return Colors.white.withOpacity(0.6);
        case 3: return Colors.white.withOpacity(0.4);
        default: return Colors.white.withOpacity(0.2);
      }
    }

    Color getBackgroundColor() {
      if (isNoPosition) return Colors.white.withOpacity(0.03);
      switch (position) {
        case 1: return const Color(0xFF2ED573).withOpacity(0.15);
        case 2: return const Color(0xFF6C757D).withOpacity(0.15);
        case 3: return const Color(0xFF6C757D).withOpacity(0.1);
        default: return Colors.white.withOpacity(0.05);
      }
    }

    Color getBorderColor() {
      if (isNoPosition) return Colors.white.withOpacity(0.06);
      switch (position) {
        case 1: return const Color(0xFF2ED573).withOpacity(0.3);
        case 2: return const Color(0xFF6C757D).withOpacity(0.3);
        case 3: return const Color(0xFF6C757D).withOpacity(0.2);
        default: return Colors.white.withOpacity(0.1);
      }
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: getBackgroundColor(),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: getBorderColor(),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Columna 1: Puesto y altura (20% del ancho)
          Expanded(
            flex: 20,
            child: Container(
              height: 90,
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
              decoration: BoxDecoration(
                color: getPositionColor(),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(15),
                  bottomLeft: Radius.circular(15),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      isNoPosition
                          ? athlete.positionText
                          : (athlete.positionText != '--' ? 'Puesto ${athlete.positionText.replaceAll("°", "")}°' : '--'),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isNoPosition ? 13 : 9,
                        fontWeight: isNoPosition ? FontWeight.w800 : FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  if (!isNoPosition) ...[
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        athlete.bestMark ?? athlete.bestHeight ?? '--',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          // Columna 2: Nombre y intentos (65% del ancho)
          Expanded(
            flex: 65,
            child: Container(
              height: 90,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    athlete.name,
                    style: TextStyle(
                      color: isNoPosition ? Colors.white54 : Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (!isNoPosition) ...[
                    const SizedBox(height: 4),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: athlete.attempts
                              .map((attempt) => _buildAttemptBadge(attempt))
                              .toList(),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          // Columna 3: Equipo (15% del ancho)
          Expanded(
            flex: 15,
            child: Container(
              height: 90,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(15),
                  bottomRight: Radius.circular(15),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      athlete.clubFormatted,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttemptBadge(HeightAttempt attempt) {
    if (attempt.height.isEmpty) return const SizedBox.shrink();
    
    final bool isFailed = attempt.isFailed;
    final bool isCleared = attempt.isCleared;
    final bool isPassed = attempt.isPassed;
    
    return Container(
      margin: const EdgeInsets.only(right: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: isFailed 
            ? const Color(0xFFE74C3C).withOpacity(0.15)
            : isCleared
              ? const Color(0xFF2ED573).withOpacity(0.15)
              : Colors.white.withOpacity(0.1),
          border: Border.all(
            color: isFailed 
              ? const Color(0xFFE74C3C).withOpacity(0.3)
              : isCleared
                ? const Color(0xFF2ED573).withOpacity(0.3)
                : Colors.white.withOpacity(0.2),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Altura
            Text(
              '${attempt.height} m',
              style: TextStyle(
                color: isFailed 
                  ? const Color(0xFFE74C3C) 
                  : isCleared
                    ? const Color(0xFF2ED573)
                    : Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
            // Resultado (O, X, -, etc.)
            if (attempt.result.isNotEmpty)
              const SizedBox(height: 1),
            if (attempt.result.isNotEmpty)
              Text(
                attempt.result,
                style: TextStyle(
                  color: isFailed 
                    ? const Color(0xFFE74C3C) 
                    : isCleared
                      ? const Color(0xFF2ED573)
                      : Colors.white70,
                  fontSize: 8,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1,
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showSearchDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EventTestAthleteSearchSheet(
        eventTestId: widget.eventTestId,
        eventService: _eventService,
      ),
    );
  }
}