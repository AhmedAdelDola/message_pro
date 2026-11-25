import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:message_pro/data/models/contact_details_aggregate.dart';

class ContactCalendarTabView extends StatelessWidget {
  final List<ContactCalendarEvent> events;
  final String activeBucket; // 'upcoming' | 'past'
  final SectionPaginationInfo? pagination;
  final bool isLoading;
  final bool isDark;
  final bool isArabic;
  final ValueChanged<String> onSwitchBucket;
  final VoidCallback onLoadMore;

  const ContactCalendarTabView({
    super.key,
    required this.events,
    required this.activeBucket,
    required this.pagination,
    required this.isLoading,
    required this.isDark,
    required this.isArabic,
    required this.onSwitchBucket,
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
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          child: Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1C1D22) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                _buildSegment(
                  label: isArabic ? 'القادمة' : 'Upcoming',
                  value: 'upcoming',
                  primaryText: primaryText,
                  secondaryText: secondaryText,
                ),
                _buildSegment(
                  label: isArabic ? 'السابقة' : 'Past',
                  value: 'past',
                  primaryText: primaryText,
                  secondaryText: secondaryText,
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: isLoading && events.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : events.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(16),
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1C1D22) : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: borderColor),
                          ),
                          child: Text(
                            isArabic
                                ? 'لا توجد مواعيد مطابقة لهذا العميل.'
                                : 'No matching meetings for this contact.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 13.5, color: secondaryText),
                          ),
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                      itemCount: events.length + (pagination?.hasMore == true ? 1 : 0),
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        if (index == events.length) {
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
                        final ev = events[index];
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1C1D22) : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: borderColor),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      ev.title,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: primaryText,
                                      ),
                                    ),
                                  ),
                                  if (ev.status != null && ev.status!.isNotEmpty)
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
                                        ev.status!,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF4162E3),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              if (ev.startAt != null) ...[
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Icon(Icons.access_time_rounded, size: 14, color: secondaryText),
                                    const SizedBox(width: 5),
                                    Text(
                                      DateFormat('EEE, MMM d • hh:mm a').format(ev.startAt!),
                                      style: TextStyle(fontSize: 12.5, color: secondaryText),
                                    ),
                                  ],
                                ),
                              ],
                              if (ev.description != null && ev.description!.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(
                                  ev.description!,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 12.5, color: secondaryText),
                                ),
                              ],
                              if (ev.meetingUrl != null && ev.meetingUrl!.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                InkWell(
                                  onTap: () {
                                    final uri = Uri.tryParse(ev.meetingUrl!);
                                    if (uri != null) {
                                      launchUrl(uri, mode: LaunchMode.externalApplication);
                                    }
                                  },
                                  child: Text(
                                    isArabic ? 'انضمام للاجتماع ↗' : 'Join meeting ↗',
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF4162E3),
                                    ),
                                  ),
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

  Widget _buildSegment({
    required String label,
    required String value,
    required Color primaryText,
    required Color secondaryText,
  }) {
    final isSelected = activeBucket == value;
    return Expanded(
      child: InkWell(
        onTap: () => onSwitchBucket(value),
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? const Color(0xFF2B2D35) : Colors.white)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? primaryText : secondaryText,
            ),
          ),
        ),
      ),
    );
  }
}
