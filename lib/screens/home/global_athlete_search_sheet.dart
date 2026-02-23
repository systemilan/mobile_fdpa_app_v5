import 'package:flutter/material.dart';
import '../../models/athlete_search.dart';
import '../../services/event_service.dart';

class GlobalAthleteSearchSheet extends StatefulWidget {
  final EventService eventService;

  const GlobalAthleteSearchSheet({
    super.key,
    required this.eventService,
  });

  @override
  State<GlobalAthleteSearchSheet> createState() =>
      _GlobalAthleteSearchSheetState();
}

class _GlobalAthleteSearchSheetState extends State<GlobalAthleteSearchSheet> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  List<AthleteSearchResult> _results = [];
  bool _isLoading = false;
  bool _hasSearched = false;
  String _error = '';

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

  Future<void> _search() async {
    final query = _controller.text.trim();
    if (query.length < 2) return;

    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      _hasSearched = true;
      _error = '';
    });

    try {
      final response = await widget.eventService.searchAthletesGlobal(
        query,
        limit: 100,
      );
      if (mounted) {
        setState(() {
          _results = response.data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error al buscar. Verifica tu conexión e intenta de nuevo.';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 0.92,
      decoration: const BoxDecoration(
        color: Color(0xFF0D0F1A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // ── Header fijo ──
          _buildHeader(bottomPadding),

          // ── Resultados con scroll ──
          Expanded(
            child: _buildBody(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(double bottomPadding) {
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
              const Icon(Icons.person_search,
                  color: Color(0xFFE74C3C), size: 22),
              const SizedBox(width: 10),
              const Text(
                'Buscar atleta',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.close,
                      color: Colors.white54, size: 18),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Busca en todos los eventos disponibles',
            style: TextStyle(color: Colors.white38, fontSize: 12),
          ),
          const SizedBox(height: 16),

          // Campo de búsqueda
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 16),
                  textInputAction: TextInputAction.search,
                  textCapitalization: TextCapitalization.words,
                  onSubmitted: (_) => _search(),
                  decoration: InputDecoration(
                    hintText: 'Ej: GARCIA, CHAVEZ...',
                    hintStyle: const TextStyle(color: Colors.white38),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.07),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: const Icon(Icons.search,
                        color: Colors.white54, size: 22),
                    suffixIcon: _controller.text.isNotEmpty
                        ? GestureDetector(
                            onTap: () {
                              _controller.clear();
                              setState(() {
                                _results = [];
                                _hasSearched = false;
                                _error = '';
                              });
                              _focusNode.requestFocus();
                            },
                            child: const Icon(Icons.clear,
                                color: Colors.white38, size: 18),
                          )
                        : null,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: _search,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE74C3C),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.arrow_forward,
                          color: Colors.white, size: 22),
                ),
              ),
            ],
          ),

          // Contador de resultados
          if (_hasSearched && !_isLoading && _results.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              '${_results.length} resultado${_results.length != 1 ? 's' : ''} encontrados',
              style: const TextStyle(
                  color: Colors.white54, fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE74C3C)),
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
              const Icon(Icons.wifi_off, color: Colors.white24, size: 48),
              const SizedBox(height: 16),
              Text(
                _error,
                style:
                    const TextStyle(color: Colors.white54, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: _search,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE74C3C).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: const Color(0xFFE74C3C).withOpacity(0.3)),
                  ),
                  child: const Text('Reintentar',
                      style: TextStyle(
                          color: Color(0xFFE74C3C),
                          fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (!_hasSearched) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search,
                  color: Colors.white.withOpacity(0.1), size: 72),
              const SizedBox(height: 16),
              const Text(
                'Ingresa el apellido del atleta',
                style:
                    TextStyle(color: Colors.white38, fontSize: 15),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Se buscará en todos los eventos registrados',
                style:
                    TextStyle(color: Colors.white24, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (_results.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.person_off,
                  color: Colors.white24, size: 56),
              const SizedBox(height: 16),
              const Text(
                'No se encontraron resultados',
                style: TextStyle(
                    color: Colors.white54,
                    fontSize: 16,
                    fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              const Text(
                'Intenta con el apellido completo o en mayúsculas',
                style:
                    TextStyle(color: Colors.white38, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      itemCount: _results.length,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _buildResultCard(_results[index]),
      ),
    );
  }

  Widget _buildResultCard(AthleteSearchResult item) {
    final result = item.result;
    final isFirst = result.position == 1;
    final Color accentColor =
        isFirst ? const Color(0xFF2ECC71) : const Color(0xFFE74C3C);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isFirst
              ? const Color(0xFF2ECC71).withOpacity(0.25)
              : Colors.white.withOpacity(0.08),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Cabecera: evento ──
          if (item.event != null)
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.03),
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(14)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.emoji_events_outlined,
                      color: Color(0xFFE74C3C), size: 14),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      item.event!.shortName,
                      style: const TextStyle(
                        color: Color(0xFFE74C3C),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

          // ── Cuerpo ──
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Jornada + prueba
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item.jornada.shortName,
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.eventTest.displayedName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '${item.serie.name}  ·  ${item.jornada.longName}',
                  style: const TextStyle(
                      color: Colors.white38, fontSize: 11),
                ),

                const SizedBox(height: 10),
                Divider(
                    height: 1, color: Colors.white.withOpacity(0.06)),
                const SizedBox(height: 10),

                // Nombre del atleta
                Text(
                  result.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.2,
                  ),
                ),
                if (result.team.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    result.teamFormatted,
                    style: const TextStyle(
                        color: Colors.white54, fontSize: 12),
                  ),
                ],

                const SizedBox(height: 10),

                // Posición + resultado
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isFirst) ...[
                            Icon(Icons.emoji_events,
                                color: accentColor, size: 13),
                            const SizedBox(width: 4),
                          ],
                          Text(
                            result.position != null
                                ? 'Puesto ${result.position}'
                                : '--',
                            style: TextStyle(
                              color: accentColor,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      result.displayTime,
                      style: TextStyle(
                        color: isFirst ? accentColor : Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (result.lane != null) ...[
                      const Spacer(),
                      Text(
                        'Carril ${result.lane}',
                        style: const TextStyle(
                            color: Colors.white38, fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
