import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:in_app_update/in_app_update.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import '../championship/championship_detail_screen.dart';
import '../results/all_results_screen.dart';
import '../records/records_screen.dart';
import '../minimum_marks/minimum_marks_list_screen.dart';
import '../rankings/rankings_list_screen.dart';
import '../../config/environment.dart';
import '../../config/build_info.dart';
import '../../services/update_service.dart';
import '../../services/event_service.dart';
import '../../services/socket_service.dart';
import '../../models/event.dart' as EventModel;
import '../../models/event_list.dart';
import '../../models/calendar_activity.dart';
import '../../providers/theme_provider.dart';
import '../../providers/locale_provider.dart';
import '../../l10n/app_strings.dart';
import 'global_athlete_search_sheet.dart';

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

  // Suscripciones realtime
  final List<StreamSubscription<Map<String, dynamic>>> _socketSubs = [];

  // Fechas de actualización desde la API (ISO crudo para formateo por idioma)
  String? _nationalRecordsDateIso;
  String? _minimumMarksDateIso;
  String? _rankingDateIso;
  bool _datesLoaded = false;
  String _appVersion = '--';

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

      // Cargar fechas de actualización
      _loadUpdateDates();

      // Cargar versión instalada para mostrarla en Drawer/About
      _loadAppVersion();
      
      // Verificar actualizaciones después de que se cargue la pantalla
      _checkForUpdatesOnStartup();

      // Suscribir a eventos realtime
      _subscribeToSocket();
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

  Future<void> _loadAppVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          _appVersion = '${info.version}+${info.buildNumber}';
        });
      }
    } catch (_) {}
  }

  Future<void> _loadUpdateDates() async {
    try {
      final url = Uri.parse('${Environment.publicBaseUrl}/app/update-dates');
      final response = await http.get(url).timeout(Environment.connectTimeout);
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final data = json['data'];
        if (mounted) {
          setState(() {
            _nationalRecordsDateIso = data['nationalRecords']?['lastUpdated']?.toString();
            _minimumMarksDateIso = data['minimumMarks']?['lastUpdated']?.toString();
            _rankingDateIso = data['rankings']?['lastUpdated']?.toString();
            _datesLoaded = true;
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _nationalRecordsDateIso = null;
          _minimumMarksDateIso = null;
          _rankingDateIso = null;
          _datesLoaded = true;
        });
      }
    }
  }

  String _formatDate(String? isoDate, AppStrings s) {
    if (isoDate == null || isoDate.isEmpty) {
      return _datesLoaded ? '--' : s.loading;
    }
    try {
      final dt = DateTime.parse(isoDate).toLocal();
      final months = s.languageCode == 'es'
          ? const [
              'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
              'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'
            ]
          : const [
              'January', 'February', 'March', 'April', 'May', 'June',
              'July', 'August', 'September', 'October', 'November', 'December'
            ];
      final dateText = s.languageCode == 'es'
          ? '${dt.day} de ${months[dt.month - 1]} de ${dt.year}'
          : '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
      return s.rankingListUpdated(dateText);
    } catch (_) {
      return '--';
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
    for (final s in _socketSubs) {
      s.cancel();
    }
    _socketSubs.clear();
    super.dispose();
  }

  /// Suscribirse a eventos realtime del backend para refrescar la lista de eventos
  void _subscribeToSocket() {
    final socket = SocketService();
    _socketSubs
      ..add(socket.on('event:created').listen((_) {
        if (mounted) _loadLatestEvents();
      }))
      ..add(socket.on('event:updated').listen((_) {
        if (mounted) _loadLatestEvents();
      }))
      ..add(socket.on('event:deleted').listen((_) {
        if (mounted) _loadLatestEvents();
      }));
  }

  /// Recarga todos los datos de la pantalla principal (pull-to-refresh)
  Future<void> _refreshData() async {
    await Future.wait([
      _loadLatestEvents(),
      _loadCalendarActivities(),
    ]);
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
          
          final today = DateTime.now();
          final todayDate = DateTime(today.year, today.month, today.day);

          // Filtrar PRÓXIMOS: eventos que no han terminado y empiezan en <= 15 días
          final upcomingEvents = eventItems.where((event) {
            try {
              final endRaw = DateTime.parse(event.dateEnd.isNotEmpty ? event.dateEnd : event.dateStart);
              final endDate = DateTime(endRaw.year, endRaw.month, endRaw.day);
              final startRaw = DateTime.parse(event.dateStart);
              final startDate = DateTime(startRaw.year, startRaw.month, startRaw.day);
              return !endDate.isBefore(todayDate) && startDate.difference(todayDate).inDays <= 15;
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

          // ÚLTIMOS RESULTADOS: eventos cuyo dateEnd ya pasó (comparación de fecha-only)
          final allPastEvents = eventItems.where((event) {
            try {
              final endRaw = DateTime.parse(event.dateEnd.isNotEmpty ? event.dateEnd : event.dateStart);
              final endDate = DateTime(endRaw.year, endRaw.month, endRaw.day);
              return endDate.isBefore(todayDate);
            } catch (e) {
              return false;
            }
          }).toList();
          
          // Ordenar por fecha más reciente primero y tomar los 5 últimos
          allPastEvents.sort((a, b) {
            try {
              final dateA = DateTime.parse(a.dateEnd.isNotEmpty ? a.dateEnd : a.dateStart);
              final dateB = DateTime.parse(b.dateEnd.isNotEmpty ? b.dateEnd : b.dateStart);
              return dateB.compareTo(dateA);
            } catch (e) {
              return 0;
            }
          });
          final latestResults = allPastEvents.take(5).toList();
          
          debugPrint('✅ Próximos eventos (15 días): ${upcomingEvents.length}');
          debugPrint('✅ Últimos resultados (5 más recientes): ${latestResults.length}');
          
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
          final today2 = DateTime.now();
          final todayDate2 = DateTime(today2.year, today2.month, today2.day);

          // Filtrar PRÓXIMOS: eventos que no han terminado y empiezan en <= 15 días
          final upcomingEvents = response.data.where((event) {
            try {
              final endRaw = DateTime.parse(event.dateEnd.isNotEmpty ? event.dateEnd : event.dateStart);
              final endDate = DateTime(endRaw.year, endRaw.month, endRaw.day);
              final startRaw = DateTime.parse(event.dateStart);
              final startDate = DateTime(startRaw.year, startRaw.month, startRaw.day);
              return !endDate.isBefore(todayDate2) && startDate.difference(todayDate2).inDays <= 15;
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

          // ÚLTIMOS RESULTADOS: eventos cuyo dateEnd ya pasó (comparación de fecha-only)
          final allPastEvents2 = response.data.where((event) {
            try {
              final endRaw = DateTime.parse(event.dateEnd.isNotEmpty ? event.dateEnd : event.dateStart);
              final endDate = DateTime(endRaw.year, endRaw.month, endRaw.day);
              return endDate.isBefore(todayDate2);
            } catch (e) {
              return false;
            }
          }).toList();
          
          allPastEvents2.sort((a, b) {
            try {
              final dateA = DateTime.parse(a.dateEnd.isNotEmpty ? a.dateEnd : a.dateStart);
              final dateB = DateTime.parse(b.dateEnd.isNotEmpty ? b.dateEnd : b.dateStart);
              return dateB.compareTo(dateA);
            } catch (e) {
              return 0;
            }
          });
          final latestResults = allPastEvents2.take(5).toList();
          
          debugPrint('✅ Próximos eventos (15 días): ${upcomingEvents.length}');
          debugPrint('✅ Últimos resultados (5 más recientes): ${latestResults.length}');
          
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
        final calToday = DateTime.now();
        final calTodayDate = DateTime(calToday.year, calToday.month, calToday.day);

        // Filtrar TODAS las actividades que no han terminado aún
        final upcomingActivities = response.data
            .where((activity) {
              try {
                final endRaw = DateTime.parse(activity.dateEnd);
                final endDate = DateTime(endRaw.year, endRaw.month, endRaw.day);
                return !endDate.isBefore(calTodayDate);
              } catch (e) {
                debugPrint('⚠️ Error parseando fecha: ${activity.dateEnd}');
                return true;
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
          child: RefreshIndicator(
            onRefresh: _refreshData,
            color: const Color(0xFFE53935),
            backgroundColor: const Color(0xFF1A1A2E),
            strokeWidth: 2.5,
            child: SlideTransition(
              position: _slideAnimation,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 6),
                  FadeTransition(
                    opacity: _headerFadeAnimation,
                    child: SlideTransition(
                      position: _headerSlideAnimation,
                      child: _buildHeader(),
                    ),
                  ),
                  const SizedBox(height: 12),
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
    ),
  );
  }

  Widget _buildGlobalSearchBar() {
    final isDarkMode = Provider.of<ThemeProvider>(context, listen: false).isDarkMode;
    final s = context.watch<LocaleProvider>().strings;
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => GlobalAthleteSearchSheet(
            eventService: _eventService,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          color: isDarkMode
              ? Colors.white.withOpacity(0.06)
              : Colors.black.withOpacity(0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDarkMode
                ? Colors.white.withOpacity(0.1)
                : Colors.black.withOpacity(0.08),
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.search,
                color: isDarkMode ? Colors.white38 : Colors.black38,
                size: 20),
            const SizedBox(width: 10),
            Text(
              s.enterNameSurname,
              style: TextStyle(
                color: isDarkMode ? Colors.white38 : Colors.black38,
                fontSize: 14,
              ),
            ),
            const Spacer(),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFE74C3C).withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.person_search,
                  color: Color(0xFFE74C3C), size: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    final s = context.watch<LocaleProvider>().strings;
    
    return Row(
      children: [
        const SizedBox(width: 12),
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(7),
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
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  s.federationLine1,
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black87,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                ),
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  s.federationLine2,
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black87,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
        // Botón de búsqueda (lupa)
        GestureDetector(
          onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => GlobalAthleteSearchSheet(
                eventService: _eventService,
              ),
            );
          },
          child: Container(
            width: 34,
            height: 34,
            margin: const EdgeInsets.only(right: 6),
            decoration: BoxDecoration(
              color: isDarkMode
                  ? Colors.white.withOpacity(0.1)
                  : Colors.black.withOpacity(0.1),
              borderRadius: BorderRadius.circular(17),
              border: Border.all(
                color: isDarkMode
                    ? Colors.white.withOpacity(0.2)
                    : Colors.black.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Icon(
              Icons.search,
              color: isDarkMode ? Colors.white70 : Colors.black54,
              size: 17,
            ),
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
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: _updateAvailable 
                  ? Colors.orange.withOpacity(0.2) 
                  : (isDarkMode ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1)),
                borderRadius: BorderRadius.circular(17),
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
                  size: 18,
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
    final s = Provider.of<LocaleProvider>(context).strings;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              s.latestResults,
              style: TextStyle(
                color: isDarkMode ? const Color(0xFFE74C3C) : const Color(0xFFFF6868),
                fontSize: 16,
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
                s.viewAll,
                style: TextStyle(
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _getResultsData().isEmpty
            ? Container(
                height: 150,
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: isDarkMode ? Colors.white.withOpacity(0.1) : Colors.black12,
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.event_busy,
                        color: isDarkMode ? Colors.white38 : Colors.black26,
                        size: 40,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        s.noRecentResults,
                        style: TextStyle(
                          color: isDarkMode ? Colors.white60 : Colors.black54,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        s.pastResultsHere,
                        style: TextStyle(
                          color: isDarkMode ? Colors.white38 : Colors.black38,
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
                        index,
                      ),
                    );
                  },
                ),
              ),
      ],
    );
  }

  List<Map<String, String>> _getResultsData() {
    if (_latestResults.isNotEmpty) {
      // Ya vienen ordenados por fecha desc y limitados a 5 desde la carga
      return _latestResults.take(5).map((event) {
        return {
          'id': event.id,
          'date': event.formattedStartDate,
          'title': event.longName,
          'location': '${event.stadium.shortName} - ${event.stadium.locationFormatted}',
        };
      }).toList();
    }
    return [];
  }

  Widget _buildResultCard(String? eventId, String date, String title, String location, [int cardIndex = 0]) {
    final isDark = Provider.of<ThemeProvider>(context, listen: false).isDarkMode;
    final lightBg = Colors.white;
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
          color: isDark ? const Color(0xFF1D1F28) : lightBg,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black38 : Colors.black.withOpacity(0.09),
              blurRadius: isDark ? 10 : 18,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              date,
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black54,
                fontSize: 14,
              ),
            ),
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  title,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontSize: 18,
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
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black54,
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
    final s = context.watch<LocaleProvider>().strings;
    return Column(
      children: [
        _buildRankingCard(
          title: s.minimumMarks,
          subtitle: _formatDate(_minimumMarksDateIso, s),
          imagePath: 'assets/images/botom1.jpg',
          lightColor: const Color(0xFFFFF0F0),
          onTap: () => _navigateToRecords(isMinimumMarks: true),
        ),
        const SizedBox(height: 15),
        _buildRankingCard(
          title: s.nationalRecords,
          subtitle: _formatDate(_nationalRecordsDateIso, s),
          imagePath: 'assets/images/botom2.jpg',
          lightColor: const Color(0xFFEEF4FF),
          onTap: () => _navigateToRecords(isMinimumMarks: false),
        ),
        const SizedBox(height: 15),
        _buildRankingCard(
          title: s.nationalRanking,
          subtitle: _formatDate(_rankingDateIso, s),
          imagePath: 'assets/images/botom3.jpg',
          lightColor: const Color(0xFFF5F0FF),
          onTap: () => Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, _) =>
                  const RankingsListScreen(),
              transitionsBuilder: (context, animation, _, child) =>
                  FadeTransition(opacity: animation, child: child),
              transitionDuration: const Duration(milliseconds: 400),
              reverseTransitionDuration: const Duration(milliseconds: 300),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRankingCard({
    required String title,
    required String subtitle,
    required String imagePath,
    required VoidCallback onTap,
    Color lightColor = Colors.white,
  }) {
    final isDark = Provider.of<ThemeProvider>(context, listen: false).isDarkMode;
    final cardColor = isDark ? const Color(0xFF1D1F28) : const Color(0xFFD9473A);
    final gradientStart = isDark ? const Color(0xFF1D1F28) : const Color(0xFFD9473A);
    final gradientMid = isDark ? const Color(0xEE1D1F28) : const Color(0xCCD9473A);
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: cardColor,
            boxShadow: [
              BoxShadow(
                color: isDark ? Colors.black38 : Colors.black.withOpacity(0.09),
                blurRadius: isDark ? 10 : 18,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Imagen en el lado derecho
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                width: 160,
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.cover,
                ),
              ),
              // Capa oscura/clara encima de la imagen para apagarla
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                width: 160,
                child: Container(
                  color: Colors.black.withOpacity(isDark ? 0.45 : 0.25),
                ),
              ),
              // Gradiente de fusión: cardColor → transparente (izq → der)
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                width: 180,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      stops: const [0.0, 0.35, 1.0],
                      colors: [
                        gradientStart,
                        gradientMid,
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              // Texto
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.75),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCard(String title, String subtitle, IconData icon, VoidCallback onTap) {
    final isDark = Provider.of<ThemeProvider>(context, listen: false).isDarkMode;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1D1F28) : Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black38 : Colors.black.withOpacity(0.09),
              blurRadius: isDark ? 10 : 18,
              offset: const Offset(0, 4),
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
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: isDark ? Colors.white60 : Colors.black45,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFE74C3C).withOpacity(isDark ? 0.2 : 0.12),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Icon(
                icon,
                color: const Color(0xFFE74C3C),
                size: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingEvents() {
    final now = DateTime.now();
    final s = Provider.of<LocaleProvider>(context).strings;
    final upcomingEvents = _generateUpcomingEvents(now, s.monthNamesShort);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              s.upcomingEvents,
              style: const TextStyle(
                color: Color(0xFFE74C3C),
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            GestureDetector(
              onTap: () {
                _showCalendar(context);
              },
              child: Text(
                s.openCalendar,
                style: const TextStyle(
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
                        s.noUpcomingEvents,
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

  List<Map<String, String>> _generateUpcomingEvents(DateTime currentDate, List<String> monthNamesShort) {
    final events = <Map<String, String>>[];
    final monthNames = monthNamesShort;

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
    final s = context.read<LocaleProvider>().strings;
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(s.eventOnDate(day, month, year)),
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
                fontSize: 18,
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
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final s = Provider.of<LocaleProvider>(context).strings;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              s.upcomingEvents,
              style: TextStyle(
                color: isDark ? const Color(0xFFE74C3C) : const Color(0xFFFF6868),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            GestureDetector(
              onTap: () {
                _showCalendarFromActivities(context);
              },
              child: Text(
                s.openCalendar,
                style: TextStyle(
                  color: isDark ? Colors.white54 : Colors.black45,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _calendarActivities.isEmpty
            ? Container(
                height: 120,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.05)
                      : Colors.black.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withOpacity(0.1)
                        : Colors.black.withOpacity(0.08),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        color: isDark
                            ? Colors.white.withOpacity(0.4)
                            : Colors.black38,
                        size: 32,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        s.noUpcomingEvents,
                        style: TextStyle(
                          color: isDark ? Colors.white.withOpacity(0.6) : Colors.black54,
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
                    return _buildEventCardFromActivity(activity, index == 0, index);
                  },
                ),
              ),
        const SizedBox(height: 20),
        _buildCurrentDateTime(),
      ],
    );
  }

  /// Card de evento usando datos de CalendarActivity
  Widget _buildEventCardFromActivity(CalendarActivity activity, bool isNext, [int cardIndex = 0]) {
    final isDark = Provider.of<ThemeProvider>(context, listen: false).isDarkMode;
    final s = Provider.of<LocaleProvider>(context, listen: false).strings;
    final lightEventBg = Colors.white;
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
          color: isNext
              ? const Color(0xFFE74C3C)
              : (isDark ? const Color(0xFF1D1F28) : lightEventBg),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: isNext
                  ? const Color(0xFFE74C3C).withOpacity(0.35)
                  : Colors.black.withOpacity(isDark ? 0.20 : 0.10),
              blurRadius: isNext ? 12 : 8,
              offset: const Offset(0, 4),
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
                color: isNext
                    ? Colors.white
                    : (Provider.of<ThemeProvider>(context, listen: false).isDarkMode
                        ? Colors.white
                        : const Color(0xFF1D1F28)),
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              () {
                try {
                  final date = DateTime.parse(activity.dateStart);
                  return s.monthNamesShort[date.month - 1];
                } catch (e) {
                  return '--';
                }
              }(),
              style: TextStyle(
                color: isNext
                    ? Colors.white
                    : (Provider.of<ThemeProvider>(context, listen: false).isDarkMode
                        ? Colors.white70
                        : const Color(0xFF1D1F28)),
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
                color: isNext
                    ? Colors.white70
                    : (Provider.of<ThemeProvider>(context, listen: false).isDarkMode
                        ? Colors.white38
                        : Colors.black45),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Descargar PDF del calendario de eventos
  Future<void> _downloadCalendarPdf() async {
    final s = context.read<LocaleProvider>().strings;
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(s.pdfMobileOnly),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }
    try {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                const SizedBox(width: 16),
                Text(s.downloadingCalendarPdf),
              ],
            ),
            duration: const Duration(seconds: 30),
          ),
        );
      }

      final eventService = EventService();
      final filePath = await eventService.downloadCalendarPdf();

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(s.calendarDownloaded(filePath)),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: s.ok,
              textColor: Colors.white,
              onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(s.errorDownloadingPdf(e.toString())),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  /// Mostrar calendario modal con actividades
  void _showCalendarFromActivities(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final s = context.read<LocaleProvider>().strings;
        return DraggableScrollableSheet(
          initialChildSize: 0.80,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Color(0xFF0E1018),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  // ── Header con imagen de fondo ──
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    child: SizedBox(
                      height: 130,
                      width: double.infinity,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // Imagen de fondo
                          Image.asset(
                            'assets/images/botomevent.jpg',
                            fit: BoxFit.cover,
                          ),
                          // Overlay oscuro degradado
                          Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Color(0xCC040512),
                                  Color(0xEE0E1018),
                                ],
                              ),
                            ),
                          ),
                          // Contenido del header
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Pill handle
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
                                const Spacer(),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(0.08),
                                              borderRadius: BorderRadius.circular(20),
                                              border: Border.all(
                                                color: Colors.white.withOpacity(0.15),
                                                width: 1,
                                              ),
                                            ),
                                            child: Text(
                                              s.seasonYear(2026),
                                              style: const TextStyle(
                                                color: Colors.white60,
                                                fontSize: 9,
                                                fontWeight: FontWeight.w700,
                                                letterSpacing: 1.5,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            s.calendarWord,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 26,
                                              fontWeight: FontWeight.w800,
                                              height: 1,
                                              letterSpacing: -0.5,
                                            ),
                                          ),
                                          Text(
                                            s.ofEventsWord,
                                            style: const TextStyle(
                                              color: Color(0xFFE74C3C),
                                              fontSize: 26,
                                              fontWeight: FontWeight.w800,
                                              height: 1.1,
                                              letterSpacing: -0.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Botones top-right
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        GestureDetector(
                                          onTap: () => Navigator.pop(context),
                                          child: Container(
                                            padding: const EdgeInsets.all(7),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(0.08),
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: Colors.white.withOpacity(0.12),
                                                width: 1,
                                              ),
                                            ),
                                            child: const Icon(
                                              Icons.close,
                                              color: Colors.white70,
                                              size: 16,
                                            ),
                                          ),
                                        ),
                                        if (!kIsWeb) ...[  
                                          const SizedBox(height: 8),
                                          GestureDetector(
                                            onTap: _downloadCalendarPdf,
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFE74C3C).withOpacity(0.15),
                                                borderRadius: BorderRadius.circular(8),
                                                border: Border.all(
                                                  color: const Color(0xFFE74C3C).withOpacity(0.35),
                                                  width: 1,
                                                ),
                                              ),
                                              child: const Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(Icons.download_rounded, color: Color(0xFFE74C3C), size: 13),
                                                  SizedBox(width: 4),
                                                  Text(
                                                    'PDF',
                                                    style: TextStyle(
                                                      color: Color(0xFFE74C3C),
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.w700,
                                                      letterSpacing: 0.5,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: _calendarActivities.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.calendar_today_outlined,
                                  color: Colors.white24,
                                  size: 48,
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  s.noUpcomingEvents,
                                  style: const TextStyle(
                                    color: Colors.white38,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            controller: scrollController,
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                            itemCount: _calendarActivities.length,
                            itemBuilder: (context, index) {
                              final activity = _calendarActivities[index];
                              return _buildCalendarEventCardFromActivity(activity);
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Card de evento en el calendario modal
  Widget _buildCalendarEventCardFromActivity(CalendarActivity activity) {
    DateTime? startDate;
    DateTime? endDate;
    try { startDate = DateTime.parse(activity.dateStart); } catch (_) {}
    try { endDate = DateTime.parse(activity.dateEnd); } catch (_) {}

    const monthNames = [
      'ENE', 'FEB', 'MAR', 'ABR', 'MAY', 'JUN',
      'JUL', 'AGO', 'SEP', 'OCT', 'NOV', 'DIC'
    ];
    final dayStr = startDate != null ? startDate.day.toString().padLeft(2, '0') : '--';
    final monStr = startDate != null ? monthNames[startDate.month - 1] : '--';
    final isMultiDay = endDate != null && startDate != null && endDate.day != startDate.day;
    final endDayStr = endDate != null ? endDate.day.toString().padLeft(2, '0') : '';
    final isClickable = activity.eventId != null && activity.eventId!.isNotEmpty;
    final days = activity.daysUntilStart;

    // Acento sutil según tipo (tonos apagados)
    final Color accentColor;
    final String typeLabel;
    switch (activity.type) {
      case 'international':
        accentColor = const Color(0xFF5B9BD5);
        typeLabel   = 'INTERNACIONAL';
        break;
      case 'regional':
        accentColor = const Color(0xFFB8976A);
        typeLabel   = 'REGIONAL';
        break;
      default:
        accentColor = const Color(0xFFB85C5C);
        typeLabel   = 'NACIONAL';
    }

    // Badge días
    String daysLabel;
    Color daysColor;
    if (days <= 0) {
      daysLabel = 'HOY';
      daysColor = const Color(0xFF5DCA88);
    } else if (days == 1) {
      daysLabel = 'MAÑANA';
      daysColor = const Color(0xFFE8876A);
    } else {
      daysLabel = '${days}d';
      daysColor = days <= 7
          ? const Color(0xFFE8876A)
          : days <= 30
              ? const Color(0xFFD4B896)
              : Colors.white38;
    }

    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        if (isClickable) {
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
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF161821),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.white.withOpacity(0.06),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Accent left bar
            Container(
              width: 3,
              height: 72,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(14),
                  bottomLeft: Radius.circular(14),
                ),
              ),
            ),
            // Date column
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    dayStr,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      height: 1,
                    ),
                  ),
                  if (isMultiDay)
                    Text(
                      '–$endDayStr',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.4),
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                    ),
                  const SizedBox(height: 2),
                  Text(
                    monStr,
                    style: TextStyle(
                      color: accentColor.withOpacity(0.85),
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            // Divider vertical
            Container(
              width: 1,
              height: 44,
              color: Colors.white.withOpacity(0.07),
            ),
            const SizedBox(width: 14),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Type badge - minimal
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      typeLabel,
                      style: TextStyle(
                        color: accentColor,
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    activity.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      height: 1.25,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (activity.location.isNotEmpty) ...[  
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined,
                            color: Colors.white.withOpacity(0.3), size: 10),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            activity.location,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.35),
                              fontSize: 11,
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
            const SizedBox(width: 12),
            // Right: days
            Padding(
              padding: const EdgeInsets.only(right: 14),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    daysLabel,
                    style: TextStyle(
                      color: daysColor,
                      fontSize: days <= 1 ? 9 : 15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: days <= 1 ? 0.5 : 0,
                    ),
                  ),
                  if (isClickable)
                    Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.white.withOpacity(0.18),
                      size: 18,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
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
    final Color accentColor;
    final String typeLabel;
    switch (activity.type) {
      case 'international':
        accentColor = const Color(0xFF5B9BD5);
        typeLabel   = 'INTERNACIONAL';
        break;
      case 'regional':
        accentColor = const Color(0xFFB8976A);
        typeLabel   = 'REGIONAL';
        break;
      default:
        accentColor = const Color(0xFFCF4040);
        typeLabel   = 'NACIONAL';
    }

    final days = activity.daysUntilStart;
    final daysEnd = activity.daysRemaining;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          margin: const EdgeInsets.fromLTRB(10, 0, 10, 16),
          decoration: BoxDecoration(
            color: const Color(0xFF181A24),
            borderRadius: BorderRadius.circular(26),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Top accent strip + handle ──────────────────────
              Container(
                height: 5,
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.6),
                  borderRadius: const BorderRadius.only(
                    topLeft:  Radius.circular(26),
                    topRight: Radius.circular(26),
                  ),
                ),
              ),
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(top: 10, bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Header row: type badge ←→ countdown ─────────
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left: badge + title + description
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Type badge
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                                decoration: BoxDecoration(
                                  color: accentColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: accentColor.withOpacity(0.3), width: 1),
                                ),
                                child: Text(
                                  typeLabel,
                                  style: TextStyle(
                                    color: accentColor,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              // Title
                              Text(
                                activity.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  height: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Right: visual countdown block
                        _buildCountdownBlock(days, daysEnd, accentColor),
                      ],
                    ),

                    // ── Description ──────────────────────────────
                    if (activity.description.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        activity.description,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.42),
                          fontSize: 13,
                          height: 1.55,
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),

                    // ── Info block ────────────────────────────────
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white.withOpacity(0.07), width: 1),
                      ),
                      child: Column(
                        children: [
                          _activityInfoRow(Icons.calendar_today_rounded, activity.formattedDateRange, accentColor),
                          if (activity.isMultiDay) ...[
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: Divider(color: Colors.white.withOpacity(0.06), height: 1),
                            ),
                            _activityInfoRow(Icons.timelapse_rounded, activity.formattedDuration, accentColor),
                          ],
                          if (activity.location.isNotEmpty) ...[
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: Divider(color: Colors.white.withOpacity(0.06), height: 1),
                            ),
                            _activityInfoRow(Icons.location_on_rounded, activity.location, accentColor),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── Close button ──────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.06),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          'Cerrar',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.55),
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 12 + MediaQuery.of(ctx).padding.bottom),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCountdownBlock(int days, int daysEnd, Color accentColor) {
    final String bigLabel;
    final String subLabel;
    final Color blockColor;

    if (daysEnd < 0) {
      // El evento ya terminó
      bigLabel   = '–';
      subLabel   = 'Finalizado';
      blockColor = Colors.white24;
    } else if (days <= 0) {
      // Empezó y aún no termina = en curso
      bigLabel   = 'EN';
      subLabel   = 'CURSO';
      blockColor = const Color(0xFF5DCA88);
    } else if (days == 1) {
      bigLabel   = '1';
      subLabel   = 'día';
      blockColor = const Color(0xFFE8876A);
    } else {
      bigLabel   = '$days';
      subLabel   = 'días';
      blockColor = days <= 7 ? const Color(0xFFE8876A) : accentColor;
    }

    final bool isToday = days == 0;
    final double bigFontSize = isToday
        ? 18
        : (days >= 100 ? 22 : 30);

    return Container(
      width: isToday ? 82 : 64,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: blockColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: blockColor.withOpacity(0.25), width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              bigLabel,
              style: TextStyle(
                color: blockColor,
                fontSize: bigFontSize,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
              maxLines: 1,
              softWrap: false,
            ),
          ),
          if (subLabel.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(
              subLabel,
              style: TextStyle(
                color: blockColor.withOpacity(0.7),
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _activityInfoRow(IconData icon, String text, Color accentColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: accentColor.withOpacity(0.6), size: 15),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.white.withOpacity(0.65),
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  // NUEVO: Muestra fecha y hora actual
  Widget _buildCurrentDateTime() {
    return StreamBuilder(
      stream: Stream.periodic(const Duration(seconds: 1)),
      builder: (context, snapshot) {
        final now = DateTime.now();
        final s = Provider.of<LocaleProvider>(context, listen: false).strings;
        final dayNumber = now.day;
        final monthName = s.monthNames[now.month - 1];
        final year = now.year;
        
        final hour = now.hour.toString().padLeft(2, '0');
        final minute = now.minute.toString().padLeft(2, '0');
        final second = now.second.toString().padLeft(2, '0');
        
        final weekDay = s.weekDayNames[now.weekday % 7];
        
        final isDark = Provider.of<ThemeProvider>(context, listen: false).isDarkMode;
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [const Color(0xFF1D1F28), const Color(0xFF2A2D36)]
                  : [Colors.white, const Color(0xFFF5F5F5)],
            ),
            borderRadius: BorderRadius.circular(15),
            border: isDark ? null : Border.all(color: Colors.black12),
            boxShadow: [
              BoxShadow(
                color: isDark ? Colors.black26 : Colors.black12,
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Día de la semana
              Text(
                weekDay,
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.black54,
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
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '$year',
                        style: TextStyle(
                          color: isDark ? Colors.white.withOpacity(0.6) : Colors.black45,
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
                color: isDark ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.1),
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
    if (isMinimumMarks) {
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, _) => const MinimumMarksListScreen(),
          transitionsBuilder: (context, animation, _, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
      return;
    }
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
    final s = context.read<LocaleProvider>().strings;
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
                  Text(
                    s.calendarOfEvents,
                    style: const TextStyle(
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
                            Text(
                              s.noUpcomingEvents,
                              style: const TextStyle(
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
    final s = context.read<LocaleProvider>().strings;
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
                    child: Text(
                      s.moreInfo,
                      style: const TextStyle(
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
                    child: Text(
                      s.register,
                      style: const TextStyle(
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
    final localeProvider = context.watch<LocaleProvider>();
    final s = localeProvider.strings;
    
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
                      s.federationLine1,
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black87,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      s.federationLine2,
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
                    // ── Modo oscuro ──────────────────────────────────────
                    _buildDrawerTile(
                      isDark: isDarkMode,
                      icon: isDarkMode ? Icons.dark_mode : Icons.light_mode,
                      title: s.darkMode,
                      subtitle: s.changeAppearance,
                      trailing: Switch(
                        value: isDarkMode,
                        onChanged: (_) => themeProvider.toggleTheme(),
                        activeColor: const Color(0xFFE74C3C),
                        inactiveThumbColor: isDarkMode ? Colors.white70 : Colors.black54,
                        inactiveTrackColor: isDarkMode
                            ? Colors.white.withOpacity(0.3)
                            : Colors.black.withOpacity(0.3),
                      ),
                    ),

                    // ── Idioma ───────────────────────────────────────────
                    _buildDrawerTile(
                      isDark: isDarkMode,
                      icon: Icons.language,
                      title: s.language,
                      subtitle: localeProvider.isSpanish ? s.spanish : s.english,
                      trailing: Icon(
                        Icons.arrow_forward_ios,
                        color: isDarkMode ? Colors.white30 : Colors.black26,
                        size: 16,
                      ),
                      onTap: () => _showLanguageDialog(context, localeProvider, s),
                    ),

                    // ── Actualizaciones ──────────────────────────────────
                    _buildDrawerTile(
                      isDark: isDarkMode,
                      icon: Icons.system_update,
                      iconBadge: _updateAvailable && !_checkingUpdates,
                      isLoading: _checkingUpdates,
                      isHighlighted: _updateAvailable,
                      title: s.updates,
                      subtitle: _updateAvailable
                          ? s.updateAvailable
                          : (_checkingUpdates ? s.checking : s.checkUpdates),
                      trailing: Icon(
                        Icons.arrow_forward_ios,
                        color: isDarkMode ? Colors.white30 : Colors.black26,
                        size: 16,
                      ),
                      onTap: _handleUpdateButtonPressed,
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
                    
                    // ── Sobre la app ─────────────────────────────────────
                    _buildDrawerTile(
                      isDark: isDarkMode,
                      icon: Icons.info_outline,
                      title: s.about,
                      subtitle: s.infoAndVersion,
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
                  ],
                ),
              ),
            ),
          ),
          
          // Footer
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: Column(
                children: [
                  Text(
                    'Powered by: Ditxon Milan',
                    style: TextStyle(
                      color: isDarkMode ? Colors.white60 : Colors.black54,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${s.versionLabel} $_appVersion',
                    style: TextStyle(
                      color: isDarkMode
                          ? Colors.white.withOpacity(0.4)
                          : Colors.black.withOpacity(0.38),
                      fontSize: 11,
                    ),
                  ),
                  if (kBuildDate.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      '${s.buildLabel}: $kBuildDate',
                      style: TextStyle(
                        color: isDarkMode
                            ? Colors.white.withOpacity(0.3)
                            : Colors.black.withOpacity(0.28),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Widget auxiliar para cada fila del drawer — evita repetición de código.
  Widget _buildDrawerTile({
    required bool isDark,
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
    VoidCallback? onTap,
    bool iconBadge = false,
    bool isLoading = false,
    bool isHighlighted = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isHighlighted
            ? const Color(0xFFFF6B35).withOpacity(0.1)
            : (isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.black.withOpacity(0.03)),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: isHighlighted
              ? const Color(0xFFFF6B35).withOpacity(0.3)
              : (isDark
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
                color: isDark
                    ? Colors.white.withOpacity(0.1)
                    : Colors.black.withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
              ),
              child: isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isDark ? Colors.white70 : Colors.black54,
                        ),
                      ),
                    )
                  : Icon(icon,
                      color: isDark ? Colors.white70 : Colors.black54,
                      size: 22),
            ),
            if (iconBadge)
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
          title,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: isDark ? Colors.white60 : Colors.black54,
            fontSize: 13,
          ),
        ),
        trailing: trailing,
        onTap: onTap,
      ),
    );
  }

  void _showLanguageDialog(
      BuildContext ctx, LocaleProvider localeProvider, AppStrings s) {
    Navigator.pop(ctx);
    showDialog(
      context: context,
      builder: (context) {
        final isDark = Provider.of<ThemeProvider>(context, listen: false).isDarkMode;
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1D1F28) : Colors.white,
          title: Text(
            s.languageDialogTitle,
            style: TextStyle(
                color: isDark ? Colors.white : Colors.black87),
          ),
          content: Text(
            s.languageDialogContent,
            style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black54),
          ),
          actions: [
            TextButton.icon(
              icon: const Text('🇵🇪', style: TextStyle(fontSize: 18)),
              label: Text(
                s.spanish,
                style: TextStyle(
                  color: localeProvider.isSpanish
                      ? const Color(0xFFE74C3C)
                      : (isDark ? Colors.white60 : Colors.black54),
                  fontWeight: localeProvider.isSpanish
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
              onPressed: () {
                localeProvider.setLocale(const Locale('es'));
                Navigator.pop(context);
              },
            ),
            TextButton.icon(
              icon: const Text('🇺🇸', style: TextStyle(fontSize: 18)),
              label: Text(
                s.english,
                style: TextStyle(
                  color: !localeProvider.isSpanish
                      ? const Color(0xFFE74C3C)
                      : (isDark ? Colors.white60 : Colors.black54),
                  fontWeight: !localeProvider.isSpanish
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
              onPressed: () {
                localeProvider.setLocale(const Locale('en'));
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  void _showAboutDialog() {
    final s = context.read<LocaleProvider>().strings;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Provider.of<ThemeProvider>(context).isDarkMode
            ? const Color(0xFF1D1F28)
            : Colors.white,
        title: Text(
          s.aboutTitle,
          style: TextStyle(
            color: Provider.of<ThemeProvider>(context).isDarkMode
                ? Colors.white
                : Colors.black87,
          ),
        ),
        content: Text(
          s.aboutContent(_appVersion, kBuildDate),
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
              s.close,
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