import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:message_pro/data/models/contact_details_aggregate.dart';

class ContactActivitiesTabView extends StatelessWidget {
  final List<ContactActivityItem> items;
  final SectionPaginationInfo? pagination;
  final bool isLoading;
  final bool isDark;
  final bool isArabic;
  final VoidCallback onLoadMore;

  const ContactActivitiesTabView({
    super.key,
    required this.items,
    required this.pagination,
    required this.isLoading,
    required this.isDark,
    required this.isArabic,
    required this.onLoadMore,
  });

  String _dateLabel(DateTime? dt) {
    if (dt == null) return isArabic ? 'أخرى' : 'Other';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(dt.year, dt.month, dt.day);
    if (target == today) return isArabic ? 'اليوم' : 'Today';
    if (target == today.subtract(const Duration(days: 1))) {
      return isArabic ? 'أمس' : 'Yesterday';
    }
    return DateFormat('MMM d, yyyy').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = isDark
        ? const Color(0xFF2C2D32)
        : const Color(0xFF353C45).withValues(alpha: 0.16);
    final primaryText = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF282E34);
    final secondaryText = isDark ? const Color(0xFF94A3B8) : const Color(0xFF626F7F);

    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            isArabic ? 'لا توجد أنشطة مسجلة' : 'No activities recorded.',
            style: TextStyle(fontSize: 13.5, color: secondaryText),
          ),
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1C1D22) : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.calendar_today_outlined, size: 14, color: secondaryText),
                  const SizedBox(width: 6),
                  Text(
                    isArabic ? 'كل الأوقات' : 'All Time',
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500, color: primaryText),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 20),
            itemCount: items.length + (pagination?.hasMore == true ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == items.length) {
                return Center(
                  child: TextButton(
                    onPressed: isLoading ? null : onLoadMore,
                    child: isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            isArabic ? 'تحميل المزيد' : 'Load more',
                            style: const TextStyle(color: Color(0xFF4162E3)),
                          ),
                  ),
                );
              }

              final item = items[index];
              final prev = index > 0 ? items[index - 1] : null;
              final label = _dateLabel(item.createdAt);
              final showHeader = prev == null || _dateLabel(prev.createdAt) != label;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (showHeader)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF26272D)
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            label,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              color: secondaryText,
                            ),
                          ),
                        ),
                      ),
                    ),
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1C1D22) : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.history_rounded, size: 15, color: secondaryText),
                            const SizedBox(width: 6),
                            Text(
                              item.title,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: primaryText,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          item.content,
                          style: TextStyle(fontSize: 13, color: secondaryText, height: 1.35),
                        ),
                        if (item.createdAt != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            DateFormat('MMM dd, yyyy hh:mm a').format(item.createdAt!),
                            style: TextStyle(fontSize: 11.5, color: secondaryText),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
