import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:message_pro/data/models/contact_details_aggregate.dart';
import 'package:message_pro/ui/widgets/avatar_widget.dart';

class ContactAttachmentsTabView extends StatefulWidget {
  final List<ContactAttachmentItem> items;
  final SectionPaginationInfo? pagination;
  final bool isLoading;
  final bool isDark;
  final bool isArabic;
  final VoidCallback onLoadMore;

  const ContactAttachmentsTabView({
    super.key,
    required this.items,
    required this.pagination,
    required this.isLoading,
    required this.isDark,
    required this.isArabic,
    required this.onLoadMore,
  });

  @override
  State<ContactAttachmentsTabView> createState() => _ContactAttachmentsTabViewState();
}

class _ContactAttachmentsTabViewState extends State<ContactAttachmentsTabView> {
  String _query = '';

  String _dateLabel(DateTime? dt) {
    if (dt == null) return widget.isArabic ? 'أخرى' : 'Other';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(dt.year, dt.month, dt.day);
    if (target == today) return widget.isArabic ? 'اليوم' : 'Today';
    if (target == today.subtract(const Duration(days: 1))) {
      return widget.isArabic ? 'أمس' : 'Yesterday';
    }
    return DateFormat('MMM d, yyyy').format(dt);
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = widget.isDark
        ? const Color(0xFF2C2D32)
        : const Color(0xFF353C45).withValues(alpha: 0.16);
    final primaryText = widget.isDark ? const Color(0xFFF1F5F9) : const Color(0xFF282E34);
    final secondaryText = widget.isDark ? const Color(0xFF94A3B8) : const Color(0xFF626F7F);

    final filtered = _query.trim().isEmpty
        ? widget.items
        : widget.items
            .where((a) => a.fileName.toLowerCase().contains(_query.trim().toLowerCase()))
            .toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            onChanged: (v) => setState(() => _query = v),
            decoration: InputDecoration(
              hintText: widget.isArabic ? 'ابحث باسم الملف' : 'Search by file name',
              hintStyle: TextStyle(fontSize: 13.5, color: secondaryText),
              prefixIcon: Icon(Icons.search_rounded, size: 19, color: secondaryText),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              filled: true,
              fillColor: widget.isDark ? const Color(0xFF1C1D22) : Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: borderColor),
              ),
            ),
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Text(
                    widget.isArabic ? 'لا توجد مرفقات' : 'No attachments found',
                    style: TextStyle(fontSize: 13.5, color: secondaryText),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                  itemCount: filtered.length + (widget.pagination?.hasMore == true ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == filtered.length) {
                      return Center(
                        child: TextButton(
                          onPressed: widget.isLoading ? null : widget.onLoadMore,
                          child: widget.isLoading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : Text(
                                  widget.isArabic ? 'تحميل المزيد' : 'Load more',
                                  style: const TextStyle(color: Color(0xFF4162E3)),
                                ),
                        ),
                      );
                    }

                    final item = filtered[index];
                    final prev = index > 0 ? filtered[index - 1] : null;
                    final label = _dateLabel(item.createdAt);
                    final showHeader = prev == null || _dateLabel(prev.createdAt) != label;

                    final isImage = item.fileType.toLowerCase().contains('image');
                    final subtitleParts = <String>[
                      if (item.extension != null && item.extension!.isNotEmpty) item.extension!,
                      if (item.formattedSize.isNotEmpty) item.formattedSize,
                    ];

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
                                  color: widget.isDark
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
                        InkWell(
                          onTap: () => _openUrl(item.dataUrl),
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: widget.isDark
                                        ? const Color(0xFF1C1D22)
                                        : const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: borderColor),
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: isImage && (item.thumbUrl ?? item.dataUrl).isNotEmpty
                                      ? Image.network(
                                          item.thumbUrl ?? item.dataUrl,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => Icon(
                                            Icons.image_outlined,
                                            size: 20,
                                            color: secondaryText,
                                          ),
                                        )
                                      : Icon(
                                          item.fileType.toLowerCase().contains('audio')
                                              ? Icons.audiotrack_outlined
                                              : (item.fileType.toLowerCase().contains('video')
                                                  ? Icons.videocam_outlined
                                                  : Icons.insert_drive_file_outlined),
                                          size: 20,
                                          color: secondaryText,
                                        ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.fileName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w500,
                                          color: primaryText,
                                        ),
                                      ),
                                      if (subtitleParts.isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          subtitleParts.join(' | '),
                                          style: TextStyle(fontSize: 11.5, color: secondaryText),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                if (item.senderName != null && item.senderName!.isNotEmpty) ...[
                                  AvatarWidget(
                                    avatarUrl: item.senderAvatar,
                                    name: item.senderName!,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                Icon(Icons.north_east_rounded, size: 17, color: secondaryText),
                              ],
                            ),
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
