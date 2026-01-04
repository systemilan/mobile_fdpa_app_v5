import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:provider/provider.dart';
import '../championship/championship_detail_screen.dart';
import '../results/all_results_screen.dart';
import '../records/records_screen.dart';
import '../../services/update_service.dart';
import '../../services/event_service.dart';
import '../../models/event.dart' as EventModel;
import '../../models/event_list.dart';
import '../../models/calendar_activity.dart';
import '../../providers/theme_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
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

  // Estado para eventos de la API
  final EventService _eventService = EventService();
  List<EventItem> _upcomingEvents = [];
  List<EventItem> _latestResults = [];
  List<CalendarActivity> _calendarActivities = [];

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
      
      // Cargar eventos de la API
      _loadLatestEvents();
      
      // Cargar actividades del calendario
      _loadCalendarActivities();
      
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

  /// Carga los últimos eventos de la API
  Future<void> _loadLatestEvents() async {
    try {
      debugPrint('🔄 Cargando eventos desde la API...');
      
      // Intentar primero con /events/latest
      try {
        final response = await _eventService.getLatestEvents();
        debugPrint('✅ Eventos cargados desde /events/latest: ${response.events.length}');
        
        if (mounted) {
          // Convertir Event a EventItem
          final eventItems = response.events.map((event) {
            // Convertir Stadium de event.dart a Stadium de event_list.dart
            final stadium = Stadium(
              id: event.stadium.id,
              shortName: event.stadium.shortName,
              longName: event.stadium.longName,
              address: event.stadium.address,
              description: event.stadium.description,
              district: District(
                id: event.stadium.district.id,
                name: event.stadium.district.name,
                province: event.stadium.district.province,
                department: event.stadium.district.department,
              ),
            );
            
            return EventItem(
              id: event.id,
              shortName: event.shortName,
              longName: event.longName,
              dateStart: event.dateStart,
              dateEnd: event.dateEnd,
              stadium: stadium,
            );
          }).toList();
          
          final now = DateTime.now();
          
          // Filtrar PRÓXIMOS eventos: de hoy en adelante + 15 días
          final endDate = now.add(const Duration(days: 15));
          final upcomingEvents = eventItems.where((event) {
            try {
              final eventDate = DateTime.parse(event.dateStart);
              // Incluir eventos que están entre hoy y 15 días adelante
              return eventDate.isAfter(now.subtract(const Duration(days: 1))) && 
                     eventDate.isBefore(endDate.add(const Duration(days: 1)));
            } catch (e) {
              return false;
            }
          }).toList();
          
          // Ordenar próximos eventos por fecha (más cercanos primero)
          upcomingEvents.sort((a, b) {
            try {
              return DateTime.parse(a.dateStart).compareTo(DateTime.parse(b.dateStart));
            } catch (e) {
              return 0;
            }
          });
          
          // Filtrar ÚLTIMOS RESULTADOS: eventos pasados (últimos 90 días)
          final startDate = now.subtract(const Duration(days: 90));
          final latestResults = eventItems.where((event) {
            try {
              final eventDate = DateTime.parse(event.dateEnd.isNotEmpty ? event.dateEnd : event.dateStart);
              // Incluir eventos que terminaron en los últimos 90 días pero antes de hoy
              return eventDate.isAfter(startDate.subtract(const Duration(days: 1))) && 
                     eventDate.isBefore(now.add(const Duration(days: 1)));
            } catch (e) {
              return false;
            }
          }).toList();
          
          // Ordenar últimos resultados por fecha (más recientes primero)
          latestResults.sort((a, b) {
            try {
              final dateA = DateTime.parse(a.dateEnd.isNotEmpty ? a.dateEnd : a.dateStart);
              final dateB = DateTime.parse(b.dateEnd.isNotEmpty ? b.dateEnd : b.dateStart);
              return dateB.compareTo(dateA); // Orden descendente (más recientes primero)
            } catch (e) {
              return 0;
            }
          });
          
          debugPrint('✅ Próximos eventos (15 días): ${upcomingEvents.length}');
          debugPrint('✅ Últimos resultados (90 días): ${latestResults.length}');
          
          setState(() {
            _upcomingEvents = upcomingEvents;
            _latestResults = latestResults;
          });
        }
      } catch (e) {
        debugPrint('⚠️ Error con /events/latest, intentando con /events...');
        
        // Si falla, intentar con /events
        final response = await _eventService.getAllEvents();
        debugPrint('✅ Eventos cargados desde /events: ${response.data.length}');
        
        if (mounted) {
          final now = DateTime.now();
          
          // Filtrar PRÓXIMOS eventos: de hoy en adelante + 15 días
          final endDate = now.add(const Duration(days: 15));
          final upcomingEvents = response.data.where((event) {
            try {
              final eventDate = DateTime.parse(event.dateStart);
              // Incluir eventos que están entre hoy y 15 días adelante
              return eventDate.isAfter(now.subtract(const Duration(days: 1))) && 
                     eventDate.isBefore(endDate.add(const Duration(days: 1)));
            } catch (e) {
              return false;
            }
          }).toList();
          
          // Ordenar próximos eventos por fecha (más cercanos primero)
          upcomingEvents.sort((a, b) {
            try {
              return DateTime.parse(a.dateStart).compareTo(DateTime.parse(b.dateStart));
            } catch (e) {
              return 0;
            }
          });
          
          // Filtrar ÚLTIMOS RESULTADOS: eventos pasados (últimos 90 días)
          final startDate = now.subtract(const Duration(days: 90));
          final latestResults = response.data.where((event) {
            try {
              final eventDate = DateTime.parse(event.dateEnd.isNotEmpty ? event.dateEnd : event.dateStart);
              // Incluir eventos que terminaron en los últimos 90 días pero antes de hoy
              return eventDate.isAfter(startDate.subtract(const Duration(days: 1))) && 
                     eventDate.isBefore(now.add(const Duration(days: 1)));
            } catch (e) {
              return false;
            }
          }).toList();
          
          // Ordenar últimos resultados por fecha (más recientes primero)
          latestResults.sort((a, b) {
            try {
              final dateA = DateTime.parse(a.dateEnd.isNotEmpty ? a.dateEnd : a.dateStart);
              final dateB = DateTime.parse(b.dateEnd.isNotEmpty ? b.dateEnd : b.dateStart);
              return dateB.compareTo(dateA); // Orden descendente (más recientes primero)
            } catch (e) {
              return 0;
            }
          });
          
          debugPrint('✅ Próximos eventos (15 días): ${upcomingEvents.length}');
          debugPrint('✅ Últimos resultados (90 días): ${latestResults.length}');
          
          debugPrint('✅ Próximos eventos (15 días): ${upcomingEvents.length}');
          debugPrint('✅ Últimos resultados (30 días): ${latestResults.length}');
          
          setState(() {
            _upcomingEvents = upcomingEvents;
            _latestResults = latestResults;
          });
        }
      }
    } catch (e) {
      debugPrint('❌ Error cargando eventos: $e');
      if (mounted) {
        setState(() {
          _upcomingEvents = [];
        });
      }
    }
  }

  /// Carga las actividades del calendario desde la API
  Future<void> _loadCalendarActivities() async {
    try {
      debugPrint('📅 Cargando actividades del calendario...');
      
      final response = await _eventService.getCalendarActivities();
      debugPrint('✅ Actividades cargadas: ${response.total}');
      
      if (mounted) {
        final now = DateTime.now();
        
        // Filtrar TODAS las actividades futuras sin límite de fecha
        final upcomingActivities = response.data
            .where((activity) {
              try {
                final endDate = DateTime.parse(activity.dateEnd);
                // Incluir TODOS los eventos que no han terminado aún
                return endDate.isAfter(now.subtract(const Duration(days: 1)));
              } catch (e) {
                debugPrint('⚠️ Error parseando fecha: ${activity.dateEnd}');
                return true; // Incluir si hay error en la fecha
              }
            })
            .toList();
        
        // Ordenar por fecha de inicio (más cercanas primero)
        upcomingActivities.sort((a, b) {
          try {
            final dateA = a.dateStartParsed ?? DateTime.now();
            final dateB = b.dateStartParsed ?? DateTime.now();
            return dateA.compareTo(dateB);
          } catch (e) {
            return 0;
          }
        });
        
        debugPrint('✅ Actividades futuras encontradas: ${upcomingActivities.length}');
        if (upcomingActivities.isNotEmpty) {
          debugPrint('📌 Primera actividad: ${upcomingActivities.first.title} - ${upcomingActivities.first.dateStart}');
        }
        
        setState(() {
          _calendarActivities = upcomingActivities;
        });
      }
    } catch (e) {
      debugPrint('❌ Error cargando actividades del calendario: $e');
      if (mounted) {
        setState(() {
          _calendarActivities = [];
        });
      }
    }
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
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 32),
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
                      child: _buildUpcomingEventsFromCalendar(),
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
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) => const AllResultsScreen(),
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
        _getResultsData().isEmpty
            ? Container(
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.event_busy,
                        color: Colors.white.withOpacity(0.4),
                        size: 40,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No hay resultados recientes',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Los resultados de eventos pasados aparecerán aquí',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.4),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : SizedBox(
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
                        result['id'],
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
    // Usar últimos resultados (eventos pasados) ordenados descendentemente
    if (_latestResults.isNotEmpty) {
      // Crear una copia de la lista para ordenar
      final sortedResults = List<EventItem>.from(_latestResults);
      
      // Ordenar por fecha de inicio de forma descendente (más recientes primero)
      sortedResults.sort((a, b) {
        try {
          final dateA = DateTime.parse(a.dateStart);
          final dateB = DateTime.parse(b.dateStart);
          return dateB.compareTo(dateA); // Orden descendente
        } catch (e) {
          return 0;
        }
      });
      
      return sortedResults.map((event) {
        return {
          'id': event.id,
          'date': event.formattedStartDate, // Solo fecha de inicio
          'title': event.longName,
          'location': '${event.stadium.shortName} - ${event.stadium.locationFormatted}',
        };
      }).toList();
    }
    
    // Retornar lista vacía si no hay eventos de la API
    return [];
  }

  Widget _buildResultCard(String? eventId, String date, String title, String location) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => ChampionshipDetailScreen(
              eventId: eventId,
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
          () => _navigateToRecords(isMinimumMarks: true),
        ),
        const SizedBox(height: 15),
        _buildStatsCard(
          'Records Nacionales',
          'Lista actualizada el 20 de febrero de 2025',
          Icons.emoji_events,
          () => _navigateToRecords(isMinimumMarks: false),
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
        upcomingEvents.isEmpty
            ? Container(
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        color: Colors.white.withOpacity(0.4),
                        size: 32,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No hay eventos próximos',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : SizedBox(
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
        _buildCurrentDateTime(), // Reemplazado: _buildNextEvent()
      ],
    );
  }

  List<Map<String, String>> _generateUpcomingEvents(DateTime currentDate) {
    final events = <Map<String, String>>[];
    final monthNames = [
      'Ene.', 'Feb.', 'Mar.', 'Abr.', 'May.', 'Jun.',
      'Jul.', 'Ago.', 'Sep.', 'Oct.', 'Nov.', 'Dic.'
    ];

    // Usar eventos reales de la API
    if (_upcomingEvents.isNotEmpty) {
      for (var event in _upcomingEvents.take(6)) {
        try {
          final eventDate = DateTime.parse(event.dateStart);
          events.add({
            'day': eventDate.day.toString().padLeft(2, '0'),
            'month': monthNames[eventDate.month - 1],
            'year': eventDate.year.toString(),
          });
        } catch (e) {
          // Ignorar eventos con fechas inválidas
        }
      }
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

  // COMENTADO TEMPORALMENTE - Siguiente Campeonato
  /*
  Widget _buildNextEvent() {
    // Si hay eventos de la API, usar el primero (más reciente/próximo)
    String eventTitle = 'I Control Evaluativo';
    String dayNumber = '7';
    String monthName = 'Marzo';
    
    if (_upcomingEvents.isNotEmpty) {
      final nextEvent = _upcomingEvents.first;
      eventTitle = nextEvent.shortName;
      
      // Extraer día y mes de la fecha
      try {
        final date = DateTime.parse(nextEvent.dateStart);
        dayNumber = date.day.toString();
        final monthNames = [
          'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
          'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
        ];
        monthName = monthNames[date.month - 1];
      } catch (e) {
        // Usar valores por defecto
      }
    }
    
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Siguiente campeonato',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    eventTitle,
                    style: const TextStyle(
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
  */

  /// Widget para mostrar próximos eventos desde la API de calendario
  Widget _buildUpcomingEventsFromCalendar() {
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
                _showCalendarFromActivities(context);
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
        _calendarActivities.isEmpty
            ? Container(
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        color: Colors.white.withOpacity(0.4),
                        size: 32,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No hay eventos próximos',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _calendarActivities.length > 6 ? 6 : _calendarActivities.length,
                  itemBuilder: (context, index) {
                    final activity = _calendarActivities[index];
                    return _buildEventCardFromActivity(activity, index == 0);
                  },
                ),
              ),
        const SizedBox(height: 20),
        _buildCurrentDateTime(),
      ],
    );
  }

  /// Card de evento usando datos de CalendarActivity
  Widget _buildEventCardFromActivity(CalendarActivity activity, bool isNext) {
    return GestureDetector(
      onTap: () {
        // Si la actividad tiene un eventId, navegar al detalle del campeonato
        if (activity.eventId != null && activity.eventId!.isNotEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChampionshipDetailScreen(
                eventId: activity.eventId!,
                title: activity.title,
                date: activity.formattedDateRange,
                location: activity.location.isNotEmpty ? activity.location : 'Ubicación por definir',
              ),
            ),
          );
        } else {
          // Mostrar detalles de la actividad
          _showActivityDetails(context, activity);
        }
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
              () {
                try {
                  final date = DateTime.parse(activity.dateStart);
                  return date.day.toString().padLeft(2, '0');
                } catch (e) {
                  return '--';
                }
              }(),
              style: TextStyle(
                color: isNext ? Colors.white : const Color(0xFF1D1F28),
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              () {
                try {
                  final date = DateTime.parse(activity.dateStart);
                  final monthNames = [
                    'Ene.', 'Feb.', 'Mar.', 'Abr.', 'May.', 'Jun.',
                    'Jul.', 'Ago.', 'Sep.', 'Oct.', 'Nov.', 'Dic.'
                  ];
                  return monthNames[date.month - 1];
                } catch (e) {
                  return '--';
                }
              }(),
              style: TextStyle(
                color: isNext ? Colors.white : const Color(0xFF1D1F28),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              () {
                try {
                  final date = DateTime.parse(activity.dateStart);
                  return date.year.toString();
                } catch (e) {
                  return '--';
                }
              }(),
              style: TextStyle(
                color: isNext ? Colors.white70 : Colors.grey,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Mostrar calendario modal con actividades
  void _showCalendarFromActivities(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF1D1F28),
                Color(0xFF2A2D36),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFE74C3C).withOpacity(0.3),
              width: 2,
            ),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Calendario de Eventos',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: _calendarActivities.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.calendar_today,
                              color: Colors.white.withOpacity(0.3),
                              size: 64,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No hay eventos próximos',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _calendarActivities.length,
                        itemBuilder: (context, index) {
                          final activity = _calendarActivities[index];
                          return _buildCalendarEventCardFromActivity(activity);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Card de evento en el calendario modal
  Widget _buildCalendarEventCardFromActivity(CalendarActivity activity) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        if (activity.eventId != null && activity.eventId!.isNotEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChampionshipDetailScreen(
                eventId: activity.eventId!,
                title: activity.title,
                date: activity.formattedDateRange,
                location: activity.location.isNotEmpty ? activity.location : 'Ubicación por definir',
              ),
            ),
          );
        } else {
          _showActivityDetails(context, activity);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF282C34),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: activity.typeColor.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: activity.typeColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    () {
                      try {
                        final date = DateTime.parse(activity.dateStart);
                        return date.day.toString();
                      } catch (e) {
                        return '--';
                      }
                    }(),
                    style: TextStyle(
                      color: activity.typeColor,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    () {
                      try {
                        final date = DateTime.parse(activity.dateStart);
                        final monthNames = [
                          'ENE', 'FEB', 'MAR', 'ABR', 'MAY', 'JUN',
                          'JUL', 'AGO', 'SEP', 'OCT', 'NOV', 'DIC'
                        ];
                        return monthNames[date.month - 1];
                      } catch (e) {
                        return '--';
                      }
                    }(),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: activity.typeColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: activity.typeColor,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          activity.type.toUpperCase(),
                          style: TextStyle(
                            color: activity.typeColor,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    activity.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if (activity.location.isNotEmpty)
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          color: Colors.white54,
                          size: 12,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            activity.location,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            if (activity.daysUntilStart > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE74C3C).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${activity.daysUntilStart}d',
                  style: const TextStyle(
                    color: Color(0xFFE74C3C),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Widget para mostrar actividades del calendario desde la API (MÉTODO ANTIGUO - NO SE USA)
  Widget _buildCalendarActivities() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(
              Icons.event_note,
              color: Color(0xFFE74C3C),
              size: 26,
            ),
            SizedBox(width: 10),
            Text(
              'Calendario de Actividades',
              style: TextStyle(
                color: Color(0xFFE74C3C),
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _calendarActivities.isEmpty
            ? Container(
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.event_busy,
                        color: Colors.white.withOpacity(0.4),
                        size: 40,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No hay actividades programadas',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : Column(
                children: _calendarActivities.take(3).map((activity) {
                  return _buildCalendarActivityCard(activity);
                }).toList(),
              ),
      ],
    );
  }

  /// Card individual para cada actividad del calendario
  Widget _buildCalendarActivityCard(CalendarActivity activity) {
    return GestureDetector(
      onTap: () {
        // Si la actividad tiene un eventId, navegar al detalle del evento
        if (activity.eventId != null && activity.eventId!.isNotEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChampionshipDetailScreen(
                eventId: activity.eventId!,
                title: activity.title,
                date: activity.formattedDateRange,
                location: activity.location.isNotEmpty ? activity.location : 'Ubicación por definir',
              ),
            ),
          );
        } else {
          // Mostrar detalles de la actividad en un diálogo
          _showActivityDetails(context, activity);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF1D1F28),
              const Color(0xFF2A2D36),
            ],
          ),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: activity.typeColor.withOpacity(0.3),
            width: 2,
          ),
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
          children: [
            Row(
              children: [
                // Badge de tipo
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: activity.typeColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: activity.typeColor,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    activity.type.toUpperCase(),
                    style: TextStyle(
                      color: activity.typeColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const Spacer(),
                // Días restantes
                if (activity.daysUntilStart > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE74C3C).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          color: Color(0xFFE74C3C),
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${activity.daysUntilStart}d',
                          style: const TextStyle(
                            color: Color(0xFFE74C3C),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            // Título
            Text(
              activity.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (activity.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                activity.description,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 12),
            // Fecha y ubicación
            Row(
              children: [
                const Icon(
                  Icons.calendar_today,
                  color: Colors.white54,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    activity.formattedDateRange,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            if (activity.location.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.location_on,
                    color: Colors.white54,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      activity.location,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Diálogo para mostrar detalles de una actividad
  void _showActivityDetails(BuildContext context, CalendarActivity activity) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1D1F28),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: activity.typeColor.withOpacity(0.3),
            width: 2,
          ),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: activity.typeColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: activity.typeColor,
                  width: 1,
                ),
              ),
              child: Text(
                activity.type.toUpperCase(),
                style: TextStyle(
                  color: activity.typeColor,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                activity.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              if (activity.description.isNotEmpty) ...[
                const Text(
                  'Descripción:',
                  style: TextStyle(
                    color: Color(0xFFE74C3C),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  activity.description,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Row(
                children: [
                  const Icon(Icons.calendar_today, color: Colors.white54, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      activity.formattedDateRange,
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ),
                ],
              ),
              if (activity.isMultiDay) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.access_time, color: Colors.white54, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      activity.formattedDuration,
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ],
              if (activity.location.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.white54, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        activity.location,
                        style: const TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ],
              if (activity.daysUntilStart > 0) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE74C3C).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFE74C3C).withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time, color: Color(0xFFE74C3C), size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Faltan ${activity.daysUntilStart} días',
                        style: const TextStyle(
                          color: Color(0xFFE74C3C),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
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

  // NUEVO: Muestra fecha y hora actual
  Widget _buildCurrentDateTime() {
    return StreamBuilder(
      stream: Stream.periodic(const Duration(seconds: 1)),
      builder: (context, snapshot) {
        final now = DateTime.now();
        final dayNumber = now.day;
        final monthNames = [
          'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
          'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
        ];
        final monthName = monthNames[now.month - 1];
        final year = now.year;
        
        final hour = now.hour.toString().padLeft(2, '0');
        final minute = now.minute.toString().padLeft(2, '0');
        final second = now.second.toString().padLeft(2, '0');
        
        final weekDays = ['Domingo', 'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado'];
        final weekDay = weekDays[now.weekday % 7];
        
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF1D1F28),
                const Color(0xFF2A2D36),
              ],
            ),
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
            children: [
              // Día de la semana
              Text(
                weekDay,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 8),
              // Fecha
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '$dayNumber',
                    style: const TextStyle(
                      color: Color(0xFFE74C3C),
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      height: 1,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        monthName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '$year',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Separador
              Container(
                height: 1,
                width: 100,
                color: Colors.white.withOpacity(0.2),
              ),
              const SizedBox(height: 12),
              // Hora actual
              Text(
                '$hour:$minute:$second',
                style: const TextStyle(
                  color: Color(0xFFE74C3C),
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  fontFeatures: [
                    FontFeature.tabularFigures(),
                  ],
                ),
              ),
            ],
          ),
        );
      },
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

  void _navigateToRecords({required bool isMinimumMarks}) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => RecordsScreen(initialIsMinimumMarks: isMinimumMarks),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOutCubic;

          var tween = Tween(begin: begin, end: end).chain(
            CurveTween(curve: curve),
          );

          var fadeAnimation = Tween<double>(
            begin: 0.0,
            end: 1.0,
          ).animate(
            CurvedAnimation(
              parent: animation,
              curve: const Interval(0.0, 1.0, curve: Curves.easeOut),
            ),
          );

          return SlideTransition(
            position: animation.drive(tween),
            child: FadeTransition(
              opacity: fadeAnimation,
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  void _showCalendar(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF1D1F28),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Calendario de Eventos',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: _upcomingEvents.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.calendar_today,
                              color: Colors.white.withOpacity(0.3),
                              size: 64,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No hay eventos próximos',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _upcomingEvents.length,
                        itemBuilder: (context, index) {
                          final event = _upcomingEvents[index];
                          return _buildCalendarEventCard(event);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCalendarEventCard(EventItem event) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChampionshipDetailScreen(
              eventId: event.id,
              title: event.longName,
              date: event.formattedDateRange,
              location: '${event.stadium.shortName} - ${event.stadium.locationFormatted}',
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF282C34),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFE74C3C).withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFFE74C3C).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    () {
                      try {
                        final date = DateTime.parse(event.dateStart);
                        return date.day.toString();
                      } catch (e) {
                        return '--';
                      }
                    }(),
                    style: const TextStyle(
                      color: Color(0xFFE74C3C),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    () {
                      try {
                        final date = DateTime.parse(event.dateStart);
                        final months = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
                        return months[date.month - 1];
                      } catch (e) {
                        return '---';
                      }
                    }(),
                    style: const TextStyle(
                      color: Color(0xFFE74C3C),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.longName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${event.stadium.shortName} - ${event.stadium.locationFormatted}',
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Color(0xFFE74C3C),
              size: 16,
            ),
          ],
        ),
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
              color: isDarkMode ? const Color(0xFF040512) : const Color(0xFFF8F9FA),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    Image.asset(
                      'assets/images/fdpa_logo.png',
                      width: 60,
                      height: 60,
                      fit: BoxFit.contain,
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
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
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
                              child: Icon(
                                isDarkMode ? Icons.dark_mode : Icons.light_mode,
                                color: isDarkMode ? Colors.white70 : Colors.black54,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Modo Oscuro',
                                    style: TextStyle(
                                      color: isDarkMode ? Colors.white : Colors.black87,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    'Cambiar apariencia de la app',
                                    style: TextStyle(
                                      color: isDarkMode 
                                        ? Colors.white60
                                        : Colors.black54,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: isDarkMode,
                              onChanged: (value) {
                                themeProvider.toggleTheme();
                              },
                              activeColor: const Color(0xFFE74C3C),
                              inactiveThumbColor: isDarkMode ? Colors.white70 : Colors.black54,
                              inactiveTrackColor: isDarkMode 
                                ? Colors.white.withOpacity(0.3)
                                : Colors.black.withOpacity(0.3),
                            ),
                          ],
                        ),
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
          ),
          
          // Footer con información de desarrollador y versión
          Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Text(
                  'Powered by: Ditxon Milan',
                  style: TextStyle(
                    color: isDarkMode 
                      ? Colors.white60
                      : Colors.black54,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Versión 1.2.2+109',
                  style: TextStyle(
                    color: isDarkMode 
                      ? Colors.white.withOpacity(0.4)
                      : Colors.black.withOpacity(0.38),
                    fontSize: 11,
                  ),
                ),
              ],
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