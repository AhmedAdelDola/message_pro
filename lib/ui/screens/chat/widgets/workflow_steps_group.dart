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

  String _formatTime(DateTime date) {
    return DateFormat('h:mm a').format(date);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.messages.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final firstMsg = widget.messages.first;

    final cardBg = isDark ? const Color(0xFF1B1E24) : const Color(0xFFF8FAFC);
    final borderColor = isDark ? const Color(0xFF2E333D) : const Color(0xFFE2E8F0);
    final textMuted = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final accentColor = const Color(0xFF6366F1);

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
                fontFamily: 'Gontserrat',
              ),
            ),
          ),

        // Workflow Group Card
        Container(
          margin: EdgeInsets.symmetric(horizontal: 14.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: borderColor, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                blurRadius: 4,
                offset: const Offset(0, 1.5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Row with count and Collapse / Expand TextButton
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(5.r),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Icon(
                        Icons.account_tree_outlined,
                        size: 15.r,
                        color: accentColor,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        isArabic
                            ? '${widget.messages.length} خطوات سير العمل والأتمتة'
                            : '${widget.messages.length} Workflow automation steps',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF1E293B),
                          fontFamily: 'Gontserrat',
                        ),
                      ),
                    ),
                    // Collapse / Expand TextButton
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _isExpanded = !_isExpanded;
                        });
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        foregroundColor: accentColor,
                      ),
                      icon: Icon(
                        _isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                        size: 17.r,
                      ),
                      label: Text(
                        _isExpanded
                            ? (isArabic ? 'طَي' : 'Collapse')
                            : (isArabic ? 'عرض الكل' : 'Show all'),
                        style: TextStyle(
                          fontSize: 11.5.sp,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Gontserrat',
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Collapsed Summary Preview
              if (!_isExpanded && widget.messages.isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(left: 14.w, right: 14.w, bottom: 8.h),
                  child: Text(
                    widget.messages.last.content ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: textMuted,
                      fontStyle: FontStyle.italic,
                      fontFamily: 'Gontserrat',
                    ),
                  ),
                ),

              // Expanded list of steps
              if (_isExpanded) ...[
                Divider(height: 1, color: borderColor),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                  child: Column(
                    children: [
                      for (int i = 0; i < widget.messages.length; i++)
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 4.h),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: EdgeInsets.only(top: 4.h),
                                child: Container(
                                  width: 6.r,
                                  height: 6.r,
                                  decoration: BoxDecoration(
                                    color: accentColor.withValues(alpha: 0.8),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                              SizedBox(width: 8.w),
                              Expanded(
                                child: Text(
                                  widget.messages[i].content ?? '',
                                  style: TextStyle(
                                    fontSize: 11.5.sp,
                                    height: 1.35,
                                    color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                                    fontFamily: 'Gontserrat',
                                  ),
                                ),
                              ),
                              SizedBox(width: 6.w),
                              Text(
                                _formatTime(widget.messages[i].createdAt),
                                style: TextStyle(
                                  fontSize: 9.5.sp,
                                  color: textMuted,
                                  fontFamily: 'Gontserrat',
                                ),
                              ),
                            ],
                          ),
                        ),
                      SizedBox(height: 4.h),
                      Center(
                        child: TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _isExpanded = false;
                            });
                          },
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 2.h),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            foregroundColor: textMuted,
                          ),
                          icon: Icon(Icons.keyboard_arrow_up_rounded, size: 15.r),
                          label: Text(
                            isArabic ? 'طَي الخطوات' : 'Collapse steps',
                            style: TextStyle(fontSize: 10.5.sp, fontFamily: 'Gontserrat'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
