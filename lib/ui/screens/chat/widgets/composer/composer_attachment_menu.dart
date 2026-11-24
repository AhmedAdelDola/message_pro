import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

class ComposerAttachmentMenu extends StatelessWidget {
  final VoidCallback onPickMedia;
  final VoidCallback onPickCamera;
  final VoidCallback onPickFile;

  const ComposerAttachmentMenu({
    super.key,
    required this.onPickMedia,
    required this.onPickCamera,
    required this.onPickFile,
  });

  static Future<void> show({
    required BuildContext context,
    required VoidCallback onPickMedia,
    required VoidCallback onPickCamera,
    required VoidCallback onPickFile,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF161616) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => ComposerAttachmentMenu(
        onPickMedia: onPickMedia,
        onPickCamera: onPickCamera,
        onPickFile: onPickFile,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF31343A) : const Color(0xFFEAEAEA),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF4162E3).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const HugeIcon(
                icon: HugeIcons.strokeRoundedImage01,
                color: Color(0xFF4162E3),
                size: 20,
              ),
            ),
            title: Text(
              isArabic ? 'الصور والفيديوهات' : 'Photos & Videos',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              isArabic
                  ? 'اختيار من المعرض (حتى 5 عناصر)'
                  : 'Select from gallery (up to 5)',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
            onTap: () {
              Navigator.pop(context);
              onPickMedia();
            },
          ),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF4162E3).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const HugeIcon(
                icon: HugeIcons.strokeRoundedCamera01,
                color: Color(0xFF4162E3),
                size: 20,
              ),
            ),
            title: Text(
              isArabic ? 'الكاميرا' : 'Camera',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              isArabic ? 'التقاط صورة مباشرة' : 'Take a photo directly',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
            onTap: () {
              Navigator.pop(context);
              onPickCamera();
            },
          ),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF4162E3).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const HugeIcon(
                icon: HugeIcons.strokeRoundedFile01,
                color: Color(0xFF4162E3),
                size: 20,
              ),
            ),
            title: Text(
              isArabic ? 'المستندات والملفات' : 'Documents & Files',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              isArabic
                  ? 'PDF، Word، Excel والمستندات الأخرى'
                  : 'PDF, Word, Excel, and other files',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
            onTap: () {
              Navigator.pop(context);
              onPickFile();
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
