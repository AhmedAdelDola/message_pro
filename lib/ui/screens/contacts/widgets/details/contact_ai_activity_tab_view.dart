import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:message_pro/data/models/contact_details_aggregate.dart';

class ContactAiActivityTabView extends StatelessWidget {
  final List<ContactAiActivityItem> items;
  final SectionPaginationInfo? pagination;
  final bool isLoading;
  final bool isDark;
  final bool isArabic;
  final VoidCallback onRefresh;
  final VoidCallback onLoadMore;

  const ContactAiActivityTabView({
    super.key,
    required this.items,
    required this.pagination,
    required this.isLoading,
    required this.isDark,
    required this.isArabic,
    required this.onRefresh,
    required this.onLoadMore,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isDark
        ? const Color(0xFF2C2D32)
        : const Color(0xFF353C45).withValues(alpha: 0.16);
    final primaryText = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF282E34);
    final secondaryText = isDark ? const Color(0xFF94A3B8) : const Color(0xFF626F7F);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isArabic ? 'نشاط الذكاء الاصطناعي' : 'AI activity',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: primaryText,
                ),
              ),
              TextButton(
                onPressed: isLoading ? null : onRefresh,
                child: isLoading
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        isArabic ? 'تحديث' : 'Refresh',
                        style: const TextStyle(
                          color: Color(0xFF4162E3),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            isArabic
                ? 'ملخص تشغيلات الذكاء الاصطناعي والإجراءات المنفذة وحالتها.'
                : 'Rate the overall outcome, including actions, handoffs or a missing reply.',
            style: TextStyle(fontSize: 12.5, color: secondaryText),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: items.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      isArabic
                          ? 'لا توجد تشغيلات مسجلة للذكاء الاصطناعي.'
                          : 'No AI runs recorded for this conversation.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13.5, color: secondaryText),
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                  itemCount: items.length + (pagination?.hasMore == true ? 1 : 0),
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    if (index == items.length) {
                      return Center(
                        child: TextButton(
                          onPressed: isLoading ? null : onLoadMore,
                          child: Text(
                            isArabic ? 'تحميل المزيد' : 'Load more',
                            style: const TextStyle(color: Color(0xFF4162E3)),
                          ),
                        ),
                      );
                    }
                    final item = items[index];
                    return Container(
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
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.auto_awesome_rounded,
                                    size: 15,
                                    color: Color(0xFF4162E3),
                                  ),
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
                              if (item.status != null && item.status!.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF4162E3).withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    item.status!,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF4162E3),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          if (item.summary != null && item.summary!.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              item.summary!,
                              style: TextStyle(fontSize: 13, color: secondaryText),
                            ),
                          ],
                          if (item.actions.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: item.actions.map((a) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? const Color(0xFF26272D)
                                        : const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    a,
                                    style: TextStyle(fontSize: 11, color: primaryText),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                          if (item.createdAt != null) ...[
                            const SizedBox(height: 6),
                            Text(
                              DateFormat('MMM dd, yyyy hh:mm a').format(item.createdAt!),
                              style: TextStyle(fontSize: 11, color: secondaryText),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
