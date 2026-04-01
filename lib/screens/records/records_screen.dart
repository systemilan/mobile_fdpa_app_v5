import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../config/environment.dart';
import '../../services/national_record_service.dart';
import '../../models/national_record.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_strings.dart';
import '../../providers/locale_provider.dart';

class RecordsScreen extends StatefulWidget {
  final bool? initialIsMinimumMarks;
  
  const RecordsScreen({super.key, this.initialIsMinimumMarks});

  @override
  _RecordsScreenState createState() => _RecordsScreenState();
}

class _RecordsScreenState extends State<RecordsScreen>
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
  late Animation<double> _actionsFadeAnimation;
  late Animation<Offset> _actionsSlideAnimation;
  late Animation<double> _recordsFadeAnimation;
  late Animation<Offset> _recordsSlideAnimation;

  // Estados para filtros y búsqueda
  int _selectedCategoryIndex = 0;
  late int _selectedTypeIndex;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  
  // Estados para API
  final NationalRecordService _recordService = NationalRecordService();
  List<String> _categories = [];
  List<NationalRecord> _records = [];
  bool _isLoading = true;
  String? _errorMessage;
  NationalRecordStatistics? _statistics;
  
  List<String> get _typeLabels => [
    context.read<LocaleProvider>().strings.nationalRecords,
    context.read<LocaleProvider>().strings.minimumMarks,
  ];

  // Fechas de actualización desde la API
  String _nationalRecordsDate = '';
  String _minimumMarksDate = '';

  @override
  void initState() {
    super.initState();
    
    // Inicializar tipo según parámetro
    _selectedTypeIndex = widget.initialIsMinimumMarks == true ? 1 : 0;
    
    // Inicializar controladores de animación
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

    _actionsFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _staggeredController,
        curve: const Interval(0.4, 0.7, curve: Curves.easeOut),
      ),
    );
    _actionsSlideAnimation = Tween<Offset>(begin: const Offset(0.3, 0), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _staggeredController,
        curve: const Interval(0.4, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    _recordsFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _staggeredController,
        curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
      ),
    );
    _recordsSlideAnimation = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _staggeredController,
        curve: const Interval(0.6, 1.0, curve: Curves.easeOutBack),
      ),
    );

    // Cargar datos de la API
    _loadData();
    _loadUpdateDates();

    // Iniciar animaciones con delay
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        _fadeController.forward();
        _slideController.forward();
        _staggeredController.forward();
      }
    });
  }

  Future<void> _loadUpdateDates() async {
    final s = context.read<LocaleProvider>().strings;
    try {
      final url = Uri.parse('${Environment.publicBaseUrl}/app/update-dates');
      final response = await http.get(url).timeout(Environment.connectTimeout);
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final data = json['data'];
        if (mounted) {
          setState(() {
            _nationalRecordsDate = _formatDate(data['nationalRecords']?['lastUpdated'], updatedLabel: s.updated);
            _minimumMarksDate = _formatDate(data['minimumMarks']?['lastUpdated'], updatedLabel: s.updated);
          });
        }
      }
    } catch (_) {
      // Mantener valor por defecto
    }
  }

  String _formatDate(String? isoDate, {String updatedLabel = 'Act.'}) {
    if (isoDate == null) return '--';
    try {
      final dt = DateTime.parse(isoDate).toLocal();
      return '$updatedLabel ${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (_) {
      return '--';
    }
  }

  /// Cargar categorías y estadísticas
  Future<void> _loadData() async {
    final s = context.read<LocaleProvider>().strings;
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Cargar estadísticas (incluye categorías con categoryOrder)
      final statistics = await _recordService.getStatistics();

      // Ordenar categorías por categoryOrder tal como viene del servidor
      final sortedCategories = List<CategoryStat>.from(statistics.categories)
        ..sort((a, b) => a.categoryOrder.compareTo(b.categoryOrder));
      final categories = sortedCategories.map((c) => c.category).toList();

      if (mounted) {
        setState(() {
          _categories = categories;
          _statistics = statistics;
          _isLoading = false;
        });

        // Cargar récords de la primera categoría
        if (_categories.isNotEmpty) {
          await _loadRecordsByCategory(_categories[0]);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = s.errorLoadingData(e.toString());
        });
      }
    }
  }

  /// Cargar récords por categoría
  Future<void> _loadRecordsByCategory(String category) async {
    final s = context.read<LocaleProvider>().strings;
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final records = await _recordService.getRecordsByCategory(category);

      if (mounted) {
        setState(() {
          _records = records;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = s.errorLoadingRecords(e.toString());
        });
      }
    }
  }

  /// Buscar por atleta
  Future<void> _searchByAthlete(String name) async {
    final s = context.read<LocaleProvider>().strings;
    if (name.isEmpty) {
      // Si está vacío, cargar récords de la categoría actual
      if (_categories.isNotEmpty) {
        await _loadRecordsByCategory(_categories[_selectedCategoryIndex]);
      }
      return;
    }

    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final records = await _recordService.searchByAthlete(name);

      if (mounted) {
        setState(() {
          _records = records;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = s.errorInSearch(e.toString());
        });
      }
    }
  }

  /// Descargar PDF de récords nacionales
  Future<void> _downloadPdf() async {
    final s = context.read<LocaleProvider>().strings;
    try {
      // Mostrar indicador de carga
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
                Text(s.downloadingPdf),
              ],
            ),
            duration: const Duration(seconds: 30),
          ),
        );
      }

      final filePath = await _recordService.downloadRecordsPdf();

      if (mounted) {
        // Ocultar indicador de carga
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        
        // Mostrar mensaje de éxito
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(s.pdfDownloaded(filePath)),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: s.ok,
              textColor: Colors.white,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        // Ocultar indicador de carga
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        
        // Mostrar mensaje de error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(s.errorDownloadPdf(e.toString())),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _staggeredController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF040512),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Column(
            children: [
              // Header con imagen de fondo
              Container(
                width: double.infinity,
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height * 0.13,
                  maxHeight: MediaQuery.of(context).size.height * 0.32,
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
                          const SizedBox(height: 4),
                          Flexible(
                            child: FadeTransition(
                              opacity: _headerFadeAnimation,
                              child: SlideTransition(
                                position: _headerSlideAnimation,
                                child: _buildHeader(),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Flexible(
                            child: FadeTransition(
                              opacity: _titleFadeAnimation,
                              child: SlideTransition(
                                position: _titleSlideAnimation,
                                child: _buildTitleSection(),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Flexible(
                            child: FadeTransition(
                              opacity: _actionsFadeAnimation,
                              child: SlideTransition(
                                position: _actionsSlideAnimation,
                                child: _buildActionBar(),
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
                child: SafeArea(
                  top: false,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFilters(),
                        const SizedBox(height: 20),
                        FadeTransition(
                          opacity: _recordsFadeAnimation,
                          child: SlideTransition(
                            position: _recordsSlideAnimation,
                            child: _buildRecordsSection(),
                          ),
                        ),
                      ],
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

  Widget _buildHeader() {
    final s = context.read<LocaleProvider>().strings;
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
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  s.federationLine1,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                ),
                Text(
                  s.federationLine2,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
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
    final s = context.read<LocaleProvider>().strings;
    // Obtener nombre de categoría actual
    final currentCategory = _categories.isNotEmpty 
        ? _categories[_selectedCategoryIndex] 
        : s.loading;

    // Obtener fecha de última actualización desde update-dates API
    final rawDate = _selectedTypeIndex == 0 ? _nationalRecordsDate : _minimumMarksDate;
    final lastUpdateText = rawDate.isEmpty ? s.loading : rawDate;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            '${_typeLabels[_selectedTypeIndex]} - $currentCategory',
            style: TextStyle(
              color: Colors.white,
              fontSize: MediaQuery.of(context).size.width < 400 ? 14 : 16,
              fontWeight: FontWeight.w800,
              height: 1.0,
              letterSpacing: -0.5,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.left,
          ),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            lastUpdateText,
            style: const TextStyle(
              color: Color(0xFFE74C3C),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.left,
          ),
        ),
      ],
    );
  }

  Widget _buildActionBar() {
    final s = context.read<LocaleProvider>().strings;
    return Row(
      children: [
        // Buscador
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.white.withOpacity(0.15),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.search,
                  color: Colors.white70,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                    decoration: InputDecoration(
                      hintText: s.enterNameSurname,
                      hintStyle: const TextStyle(
                        color: Colors.white54,
                        fontSize: 14,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.toLowerCase();
                      });
                      // Buscar en la API
                      if (value.length >= 3) {
                        _searchByAthlete(value);
                      } else if (value.isEmpty && _categories.isNotEmpty) {
                        _loadRecordsByCategory(_categories[_selectedCategoryIndex]);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 15),
        // Botón de descarga - solo visible en móvil
        if (!kIsWeb)
          GestureDetector(
            onTap: _downloadPdf,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.download,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    s.pdf,
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
      ],
    );
  }

  Widget _buildFilters() {
    if (_categories.isEmpty) {
      return const SizedBox.shrink();
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _categories.asMap().entries.map((entry) {
          int index = entry.key;
          String category = entry.value;
          bool isSelected = _selectedCategoryIndex == index;
          
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedCategoryIndex = index;
              });
              // Cargar récords de la nueva categoría
              _loadRecordsByCategory(category);
            },
            child: Container(
              margin: EdgeInsets.only(right: index < _categories.length - 1 ? 10 : 0),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFE74C3C) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFFE74C3C)
                      : const Color(0xFFE74C3C).withOpacity(0.22),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isSelected
                        ? const Color(0xFFE74C3C).withOpacity(0.28)
                        : Colors.black.withOpacity(0.08),
                    blurRadius: isSelected ? 8 : 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  category,
                  style: TextStyle(
                    color: isSelected 
                      ? Colors.white
                      : const Color(0xFFE74C3C),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRecordsSection() {
    final s = context.read<LocaleProvider>().strings;
    // Mostrar indicador de carga
    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.all(40),
        child: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE74C3C)),
          ),
        ),
      );
    }

    // Mostrar mensaje de error
    if (_errorMessage != null) {
      return Container(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.withOpacity(0.6),
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadData,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE74C3C),
                foregroundColor: Colors.white,
              ),
              child: Text(s.retry),
            ),
          ],
        ),
      );
    }

    // Mostrar mensaje cuando no hay récords
    if (_records.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.white.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              s.noRecordsFound,
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (_searchQuery.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                s.forQuery(_searchQuery),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
      );
    }

    // Mostrar récords
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white.withOpacity(0.02),
      ),
      child: Column(
        children: _records.asMap().entries.map((entry) {
          int index = entry.key;
          NationalRecord record = entry.value;
          
          return _buildRecordCard(record, index, _records.length);
        }).toList(),
      ),
    );
  }

  Widget _buildRecordCard(NationalRecord record, int index, int totalRecords) {
    final bool isSearchMode = _searchQuery.trim().length >= 3;

    BorderRadius? borderRadius;
    if (totalRecords == 1) {
      borderRadius = BorderRadius.circular(12);
    } else if (index == 0) {
      borderRadius = const BorderRadius.only(
        topLeft: Radius.circular(12),
        topRight: Radius.circular(12),
      );
    } else if (index == totalRecords - 1) {
      borderRadius = const BorderRadius.only(
        bottomLeft: Radius.circular(12),
        bottomRight: Radius.circular(12),
      );
    }

    // Formatear fecha
    final formattedDate =
        '${record.recordDate.day.toString().padLeft(2, '0')}/'
        '${record.recordDate.month.toString().padLeft(2, '0')}/'
        '${record.recordDate.year}';

    // Detectar si es posta/equipo: más de un "(xx)" en el campo de atleta.
    // Los nombres pueden venir separados por coma O por espacio.
    final parenCount = RegExp(r'\(\d{2}\)').allMatches(record.athlete).length;
    final isRelay = parenCount > 1;

    // Separar atletas: primero intentar por coma; si no hay comas, separar por el
    // patrón "YY) NombreApellido" usando lookahead para no perder los paréntesis.
    List<String> athleteParts;
    if (isRelay) {
      if (record.athlete.contains(',')) {
        athleteParts = record.athlete.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
      } else {
        // Separar en cada aparición de "(NN) " seguido de mayúscula
        athleteParts = record.athlete
            .splitMapJoin(
              RegExp(r'(?<=\(\d{2}\))\s+(?=[A-ZÁÉÍÓÚÑ])'),
              onMatch: (_) => '|',
              onNonMatch: (s) => s,
            )
            .split('|')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();
      }
    } else {
      athleteParts = [record.athlete];
    }

    return GestureDetector(
      onTap: () => _showRecordDetails(record),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.03),
          borderRadius: borderRadius,
          border: index < totalRecords - 1
              ? Border(
                  bottom: BorderSide(
                    color: Colors.white.withOpacity(0.08),
                    width: 1,
                  ),
                )
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Fila 1: Prueba (izq) + Marca (der) — ambos cortos, nunca desbordan ──
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: _buildInfoChip(Icons.directions_run_rounded, record.event),
                ),
                const SizedBox(width: 8),
                // Marca destacada — tamaño fijo, no depende del nombre
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE74C3C).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFFE74C3C).withOpacity(0.4),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    '${record.record}${record.wind != null ? '  ${record.wind}' : ''}',
                    style: const TextStyle(
                      color: Color(0xFFE74C3C),
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                    maxLines: 1,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            if (isSearchMode) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.12),
                    width: 1,
                  ),
                ),
                child: Text(
                  record.category,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 8),
            ],

            // ── Fila 2: Nombre(s) atleta — ancho completo, sin competir con la marca ──
            if (isRelay)
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: athleteParts
                    .map(
                      (name) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              )
            else
              Text(
                record.athlete,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),

            const SizedBox(height: 8),

            // ── Fila 3: lugar · fecha · entrenador ──
            LayoutBuilder(
              builder: (context, constraints) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 12,
                      runSpacing: 5,
                      children: [
                        _buildInfoChip(Icons.location_on_outlined, record.place),
                        _buildInfoChip(Icons.calendar_today_outlined, formattedDate),
                      ],
                    ),
                    if (record.coach.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      SizedBox(
                        width: constraints.maxWidth,
                        child: _buildInfoChip(Icons.person_outline, record.coach),
                      ),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(icon, color: Colors.white38, size: 12),
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.white.withOpacity(0.55),
              fontSize: 11,
              height: 1.4,
            ),
            softWrap: true,
          ),
        ),
      ],
    );
  }

  void _showRecordDetails(NationalRecord record) {
    final s = context.read<LocaleProvider>().strings;
    final formattedDate =
        '${record.recordDate.day.toString().padLeft(2, '0')}/'
        '${record.recordDate.month.toString().padLeft(2, '0')}/'
        '${record.recordDate.year}';

    // Detectar posta igual que en la card
    final parenCount = RegExp(r'\(\d{2}\)').allMatches(record.athlete).length;
    final isRelay = parenCount > 1;
    List<String> athleteParts;
    if (isRelay) {
      if (record.athlete.contains(',')) {
        athleteParts = record.athlete.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
      } else {
        athleteParts = record.athlete
            .splitMapJoin(
              RegExp(r'(?<=\(\d{2}\))\s+(?=[A-ZÁÉÍÓÚÑ])'),
              onMatch: (_) => '|',
              onNonMatch: (s) => s,
            )
            .split('|')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();
      }
    } else {
      athleteParts = [record.athlete];
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF12141F),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Pill handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ── Marca grande centrada ──
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE74C3C).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFFE74C3C).withOpacity(0.5),
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    '${record.record}${record.wind != null ? '   ${record.wind}' : ''}',
                    style: const TextStyle(
                      color: Color(0xFFE74C3C),
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),

              // Prueba centrada bajo la marca
              Center(
                child: Text(
                  record.event,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ── Atleta(s) ──
              if (isRelay) ...[
                Text(
                  s.team,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.35),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: athleteParts
                      .map((name) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.07),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.12),
                              ),
                            ),
                            child: Text(
                              name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ] else ...[
                Text(
                  record.athlete,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
              ],

              const SizedBox(height: 20),
              Divider(color: Colors.white.withOpacity(0.08), height: 1),
              const SizedBox(height: 16),

              // ── Datos en grid 2 columnas ──
              Row(
                children: [
                  Expanded(child: _buildDetailTile(Icons.bookmark_outline, s.category, record.category)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildDetailTile(Icons.location_on_outlined, s.place, record.place)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildDetailTile(Icons.calendar_today_outlined, s.date, formattedDate)),
                  if (record.coach.isNotEmpty) ...[
                    const SizedBox(width: 12),
                    Expanded(child: _buildDetailTile(Icons.person_outline, s.coach, record.coach)),
                  ] else
                    const Expanded(child: SizedBox()),
                ],
              ),

              const SizedBox(height: 20),

              // ── Botón cerrar ──
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.06),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(
                    s.close,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailTile(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white30, size: 13),
              const SizedBox(width: 5),
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.35),
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$label ',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            TextSpan(
              text: value,
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
}