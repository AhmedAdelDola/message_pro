import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../../../../data/models/message.dart';

class WorkflowStepsGroupWidget extends StatefulWidget {
  final List<Message> messages;
  final bool showDateHeader;

  const WorkflowStepsGroupWidget({
    super.key,
    required this.messages,
    this.showDateHeader = false,
  });

  @override
  State<WorkflowStepsGroupWidget> createState() => _WorkflowStepsGroupWidgetState();
}

class _WorkflowStepsGroupWidgetState extends State<WorkflowStepsGroupWidget> {
  bool _isExpanded = false;

  String _formatDate(DateTime date, bool isArabic) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final msgDate = DateTime(date.year, date.month, date.day);

    if (msgDate == today) {
      return isArabic ? 'اليوم' : 'Today';
    } else if (msgDate == today.subtract(const Duration(days: 1))) {
      return isArabic ? 'أمس' : 'Yesterday';
    } else if (now.year == date.year) {
      return DateFormat('d MMM', isArabic ? 'ar' : 'en').format(date);
    } else {
      return DateFormat('d MMM yyyy', isArabic ? 'ar' : 'en').format(date);
    }
  }

  String _cleanText(String text) {
    return text
        .replaceAll(RegExp(r'</?(b|strong|p|span)[^>]*>', caseSensitive: false), '')
        .replaceAll('*', '')
        .trim();
  }

  Widget _buildOriginalStep(String text, bool isDark) {
    final clean = _cleanText(text);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 1.5.h, horizontal: 16.w),
      child: Center(
        child: Text(
          clean,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 10.sp,
            fontWeight: FontWeight.normal,
            height: 1.25,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.messages.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final firstMsg = widget.messages.first;
    final count = widget.messages.length;

    return Column(
      children: [
        // Date Header if required
        if (widget.showDateHeader)
          Container(
            margin: EdgeInsets.symmetric(vertical: 12.h),
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF0F0F3),
              borderRadius: BorderRadius.circular(999.r),
            ),
            child: Text(
              _formatDate(firstMsg.createdAt, isArabic),
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF626F7F),
              ),
            ),
          ),

        // If 2 or fewer steps, render them directly in original look
        if (count <= 2) ...[
          for (final msg in widget.messages)
            _buildOriginalStep(msg.content ?? '', isDark),
        ] else if (!_isExpanded) ...[
          // Collapsed: Show first step, "عرض الكل" button between them, then last step
          _buildOriginalStep(widget.messages.first.content ?? '', isDark),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 2.h),
            child: Center(
              child: TextButton.icon(
                onPressed: () {
                  setState(() {
                    _isExpanded = true;
                  });
                },
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 2.h),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  foregroundColor: isDark ? const Color(0xFF818CF8) : const Color(0xFF4F46E5),
                ),
                icon: Icon(Icons.expand_more_rounded, size: 15.r),
                label: Text(
                  isArabic
                      ? 'عرض باقي الخطوات (${count - 2})'
                      : 'Show remaining steps (${count - 2})',
                  style: TextStyle(
                    fontSize: 10.5.sp,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ),
            ),
          ),
          _buildOriginalStep(widget.messages.last.content ?? '', isDark),
        ] else ...[
          // Expanded: Show all steps in original look, with "إخفاء" button
          for (final msg in widget.messages)
            _buildOriginalStep(msg.content ?? '', isDark),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 2.h),
            child: Center(
              child: TextButton.icon(
                onPressed: () {
                  setState(() {
                    _isExpanded = false;
                  });
                },
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 3.h),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  foregroundColor: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
                icon: Icon(Icons.expand_less_rounded, size: 16.r),
                label: Text(
                  isArabic ? 'إخفاء الخطوات' : 'Hide steps',
                  style: TextStyle(
                    fontSize: 11.sp,
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
