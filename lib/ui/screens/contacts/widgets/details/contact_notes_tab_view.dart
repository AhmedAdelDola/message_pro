import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:message_pro/data/models/contact_details_aggregate.dart';
import 'package:message_pro/data/models/message.dart';
import 'package:message_pro/ui/widgets/avatar_widget.dart';

class ContactNotesTabView extends StatefulWidget {
  final List<ContactNoteItem> notes;
  final SectionPaginationInfo? pagination;
  final bool isLoading;
  final bool isSavingNote;
  final bool canAddNote;
  final bool isDark;
  final bool isArabic;
  final VoidCallback onLoadMore;
  final Future<bool> Function(String content) onAddNote;

  const ContactNotesTabView({
    super.key,
    required this.notes,
    required this.pagination,
    required this.isLoading,
    required this.isSavingNote,
    required this.canAddNote,
    required this.isDark,
    required this.isArabic,
    required this.onLoadMore,
    required this.onAddNote,
  });

  @override
  State<ContactNotesTabView> createState() => _ContactNotesTabViewState();
}

class _ContactNotesTabViewState extends State<ContactNotesTabView> {
  final TextEditingController _controller = TextEditingController();
  final Set<int> _expandedIds = {};

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _relativeDate(DateTime? dt) {
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return widget.isArabic ? 'الآن' : 'just now';
    if (diff.inHours < 1) {
      return widget.isArabic ? 'منذ ${diff.inMinutes} دقيقة' : '${diff.inMinutes}m ago';
    }
    if (diff.inDays < 1) {
      return widget.isArabic ? 'منذ ${diff.inHours} ساعة' : '${diff.inHours}h ago';
    }
    if (diff.inDays < 30) {
      return widget.isArabic ? 'منذ ${diff.inDays} يوم' : '${diff.inDays} days ago';
    }
    return DateFormat('MMM d, yyyy').format(dt);
  }

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty || widget.isSavingNote) return;
    final ok = await widget.onAddNote(text);
    if (ok && mounted) {
      _controller.clear();
      FocusScope.of(context).unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = widget.isDark
        ? const Color(0xFF2C2D32)
        : const Color(0xFF353C45).withValues(alpha: 0.16);
    final primaryText = widget.isDark ? const Color(0xFFF1F5F9) : const Color(0xFF282E34);
    final secondaryText = widget.isDark ? const Color(0xFF94A3B8) : const Color(0xFF626F7F);

    return Column(
      children: [
        Expanded(
          child: widget.notes.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      widget.isArabic ? 'لا توجد ملاحظات خاصة' : 'No notes yet.',
                      style: TextStyle(fontSize: 13.5, color: secondaryText),
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: widget.notes.length + (widget.pagination?.hasMore == true ? 1 : 0),
                  separatorBuilder: (_, __) => Divider(height: 1, color: borderColor),
                  itemBuilder: (context, index) {
                    if (index == widget.notes.length) {
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

                    final note = widget.notes[index];
                    final cleaned = Message.cleanMessageText(note.content);
                    final isLong = cleaned.length > 180 || cleaned.split('\n').length > 4;
                    final isExpanded = _expandedIds.contains(note.id);

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              AvatarWidget(
                                avatarUrl: note.authorAvatar,
                                name: note.authorName,
                                size: 22,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text.rich(
                                  TextSpan(
                                    children: [
                                      TextSpan(
                                        text: note.authorName,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: primaryText,
                                          fontSize: 13,
                                        ),
                                      ),
                                      TextSpan(
                                        text: widget.isArabic
                                            ? ' كتب ${_relativeDate(note.createdAt)}'
                                            : ' wrote ${_relativeDate(note.createdAt)}',
                                        style: TextStyle(
                                          color: secondaryText,
                                          fontSize: 12.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            cleaned,
                            maxLines: isLong && !isExpanded ? 4 : null,
                            overflow: isLong && !isExpanded ? TextOverflow.ellipsis : null,
                            style: TextStyle(
                              fontSize: 13.5,
                              height: 1.4,
                              color: primaryText,
                            ),
                          ),
                          if (isLong) ...[
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: () {
                                setState(() {
                                  if (isExpanded) {
                                    _expandedIds.remove(note.id);
                                  } else {
                                    _expandedIds.add(note.id);
                                  }
                                });
                              },
                              borderRadius: BorderRadius.circular(6),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF4162E3).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isExpanded
                                          ? Icons.keyboard_arrow_up_rounded
                                          : Icons.keyboard_arrow_down_rounded,
                                      size: 16,
                                      color: const Color(0xFF4162E3),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      isExpanded
                                          ? (widget.isArabic ? 'تصغير' : 'Collapse')
                                          : (widget.isArabic ? 'توسيع' : 'Expand'),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF4162E3),
                                      ),
                                    ),
                                  ],
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
        if (widget.canAddNote)
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            decoration: BoxDecoration(
              color: widget.isDark ? const Color(0xFF141518) : const Color(0xFFFEFEFE),
              border: Border(top: BorderSide(color: borderColor)),
            ),
            child: SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: widget.isDark ? const Color(0xFF1C1D22) : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        minLines: 1,
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText: widget.isArabic
                              ? 'استخدم @ للإشارة لزميل... أضف ملاحظة'
                              : 'Use @ to mention a teammate. Comment...',
                          hintStyle: TextStyle(fontSize: 13, color: secondaryText),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: widget.isSavingNote ? null : _submit,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4162E3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: widget.isSavingNote
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.send_rounded, size: 16, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
