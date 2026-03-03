import 'package:flutter/material.dart';
import '../../services/minimum_mark_service.dart';

class MinimumMarkDownloadButton extends StatefulWidget {
  final String fileUrl;
  final String? fileType;

  const MinimumMarkDownloadButton({
    super.key,
    required this.fileUrl,
    required this.fileType,
  });

  @override
  State<MinimumMarkDownloadButton> createState() =>
      _MinimumMarkDownloadButtonState();
}

class _MinimumMarkDownloadButtonState
    extends State<MinimumMarkDownloadButton> {
  final MinimumMarkService _service = MinimumMarkService();
  bool _loading = false;

  Future<void> _download() async {
    setState(() => _loading = true);
    try {
      await _service.openFile(widget.fileUrl, widget.fileType);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPdf = widget.fileType == 'pdf';
    return GestureDetector(
      onTap: _loading ? null : _download,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1B2E),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withOpacity(0.15)),
        ),
        child: _loading
            ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isPdf ? Icons.picture_as_pdf : Icons.image_outlined,
                    color: Colors.white70,
                    size: 14,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    isPdf ? 'Descargar PDF' : 'Descargar imagen',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
