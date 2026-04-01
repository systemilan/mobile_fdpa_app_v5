import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/athlete_search.dart';
import '../../services/event_service.dart';

/// Bottom sheet de búsqueda de atleta dentro de una prueba específica.
/// Usa el endpoint GET /event-tests/:eventTestId/search-athlete?q=TEXTO
/// con debounce de 400ms y mínimo 2 caracteres.
class EventTestAthleteSearchSheet extends StatefulWidget {
  final String eventTestId;
  final EventService eventService;

  const EventTestAthleteSearchSheet({
    super.key,
    required this.eventTestId,
    required this.eventService,
  });

  @override
  State<EventTestAthleteSearchSheet> createState() =>
      _EventTestAthleteSearchSheetState();
}

class _EventTestAthleteSearchSheetState
    extends State<EventTestAthleteSearchSheet> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  List<EventTestSearchResult> _results = [];
  bool _isLoading = false;
  bool _hasSearched = false;
  String _error = '';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    _debounce?.cancel();
    final query = _controller.text.trim();
    if (query.length < 2) {
      if (_hasSearched || _results.isNotEmpty) {
        setState(() {
          _results = [];
          _hasSearched = false;
          _error = '';
          _isLoading = false;
        });
      }
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () => _search(query));
  }

  Future<void> _search(String query) async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _hasSearched = true;
      _error = '';
    });

    try {
      final response =
          await widget.eventService.searchAthleteInTest(widget.eventTestId, query);
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
    final screenH = MediaQuery.of(context).size.height;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1D1F28),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      constraints: BoxConstraints(maxHeight: screenH * 0.85),
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
            'Escriba nombre o apellido (en cualquier orden)',
            style: TextStyle(color: Colors.white54, fontSize: 13),
          ),
          const SizedBox(height: 16),

          // Campo de búsqueda
          TextField(
            controller: _controller,
            focusNode: _focusNode,
            style: const TextStyle(color: Colors.white),
            textInputAction: TextInputAction.search,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              hintText: 'Escriba el nombre o apellido',
              hintStyle: const TextStyle(color: Colors.white38),
              filled: true,
              fillColor: Colors.white.withOpacity(0.07),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              prefixIcon:
                  const Icon(Icons.search, color: Colors.white54, size: 22),
              suffixIcon: _controller.text.isNotEmpty
                  ? GestureDetector(
                      onTap: () {
                        _controller.clear();
                        _focusNode.requestFocus();
                      },
                      child: const Icon(Icons.clear,
                          color: Colors.white38, size: 20),
                    )
                  : null,
            ),
          ),

          const SizedBox(height: 16),

          // Área de resultados
          Flexible(
            child: _buildBody(),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE74C3C)),
          ),
        ),
      );
    }

    if (_error.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
      );
    }

    if (_hasSearched && _results.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.person_search, color: Colors.white24, size: 48),
              const SizedBox(height: 12),
              Text(
                'No se encontró "${_controller.text.trim()}"',
                style:
                    const TextStyle(color: Colors.white54, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              const Text(
                'Prueba con otro nombre o documento',
                style: TextStyle(color: Colors.white38, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    if (!_hasSearched) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search, color: Colors.white12, size: 48),
              SizedBox(height: 12),
              Text(
                'Escribe al menos 2 caracteres',
                style: TextStyle(color: Colors.white38, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      itemCount: _results.length,
      itemBuilder: (context, index) {
        return _buildResultCard(_results[index]);
      },
    );
  }

  Widget _buildResultCard(EventTestSearchResult item) {
    final result = item.result;
    final serie = item.serie;
    final hasMark = result.hasResult;
    final isDNS = result.isDNS;

    Color markColor;
    if (isDNS) {
      markColor = Colors.orange.shade400;
    } else if (hasMark) {
      markColor = const Color(0xFF5DCA88);
    } else {
      markColor = Colors.white38;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.09),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            // Posición / badge
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isDNS
                    ? Colors.orange.withOpacity(0.12)
                    : hasMark
                        ? const Color(0xFF5DCA88).withOpacity(0.12)
                        : Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Text(
                result.displayPosition,
                style: TextStyle(
                  color: isDNS
                      ? Colors.orange.shade400
                      : hasMark
                          ? const Color(0xFF5DCA88)
                          : Colors.white54,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Nombre + serie + calle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    result.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      // Serie chip
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE74C3C).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          serie.name,
                          style: const TextStyle(
                            color: Color(0xFFE74C3C),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (result.lane != null) ...[
                        const SizedBox(width: 6),
                        Text(
                          'Calle ${result.lane}',
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 11,
                          ),
                        ),
                      ],
                      if (result.team.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            result.team,
                            style: const TextStyle(
                              color: Colors.white38,
                              fontSize: 11,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),

            // Marca / tiempo / status
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  result.displayMark,
                  style: TextStyle(
                    color: markColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (!hasMark && !isDNS)
                  const Text(
                    'Pendiente',
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 10,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
