import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class DocumentAttachmentTile extends StatelessWidget {
  final String fileUrl;
  final String? fileName;
  final int? fileSize;
  final String fileType;
  final bool isOutgoing;

  const DocumentAttachmentTile({
    super.key,
    required this.fileUrl,
    this.fileName,
    this.fileSize,
    required this.fileType,
    required this.isOutgoing,
  });

  String _formatFileSize(int? bytes) {
    if (bytes == null || bytes <= 0) return '';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _extractFileName() {
    if (fileName != null && fileName!.isNotEmpty) return fileName!;
    try {
      final name = fileUrl.split('/').last.split('?').first;
      if (name.isNotEmpty) return Uri.decodeComponent(name);
    } catch (_) {}
    return 'Document';
  }

  String _getFileExtension() {
    final name = _extractFileName().toLowerCase();
    final parts = name.split('.');
    if (parts.length > 1) {
      return parts.last;
    }
    return '';
  }

  IconData _getFileIcon() {
    final ext = _getFileExtension();
    if (ext == 'pdf' || fileType.toLowerCase() == 'pdf') {
      return Icons.picture_as_pdf_rounded;
    } else if (['mp4', 'mov', 'avi', 'mkv', 'webm', '3gp'].contains(ext) || fileType.toLowerCase() == 'video') {
      return Icons.play_circle_fill_rounded;
    } else if (['mp3', 'wav', 'ogg', 'm4a', 'aac'].contains(ext) || fileType.toLowerCase() == 'audio') {
      return Icons.audiotrack_rounded;
    } else if (['doc', 'docx', 'rtf'].contains(ext)) {
      return Icons.description_rounded;
    } else if (['xls', 'xlsx', 'csv'].contains(ext)) {
      return Icons.table_chart_rounded;
    } else if (['zip', 'rar', '7z', 'tar', 'gz'].contains(ext)) {
      return Icons.folder_zip_rounded;
    } else if (['ppt', 'pptx'].contains(ext)) {
      return Icons.slideshow_rounded;
    } else if (['txt'].contains(ext)) {
      return Icons.text_snippet_rounded;
    }
    return Icons.insert_drive_file_rounded;
  }

  Color _getIconBgColor() {
    final ext = _getFileExtension();
    if (ext == 'pdf' || fileType.toLowerCase() == 'pdf') {
      return const Color(0xFFEF4444); // Red
    } else if (['mp4', 'mov', 'avi', 'mkv', 'webm', '3gp'].contains(ext) || fileType.toLowerCase() == 'video') {
      return const Color(0xFF8B5CF6); // Violet / Purple
    } else if (['mp3', 'wav', 'ogg', 'm4a', 'aac'].contains(ext) || fileType.toLowerCase() == 'audio') {
      return const Color(0xFF06B6D4); // Cyan
    } else if (['doc', 'docx', 'rtf'].contains(ext)) {
      return const Color(0xFF2563EB); // Blue
    } else if (['xls', 'xlsx', 'csv'].contains(ext)) {
      return const Color(0xFF10B981); // Green
    } else if (['zip', 'rar', '7z'].contains(ext)) {
      return const Color(0xFFF59E0B); // Amber
    } else if (['ppt', 'pptx'].contains(ext)) {
      return const Color(0xFFEA580C); // Orange
    }
    return const Color(0xFF64748B); // Slate
  }

  Future<void> _openFile(BuildContext context) async {
    final uri = Uri.tryParse(fileUrl);
    if (uri != null) {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تعذر فتح الملف'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayName = _extractFileName();
    final sizeText = _formatFileSize(fileSize);
    final ext = _getFileExtension().toUpperCase();

    final cardBg = isOutgoing ? Colors.white.withValues(alpha: 0.15) : const Color(0xFFF8FAFC);
    final borderColor = isOutgoing ? Colors.white24 : const Color(0xFFE2E8F0);
    final titleColor = isOutgoing ? Colors.white : const Color(0xFF0F172A);
    final subtitleColor = isOutgoing ? Colors.white70 : const Color(0xFF64748B);

    return InkWell(
      onTap: () => _openFile(context),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        constraints: const BoxConstraints(minWidth: 200, maxWidth: 280),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor, width: 0.9),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: _getIconBgColor(),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getFileIcon(),
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: titleColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      if (ext.isNotEmpty) ...[
                        Text(
                          ext,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: isOutgoing ? Colors.white.withValues(alpha: 0.9) : _getIconBgColor(),
                          ),
                        ),
                        if (sizeText.isNotEmpty)
                          Text(
                            ' • ',
                            style: TextStyle(fontSize: 10.5, color: subtitleColor),
                          ),
                      ],
                      if (sizeText.isNotEmpty)
                        Text(
                          sizeText,
                          style: TextStyle(
                            fontSize: 10.5,
                            color: subtitleColor,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.download_rounded,
              size: 18,
              color: subtitleColor,
            ),
          ],
        ),
      ),
    );
  }
}
