import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_strings.dart';
import '../../providers/locale_provider.dart';
import '../../models/minimum_mark.dart';
import '../../services/minimum_mark_service.dart';
import 'minimum_mark_download_button.dart';

class MinimumMarkDetailScreen extends StatefulWidget {
  final String setId;
  final String displayName;

  const MinimumMarkDetailScreen({
    super.key,
    required this.setId,
    required this.displayName,
  });

  @override
  State<MinimumMarkDetailScreen> createState() =>
      _MinimumMarkDetailScreenState();
}

class _MinimumMarkDetailScreenState extends State<MinimumMarkDetailScreen>
    with SingleTickerProviderStateMixin {
  final MinimumMarkService _service = MinimumMarkService();
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  MinimumMarkDetail? _detail;
  bool _isLoading = true;
  String? _errorMessage;

  AppStrings get s => context.read<LocaleProvider>().strings;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);
    _loadData();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      final detail = await _service.getById(widget.setId);
      if (mounted) {
        setState(() {
          _detail = detail;
          _isLoading = false;
        });
        _fadeController.forward();
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

  String _formatDateRange(String? start, String? end) {
    String _fmt(String d) {
      try {
        final dt = DateTime.parse(d);
        return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
      } catch (_) {
        return d;
      }
    }

    if (start != null && end != null) return '${_fmt(start)} – ${_fmt(end)}';
    if (start != null) return _fmt(start);
    if (end != null) return _fmt(end);
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final detail = _detail;
    final hasFile = detail != null &&
        detail.fileUrl != null &&
        detail.fileUrl!.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFF040512),
      body: Column(
        children: [
          // Header con imagen de fondo
          Container(
            width: double.infinity,
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height * 0.15,
              maxHeight: MediaQuery.of(context).size.height * 0.32,
            ),
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/botom1.jpg'),
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
                    Colors.black.withOpacity(0.80),
                  ],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      _buildTopBar(detail, hasFile),
                      const SizedBox(height: 10),
                      // Nombre del set
                      Text(
                        detail?.displayName ?? widget.displayName,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize:
                              MediaQuery.of(context).size.width < 400 ? 17 : 20,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                          letterSpacing: -0.3,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (detail != null) ...[
                        const SizedBox(height: 6),
                        _buildMeta(detail),
                      ],
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Contenido
          Expanded(
            child: SafeArea(
              top: false,
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: Color(0xFFE74C3C)),
                    )
                  : _errorMessage != null
                      ? _buildError()
                      : detail == null
                          ? const SizedBox()
                          : FadeTransition(
                              opacity: _fadeAnimation,
                              child: _buildMarksTable(detail),
                            ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(MinimumMarkDetail? detail, bool hasFile) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
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
            // Botón descarga en el header si fileUrl != null
            if (hasFile && detail != null)
              MinimumMarkDownloadButton(
                fileUrl: detail.fileUrl!,
                fileType: detail.fileType,
              ),
            const SizedBox(width: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 28,
                  height: 34,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.asset(
                      'assets/images/fdpa_logo.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
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
        ),
      ],
    );
  }

  Widget _buildMeta(MinimumMarkDetail detail) {
    final dateRange = _formatDateRange(detail.dateStart, detail.dateEnd);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (dateRange.isNotEmpty)
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined,
                  color: Color(0xFFE74C3C), size: 13),
              const SizedBox(width: 6),
              Text(
                dateRange,
                style: TextStyle(
                    color: Colors.white.withOpacity(0.75), fontSize: 13),
              ),
            ],
          ),
        if (detail.location != null && detail.location!.isNotEmpty) ...[
          const SizedBox(height: 3),
          Row(
            children: [
              const Icon(Icons.location_on_outlined,
                  color: Color(0xFFE74C3C), size: 13),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  detail.location!,
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.75), fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildMarksTable(MinimumMarkDetail detail) {
    if (detail.marks.isEmpty) {
      return Center(
        child: Text(
          s.noMarksRegistered,
          style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14),
        ),
      );
    }

    return Column(
      children: [
        // Encabezado de tabla
        Container(
          color: const Color(0xFF0D0E1F),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Expanded(
                flex: 5,
                child: Text(
                  s.event,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  s.men,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  s.women,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: Color(0xFF1A1B2E)),
        // Filas
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.only(bottom: 24),
            itemCount: detail.marks.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, color: Color(0xFF1A1B2E)),
            itemBuilder: (context, index) {
              final mark = detail.marks[index];
              final isEven = index % 2 == 0;
              return Container(
                color: isEven
                    ? const Color(0xFF040512)
                    : const Color(0xFF080917),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      flex: 5,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            mark.test.officialName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (mark.test.type != null &&
                              mark.test.type!.isNotEmpty &&
                              double.tryParse(mark.test.type!) == null)
                            Text(
                              mark.test.type!,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.4),
                                fontSize: 11,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        mark.varones ?? '—',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF4FC3F7),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        mark.damas ?? '—',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFFFFB3C1),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFE74C3C), size: 48),
          const SizedBox(height: 12),
          Text(
            _errorMessage ?? s.unknownError,
            style:
                TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadData,
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE74C3C)),
            child: Text(s.retry),
          ),
        ],
      ),
    );
  }
}
