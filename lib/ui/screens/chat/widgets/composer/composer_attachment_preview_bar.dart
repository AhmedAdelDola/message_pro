import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';

class ComposerAttachmentPreviewBar extends StatelessWidget {
  final List<String> attachedPaths;
  final int maxAttachmentsLimit;
  final bool isAttachingSnippet;
  final ValueChanged<int> onRemove;

  const ComposerAttachmentPreviewBar({
    super.key,
    required this.attachedPaths,
    required this.maxAttachmentsLimit,
    required this.isAttachingSnippet,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    if (attachedPaths.isEmpty && !isAttachingSnippet) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Container(
      height: 52,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          if (attachedPaths.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Center(
                child: Text(
                  '${attachedPaths.length}/$maxAttachmentsLimit',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          if (isAttachingSnippet)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isArabic
                        ? 'جاري إرفاق صورة الرد الجاهز...'
                        : 'Attaching snippet image...',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ...List.generate(attachedPaths.length, (index) {
            final path = attachedPaths[index];
            final name = path.split(Platform.pathSeparator).last.split('/').last;
            final ext = name.contains('.') ? name.split('.').last.toLowerCase() : '';
            final isImage = ['png', 'jpg', 'jpeg', 'webp', 'gif'].contains(ext);
            final isVideo = ['mp4', 'mov', 'avi', 'mkv', 'webm', '3gp'].contains(ext);
            final isAudio = ['mp3', 'wav', 'ogg', 'm4a', 'aac'].contains(ext);

            return Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF212121) : const Color(0xFFEAEAEA),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isImage)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.file(
                        File(path),
                        width: 38,
                        height: 38,
                        fit: BoxFit.cover,
                      ),
                    )
                  else if (isVideo)
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B5CF6),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(
                        Icons.videocam_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    )
                  else if (isAudio)
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(
                        Icons.audiotrack_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    )
                  else
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(
                        Icons.insert_drive_file_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  const SizedBox(width: 6),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 90),
                    child: Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                  InkWell(
                    onTap: () => onRemove(index),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.close_rounded, size: 16),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
