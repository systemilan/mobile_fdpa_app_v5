import 'package:flutter/material.dart';
import '../../models/athlete_search.dart';
import '../../services/event_service.dart';

class AthleteSearchSheet extends StatefulWidget {
  final String eventId;
  final EventService eventService;

  const AthleteSearchSheet({
    super.key,
    required this.eventId,
    required this.eventService,
  });

  @override
  State<AthleteSearchSheet> createState() => _AthleteSearchSheetState();
}

class _AthleteSearchSheetState extends State<AthleteSearchSheet> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  List<AthleteSearchResult> _results = [];
  bool _isLoading = false;
  bool _hasSearched = false;
  String _error = '';

  @override
  void initState() {
    super.initState();
    // Abrir teclado automáticamente al mostrar el sheet
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
      final response =
          await widget.eventService.searchAthlete(widget.eventId, query);
      if (mounted) {
        setState(() {
          _results = response.data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error al buscar. Intenta de nuevo.';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1D1F28),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, bottomPadding + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
          const Text(
            'Buscar atleta',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Ingresa el apellido del atleta',
            style: TextStyle(color: Colors.white54, fontSize: 13),
          ),
          const SizedBox(height: 16),

          // Campo de búsqueda + botón
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  style: const TextStyle(color: Colors.white),
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _search(),
                  decoration: InputDecoration(
                    hintText: 'Ej: CHAVEZ',
                    hintStyle: const TextStyle(color: Colors.white38),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.07),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon:
                        const Icon(Icons.search, color: Colors.white54, size: 22),
                  ),
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
                  child: const Icon(Icons.arrow_forward,
                      color: Colors.white, size: 22),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Área de resultados
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: CircularProgressIndicator(
                  valueColor:
                      AlwaysStoppedAnimation<Color>(Color(0xFFE74C3C)),
                ),
              ),
            )
          else if (_error.isNotEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Column(
                  children: [
                    const Icon(Icons.wifi_off, color: Colors.white24, size: 40),
                    const SizedBox(height: 12),
                    Text(
                      _error,
                      style: const TextStyle(color: Colors.white54, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else if (_hasSearched && _results.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Column(
                  children: [
                    const Icon(Icons.person_search,
                        color: Colors.white24, size: 48),
                    const SizedBox(height: 12),
                    const Text(
                      'No se encontraron resultados',
                      style: TextStyle(color: Colors.white54, fontSize: 15),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Intenta con el apellido completo',
                      style: TextStyle(color: Colors.white38, fontSize: 13),
                    ),
                  ],
                ),
              ),
            )
          else if (_results.isNotEmpty) ...[
            Text(
              '${_results.length} resultado${_results.length != 1 ? 's' : ''}',
              style: const TextStyle(color: Colors.white54, fontSize: 13),
            ),
            const SizedBox(height: 10),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.48,
              ),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _results.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) =>
                    _buildResultCard(_results[index]),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildResultCard(AthleteSearchResult item) {
    final result = item.result;
    final isFirst = result.position == 1;
    final Color posColor =
        isFirst ? const Color(0xFF2ECC71) : Colors.white;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isFirst
            ? const Color(0xFF2ECC71).withOpacity(0.05)
            : Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
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
          // Jornada + prueba
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFE74C3C).withOpacity(0.18),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  item.jornada.shortName,
                  style: const TextStyle(
                    color: Color(0xFFE74C3C),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item.eventTest.test.officialName,
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
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),

          const SizedBox(height: 10),
          Container(
              height: 1, color: Colors.white.withOpacity(0.06)),
          const SizedBox(height: 10),

          // Nombre del atleta + equipo
          Text(
            result.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (result.team.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              result.teamFormatted,
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],

          const SizedBox(height: 10),

          // Posición + tiempo
          Row(
            children: [
              // Badge posición
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isFirst
                      ? const Color(0xFF2ECC71).withOpacity(0.15)
                      : Colors.white.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isFirst) ...[
                      const Icon(Icons.emoji_events,
                          color: Color(0xFF2ECC71), size: 13),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      result.position != null ? '#${result.position}' : '--',
                      style: TextStyle(
                        color: posColor,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Tiempo / resultado
              Text(
                result.displayTime,
                style: TextStyle(
                  color: posColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),

              // Carril (si existe)
              if (result.lane != null) ...[
                const Spacer(),
                Text(
                  'Carril ${result.lane}',
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
