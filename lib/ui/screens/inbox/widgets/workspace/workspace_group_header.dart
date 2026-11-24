import 'package:flutter/material.dart';

class WorkspaceGroupHeader extends StatelessWidget {
  final String title;
  final int count;
  final bool isDark;
  final bool isArabic;

  const WorkspaceGroupHeader({
    super.key,
    required this.title,
    required this.count,
    required this.isDark,
    required this.isArabic,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? const Color(0xFFFAFAFA) : const Color(0xFF0D0D0D);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFF4162E3).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(Icons.domain_rounded, size: 14, color: Color(0xFF4162E3)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: textPrimary,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF262626) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count ${isArabic ? (count == 1 ? 'مساحة' : 'مساحات') : (count == 1 ? 'workspace' : 'workspaces')}',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
