import 'package:flutter/material.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:provider/provider.dart';
import '../championship/championship_detail_screen.dart';
import '../../services/update_service.dart';
import '../../providers/theme_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  // Controladores para animaciones escalonadas
  late AnimationController _headerController;
  late AnimationController _resultsController;
  late AnimationController _statsController;
  late AnimationController _eventsController;
  
  late Animation<double> _headerFadeAnimation;
  late Animation<Offset> _headerSlideAnimation;
  late Animation<double> _resultsFadeAnimation;
  late Animation<Offset> _resultsSlideAnimation;
  late Animation<double> _statsFadeAnimation;
  late Animation<Offset> _statsSlideAnimation;
  late Animation<double> _eventsFadeAnimation;
  late Animation<Offset> _eventsSlideAnimation;

  // Estado para actualizaciones
  bool _updateAvailable = false;
  bool _checkingUpdates = false;
  final UpdateService _updateService = UpdateService();

  @override
  void initState() {
    super.initState();
    try {
      _fadeController = AnimationController(
        duration: const Duration(milliseconds: 1000),
        vsync: this,
      );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
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
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    // Inicializar controladores de animaciones escalonadas
    _headerController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _resultsController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _statsController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _eventsController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    // Configurar animaciones escalonadas
    _headerFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _headerController, curve: Curves.easeOut),
    );
    _headerSlideAnimation = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
      CurvedAnimation(parent: _headerController, curve: Curves.easeOutBack),
    );

    _resultsFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _resultsController, curve: Curves.easeOut),
    );
    _resultsSlideAnimation = Tween<Offset>(begin: const Offset(-0.5, 0), end: Offset.zero).animate(
      CurvedAnimation(parent: _resultsController, curve: Curves.easeOutBack),
    );

    _statsFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _statsController, curve: Curves.easeOut),
    );
    _statsSlideAnimation = Tween<Offset>(begin: const Offset(0.5, 0), end: Offset.zero).animate(
      CurvedAnimation(parent: _statsController, curve: Curves.easeOutBack),
    );

    _eventsFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _eventsController, curve: Curves.easeOut),
    );
    _eventsSlideAnimation = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
      CurvedAnimation(parent: _eventsController, curve: Curves.easeOutBack),
    );

      _fadeController.forward();
      _slideController.forward();
      
      // Iniciar animaciones escalonadas con delays
      _startStaggeredAnimations();
      
      // Verificar actualizaciones después de que se cargue la pantalla
      _checkForUpdatesOnStartup();
    } catch (e) {
      debugPrint('Error inicializando animaciones: $e');
      // Fallback: inicializar controladores básicos
      _fadeController = AnimationController(
        duration: const Duration(milliseconds: 1000),
        vsync: this,
      );
      _slideController = AnimationController(
        duration: const Duration(milliseconds: 800),
        vsync: this,
      );
    }
  }

  void _startStaggeredAnimations() {
    // Header aparece primero después de 300ms
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _headerController.forward();
    });
    
    // Resultados aparecen después de 600ms
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _resultsController.forward();
    });
    
    // Stats aparecen después de 900ms
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) _statsController.forward();
    });
    
    // Eventos aparecen después de 1200ms
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) _eventsController.forward();
    });
  }

  @override
  void dispose() {
    try {
      _fadeController.dispose();
      _slideController.dispose();
      _headerController.dispose();
      _resultsController.dispose();
      _statsController.dispose();
      _eventsController.dispose();
    } catch (e) {
      debugPrint('Error disposing controllers: $e');
    }
    super.dispose();
  }

  /// Verifica actualizaciones al iniciar la app
  Future<void> _checkForUpdatesOnStartup() async {
    // Esperar 3 segundos para que la app termine de cargar completamente
    await Future.delayed(const Duration(seconds: 3));
    
    if (!mounted) return;
    
    setState(() {
      _checkingUpdates = true;
    });

    try {
      // Verificar actualizaciones reales del Play Store
      final hasUpdate = await _checkUpdateAvailability();
      
      if (mounted) {
        setState(() {
          _updateAvailable = hasUpdate;
          _checkingUpdates = false;
        });
      }

      // Si hay actualización disponible, también ejecutar el servicio de actualización
      // para mostrar el diálogo automáticamente si es necesario
      if (hasUpdate && mounted) {
        await _updateService.checkForUpdatesOnStartup(context);
      }
    } catch (e) {
      debugPrint('Error verificando actualizaciones: $e');
      if (mounted) {
        setState(() {
          _updateAvailable = false;
          _checkingUpdates = false;
        });
      }
    }
  }

  /// Verifica si hay actualizaciones disponibles (solo para el indicador)
  Future<bool> _checkUpdateAvailability() async {
    try {
      // Usar la verificación real del Play Store
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        return false;
      }

      // Verificar actualizaciones reales en el Play Store
      final appUpdateInfo = await InAppUpdate.checkForUpdate();
      
      return appUpdateInfo.updateAvailability == UpdateAvailability.updateAvailable;
      
    } catch (e) {
      debugPrint('Error verificando actualización real: $e');
      return false;
    }
  }

  /// Maneja el clic en el botón de actualizaciones
  Future<void> _handleUpdateButtonPressed() async {
    if (_checkingUpdates) return;
    
    setState(() {
      _checkingUpdates = true;
    });

    try {
      // Usar directamente el servicio de actualización que maneja todo el flujo
      await _updateService.checkForUpdates(context, forceCheck: true);
      
      // Actualizar el estado del indicador después de la verificación
      final hasUpdate = await _checkUpdateAvailability();
      
      if (mounted) {
        setState(() {
          _updateAvailable = hasUpdate;
          _checkingUpdates = false;
        });
      }
    } catch (e) {
      debugPrint('Error al verificar actualizaciones manualmente: $e');
      if (mounted) {
        setState(() {
          _updateAvailable = false;
          _checkingUpdates = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    
    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF040512) : const Color(0xFFF8F9FA),
      drawer: _buildDrawer(themeProvider),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  FadeTransition(
                    opacity: _headerFadeAnimation,
                    child: SlideTransition(
                      position: _headerSlideAnimation,
                      child: _buildHeader(),
                    ),
                  ),
                  const SizedBox(height: 30),
                  FadeTransition(
                    opacity: _resultsFadeAnimation,
                    child: SlideTransition(
                      position: _resultsSlideAnimation,
                      child: _buildLastResults(),
                    ),
                  ),
                  const SizedBox(height: 30),
                  FadeTransition(
                    opacity: _statsFadeAnimation,
                    child: SlideTransition(
                      position: _statsSlideAnimation,
                      child: _buildStatsSections(),
                    ),
                  ),
                  const SizedBox(height: 30),
                  FadeTransition(
                    opacity: _eventsFadeAnimation,
                    child: SlideTransition(
                      position: _eventsSlideAnimation,
                      child: _buildUpcomingEvents(),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    
    return Row(
      children: [
        const SizedBox(width: 15),
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: isDarkMode 
                  ? Colors.black.withOpacity(0.2) 
                  : Colors.grey.withOpacity(0.3),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              'assets/images/fdpa_logo.png',
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Federación Deportiva',
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black87,
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Peruana de Atletismo',
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black87,
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        // Botón del menú (tuerca) con notificación de actualización
        _buildMenuButton(),
      ],
    );
  }

  Widget _buildMenuButton() {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    
    return Builder(
      builder: (context) => GestureDetector(
        onTap: () {
          Scaffold.of(context).openDrawer();
        },
        child: Stack(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _updateAvailable 
                  ? Colors.orange.withOpacity(0.2) 
                  : (isDarkMode ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1)),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: _updateAvailable 
                    ? Colors.orange.withOpacity(0.5) 
                    : (isDarkMode ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.2)),
                  width: _updateAvailable ? 2 : 1,
                ),
                boxShadow: _updateAvailable ? [
                  BoxShadow(
                    color: Colors.orange.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ] : [],
              ),
              child: Icon(
                Icons.settings,
                color: _updateAvailable 
                  ? Colors.orange 
                  : (isDarkMode ? Colors.white : Colors.black87),
                  size: 22,
                ),
          ),
          // Indicador de notificación naranja
          if (_updateAvailable && !_checkingUpdates)
            Positioned(
              top: 2,
              right: 2,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: const Color(0xFF040512),
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.info,
                  color: Colors.white,
                  size: 6,
                ),
              ),
            ),
        ],
        ),
      ),
    );
  }

  Widget _buildLastResults() {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Últimos resultados',
              style: TextStyle(
                color: const Color(0xFFE74C3C),
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Ver todos los resultados'),
                    backgroundColor: Color(0xFFE74C3C),
                  ),
                );
              },
              child: Text(
                'Ver todos',
                style: TextStyle(
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 150,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _getResultsData().length,
            itemBuilder: (context, index) {
              final result = _getResultsData()[index];
              return Container(
                width: 200,
                margin: EdgeInsets.only(right: index == _getResultsData().length - 1 ? 0 : 15),
                child: _buildResultCard(
                  result['date']!,
                  result['title']!,
                  result['location']!,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  List<Map<String, String>> _getResultsData() {
    return [
      {
        'date': '16 de marzo 2025',
        'title': 'Campeonato nacional\nde mayores',
        'location': 'VIDENA - Perú',
      },
      {
        'date': '10 de marzo 2025',
        'title': 'Campeonato infantil',
        'location': 'VIDENA - Perú',
      },
      {
        'date': '2 de marzo 2025',
        'title': 'Copa juvenil\nde atletismo',
        'location': 'VIDENA - Perú',
      },
      {
        'date': '25 de febrero 2025',
        'title': 'Torneo regional\nde velocidad',
        'location': 'VIDENA - Perú',
      },
    ];
  }

  Widget _buildResultCard(String date, String title, String location) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => ChampionshipDetailScreen(
              title: title,
              date: date,
              location: location,
            ),
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
              
              // Animación de scale sutil para la nueva pantalla
              final scaleAnimation = Tween(
                begin: 0.95,
                end: 1.0,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: const Interval(0.2, 1.0, curve: Curves.easeOutBack),
              ));
              
              // Animación de fade out para la pantalla anterior
              final secondaryFadeAnimation = Tween(
                begin: 1.0,
                end: 0.0,
              ).animate(CurvedAnimation(
                parent: secondaryAnimation,
                curve: const Interval(0.0, 0.5, curve: Curves.easeInOut),
              ));
              
              // Animación de slide out para la pantalla anterior
              final secondarySlideAnimation = Tween(
                begin: Offset.zero,
                end: const Offset(-0.3, 0.0),
              ).animate(CurvedAnimation(
                parent: secondaryAnimation,
                curve: const Interval(0.0, 0.8, curve: Curves.easeInCubic),
              ));
              
              return Stack(
                children: [
                  // Pantalla anterior con animaciones de salida
                  if (secondaryAnimation.status != AnimationStatus.dismissed)
                    SlideTransition(
                      position: secondarySlideAnimation,
                      child: FadeTransition(
                        opacity: secondaryFadeAnimation,
                        child: Container(
                          color: const Color(0xFF040512),
                        ),
                      ),
                    ),
                  // Nueva pantalla con animaciones de entrada
                  SlideTransition(
                    position: slideAnimation,
                    child: FadeTransition(
                      opacity: fadeAnimation,
                      child: ScaleTransition(
                        scale: scaleAnimation,
                        child: child,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
      child: Container(
        height: 150,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF1D1F28),
          borderRadius: BorderRadius.circular(15),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              date,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.left,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    location,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  '🇵🇪',
                  style: TextStyle(
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSections() {
    return Column(
      children: [
        _buildStatsCard(
          'Marcas Mínimas',
          'Lista actualizada el 20 de febrero de 2025',
          Icons.timer,
          () => _showStatsDetails('Marcas Mínimas'),
        ),
        const SizedBox(height: 15),
        _buildStatsCard(
          'Records Nacionales',
          'Lista actualizada el 20 de febrero de 2025',
          Icons.emoji_events,
          () => _showStatsDetails('Records Nacionales'),
        ),
        const SizedBox(height: 15),
        _buildStatsCard(
          'Ranking Nacional',
          'Lista actualizada el 20 de febrero de 2025',
          Icons.leaderboard,
          () => _showStatsDetails('Ranking Nacional'),
        ),
      ],
    );
  }

  Widget _buildStatsCard(String title, String subtitle, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF1D1F28),
          borderRadius: BorderRadius.circular(15),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFFE74C3C).withOpacity(0.2),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Icon(
                icon,
                color: const Color(0xFFE74C3C),
                size: 30,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingEvents() {
    final now = DateTime.now();
    final upcomingEvents = _generateUpcomingEvents(now);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Próximos eventos',
              style: TextStyle(
                color: Color(0xFFE74C3C),
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            GestureDetector(
              onTap: () {
                _showCalendar(context);
              },
              child: const Text(
                'Abrir calendario',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: upcomingEvents.length,
            itemBuilder: (context, index) {
              final event = upcomingEvents[index];
              return _buildEventCard(
                event['day']!,
                event['month']!,
                event['year']!,
                index == 0,
              );
            },
          ),
        ),
        const SizedBox(height: 20),
        _buildNextEvent(),
      ],
    );
  }

  List<Map<String, String>> _generateUpcomingEvents(DateTime currentDate) {
    final events = <Map<String, String>>[];
    final monthNames = [
      'Ene.', 'Feb.', 'Mar.', 'Abr.', 'May.', 'Jun.',
      'Jul.', 'Ago.', 'Sep.', 'Oct.', 'Nov.', 'Dic.'
    ];

    final eventIntervals = [7, 14, 21, 35, 42, 56];
    
    for (int i = 0; i < eventIntervals.length; i++) {
      final eventDate = currentDate.add(Duration(days: eventIntervals[i]));
      events.add({
        'day': eventDate.day.toString().padLeft(2, '0'),
        'month': monthNames[eventDate.month - 1],
        'year': eventDate.year.toString(),
      });
    }

    return events;
  }

  Widget _buildEventCard(String day, String month, String year, bool isNext) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Evento del $day de $month $year'),
            backgroundColor: const Color(0xFFE74C3C),
          ),
        );
      },
      child: Container(
        width: 100,
        margin: const EdgeInsets.only(right: 15),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: isNext ? const Color(0xFFE74C3C) : Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 5,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              day,
              style: TextStyle(
                color: isNext ? Colors.white : const Color(0xFFE74C3C),
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              month,
              style: TextStyle(
                color: isNext ? Colors.white : const Color(0xFFE74C3C),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              year,
              style: TextStyle(
                color: isNext ? Colors.white70 : Colors.black54,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNextEvent() {
    final now = DateTime.now();
    final nextEventDate = now.add(const Duration(days: 7));
    final monthNames = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    
    final dayNumber = nextEventDate.day.toString();
    final monthName = monthNames[nextEventDate.month - 1];
    
    return GestureDetector(
      onTap: () {
        _showEventDetails(context);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF1D1F28),
          borderRadius: BorderRadius.circular(15),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Siguiente campeonato',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'I Control Evaluativo',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$dayNumber de',
                  style: const TextStyle(
                    color: Color(0xFFE74C3C),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  monthName,
                  style: const TextStyle(
                    color: Color(0xFFE74C3C),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showResultDetails(BuildContext context, String title, String date, String location) {
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
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              date,
              style: const TextStyle(
                color: Color(0xFFE74C3C),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              location,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
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
                  'Ver Resultados Completos',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }

  void _showStatsDetails(String title) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1D1F28),
        title: Text(
          title,
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          'Aquí se mostrarían los detalles de $title con listas actualizadas y estadísticas completas.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cerrar',
              style: TextStyle(color: Color(0xFFE74C3C)),
            ),
          ),
        ],
      ),
    );
  }

  void _showCalendar(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E2328),
        title: const Text(
          'Calendario Completo',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Aquí se abriría el calendario completo con todos los eventos programados para la temporada.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cerrar',
              style: TextStyle(color: Color(0xFFE74C3C)),
            ),
          ),
        ],
      ),
    );
  }

  void _showEventDetails(BuildContext context) {
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
          children: [
            const Text(
              'I Control Evaluativo',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              '18 de Marzo, 2025',
              style: TextStyle(
                color: Color(0xFFE74C3C),
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 15),
            const Text(
              'Primer control evaluativo de la temporada. Participarán atletas de todas las categorías.',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      side: const BorderSide(color: Color(0xFFE74C3C)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Más Info',
                      style: TextStyle(
                        color: Color(0xFFE74C3C),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE74C3C),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Inscribirse',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer(ThemeProvider themeProvider) {
    final isDarkMode = themeProvider.isDarkMode;
    
    return Drawer(
      backgroundColor: isDarkMode ? const Color(0xFF040512) : const Color(0xFFF8F9FA),
      child: Column(
        children: [
          // Header del drawer
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDarkMode 
                  ? [
                      const Color(0xFF1D1F28),
                      const Color(0xFF2C2F36),
                      const Color(0xFF040512),
                    ]
                  : [
                      const Color(0xFFF8F9FA),
                      const Color(0xFFE9ECEF),
                      const Color(0xFFDEE2E6),
                    ],
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: isDarkMode ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          'assets/logos/fdpa_logo.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    Text(
                      'Federación Deportiva',
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black87,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Peruana de Atletismo',
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black87,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Opciones del menú
          Expanded(
            child: Container(
              color: isDarkMode ? const Color(0xFF040512) : const Color(0xFFF8F9FA),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  children: [
                    // Opción de tema
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDarkMode 
                          ? Colors.white.withOpacity(0.05)
                          : Colors.black.withOpacity(0.03),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: isDarkMode 
                            ? Colors.white.withOpacity(0.1)
                            : Colors.black.withOpacity(0.08),
                        ),
                      ),
                      child: ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isDarkMode 
                              ? Colors.white.withOpacity(0.1)
                              : Colors.black.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            isDarkMode ? Icons.light_mode : Icons.dark_mode,
                            color: isDarkMode ? Colors.white70 : Colors.black54,
                            size: 22,
                          ),
                        ),
                        title: Text(
                          isDarkMode ? 'Modo Claro' : 'Modo Oscuro',
                          style: TextStyle(
                            color: isDarkMode ? Colors.white : Colors.black87,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          'Cambiar apariencia de la app',
                          style: TextStyle(
                            color: isDarkMode 
                              ? Colors.white60
                              : Colors.black54,
                            fontSize: 13,
                          ),
                        ),
                        trailing: Icon(
                          Icons.arrow_forward_ios,
                          color: isDarkMode ? Colors.white30 : Colors.black26,
                          size: 16,
                        ),
                        onTap: () {
                          themeProvider.toggleTheme();
                          Navigator.pop(context);
                        },
                      ),
                    ),
                    
                    // Opción de actualización
                    Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: _updateAvailable 
                        ? const Color(0xFFFF6B35).withOpacity(0.1)
                        : (isDarkMode 
                          ? Colors.white.withOpacity(0.05)
                          : Colors.black.withOpacity(0.03)),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: _updateAvailable 
                          ? const Color(0xFFFF6B35).withOpacity(0.3)
                          : (isDarkMode 
                            ? Colors.white.withOpacity(0.1)
                            : Colors.black.withOpacity(0.08)),
                      ),
                    ),
                    child: ListTile(
                      leading: Stack(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: isDarkMode 
                                ? Colors.white.withOpacity(0.1)
                                : Colors.black.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: _checkingUpdates 
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      isDarkMode ? Colors.white70 : Colors.black54,
                                    ),
                                  ),
                                )
                              : Icon(
                                  Icons.system_update,
                                  color: isDarkMode ? Colors.white70 : Colors.black54,
                                  size: 22,
                                ),
                          ),
                          if (_updateAvailable && !_checkingUpdates)
                            Positioned(
                              right: 0,
                              top: 0,
                              child: Container(
                                width: 12,
                                height: 12,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFF6B35),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                        ],
                      ),
                      title: Text(
                        'Actualizaciones',
                        style: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.black87,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        _updateAvailable 
                          ? 'Actualización disponible'
                          : (_checkingUpdates 
                            ? 'Verificando...' 
                            : 'Verificar actualizaciones'),
                        style: TextStyle(
                          color: isDarkMode 
                            ? Colors.white60
                            : Colors.black54,
                          fontSize: 13,
                        ),
                      ),
                      trailing: Icon(
                        Icons.arrow_forward_ios,
                        color: isDarkMode ? Colors.white30 : Colors.black26,
                        size: 16,
                      ),
                      onTap: _handleUpdateButtonPressed,
                    ),
                  ),
                  
                  const SizedBox(height: 10),
                  
                  // Divider
                  Container(
                    height: 1,
                    margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    color: isDarkMode 
                      ? Colors.white.withOpacity(0.1) 
                      : Colors.black.withOpacity(0.1),
                  ),
                  
                  // Sobre la app
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDarkMode 
                        ? Colors.white.withOpacity(0.05)
                        : Colors.black.withOpacity(0.03),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: isDarkMode 
                          ? Colors.white.withOpacity(0.1)
                          : Colors.black.withOpacity(0.08),
                      ),
                    ),
                    child: ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isDarkMode 
                            ? Colors.white.withOpacity(0.1)
                            : Colors.black.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.info_outline,
                          color: isDarkMode ? Colors.white70 : Colors.black54,
                          size: 22,
                        ),
                      ),
                      title: Text(
                        'Sobre la app',
                        style: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.black87,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        'Información y versión',
                        style: TextStyle(
                          color: isDarkMode 
                            ? Colors.white60
                            : Colors.black54,
                          fontSize: 13,
                        ),
                      ),
                      trailing: Icon(
                        Icons.arrow_forward_ios,
                        color: isDarkMode ? Colors.white30 : Colors.black26,
                        size: 16,
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        _showAboutDialog();
                      },
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

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Provider.of<ThemeProvider>(context).isDarkMode 
          ? const Color(0xFF1D1F28) 
          : Colors.white,
        title: Text(
          'Sobre la aplicación',
          style: TextStyle(
            color: Provider.of<ThemeProvider>(context).isDarkMode 
              ? Colors.white 
              : Colors.black87,
          ),
        ),
        content: Text(
          'FDPA App\nVersión 1.2.2+109\n\nAplicación oficial de la Federación Deportiva Peruana de Atletismo para consultar resultados, estadísticas y eventos.',
          style: TextStyle(
            color: Provider.of<ThemeProvider>(context).isDarkMode 
              ? Colors.white70 
              : Colors.black54,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cerrar',
              style: TextStyle(
                color: Provider.of<ThemeProvider>(context).isDarkMode 
                  ? const Color(0xFFE74C3C) 
                  : const Color(0xFFD32F2F),
              ),
            ),
          ),
        ],
      ),
    );
  }
}