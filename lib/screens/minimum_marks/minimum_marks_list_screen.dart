import 'package:flutter/material.dart';
import '../../models/minimum_mark.dart';
import '../../services/minimum_mark_service.dart';
import 'minimum_mark_detail_screen.dart';
import 'minimum_mark_download_button.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_strings.dart';
import '../../providers/locale_provider.dart';

class MinimumMarksListScreen extends StatefulWidget {
  const MinimumMarksListScreen({super.key});

  @override
  State<MinimumMarksListScreen> createState() => _MinimumMarksListScreenState();
}

class _MinimumMarksListScreenState extends State<MinimumMarksListScreen>
    with SingleTickerProviderStateMixin {
  final MinimumMarkService _service = MinimumMarkService();
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  List<MinimumMarkSet> _sets = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );
    _loadData();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final s = context.read<LocaleProvider>().strings;
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      final sets = await _service.getAll();
      if (mounted) {
        setState(() {
          _sets = sets;
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
    if (start == null && end == null) return '';
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
    return _fmt(end!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF040512),
      body: Column(
        children: [
          // Header con imagen de fondo
          Container(
            width: double.infinity,
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height * 0.15,
              maxHeight: MediaQuery.of(context).size.height * 0.28,
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
                    Colors.black.withOpacity(0.75),
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
                      _buildHeader(),
                      const SizedBox(height: 10),
                      _buildTitleSection(),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Lista
          Expanded(
            child: SafeArea(
              top: false,
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: Color(0xFFE74C3C)),
                    )
                  : _errorMessage != null
                      ? _buildError()
                      : _sets.isEmpty
                          ? _buildEmpty()
                          : FadeTransition(
                              opacity: _fadeAnimation,
                              child: RefreshIndicator(
                                color: const Color(0xFFE74C3C),
                                onRefresh: _loadData,
                                child: ListView.builder(
                                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
                                  itemCount: _sets.length,
                                  itemBuilder: (context, index) =>
                                      _buildCard(_sets[index]),
                                ),
                              ),
                            ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final s = context.read<LocaleProvider>().strings;
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
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        s.minimumMarks,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.w800,
          height: 1.0,
          letterSpacing: -0.5,
        ),
      ),
    );
  }

  Widget _buildCard(MinimumMarkSet set) {
    final s = context.read<LocaleProvider>().strings;
    final dateRange = _formatDateRange(set.dateStart, set.dateEnd);
    final hasFile = set.fileUrl != null && set.fileUrl!.isNotEmpty;
    final isPdf = set.fileType == 'pdf';

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, _) =>
              MinimumMarkDetailScreen(setId: set.id, displayName: set.displayName),
          transitionsBuilder: (context, animation, _, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF0D0E1F),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.06),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                set.displayName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                ),
              ),
              if (dateRange.isNotEmpty) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined,
                        color: Color(0xFFE74C3C), size: 13),
                    const SizedBox(width: 6),
                    Text(
                      dateRange,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
              if (set.location != null && set.location!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined,
                        color: Color(0xFFE74C3C), size: 13),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        set.location!,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE74C3C).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      s.viewMarks,
                      style: const TextStyle(
                        color: Color(0xFFE74C3C),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (hasFile)
                    MinimumMarkDownloadButton(
                      fileUrl: set.fileUrl!,
                      fileType: set.fileType,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildError() {
    final s = context.read<LocaleProvider>().strings;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFE74C3C), size: 48),
          const SizedBox(height: 12),
          Text(
            _errorMessage ?? s.unknownError,
            style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadData,
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE74C3C)),
            child: Text(s.retry),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    final s = context.read<LocaleProvider>().strings;
    return Center(
      child: Text(
        s.noMinimumMarksAvailable,
        style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14),
      ),
    );
  }
}
