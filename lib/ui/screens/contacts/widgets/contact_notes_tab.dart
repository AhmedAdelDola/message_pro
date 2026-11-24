import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';

class ContactNotesTab extends StatelessWidget {
  final TextEditingController noteController;
  final List<Map<String, dynamic>> notes;
  final VoidCallback onAddNote;

  const ContactNotesTab({
    super.key,
    required this.noteController,
    required this.notes,
    required this.onAddNote,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final textPrimary = isDark ? AppColors.textLightPrimary : AppColors.textDarkPrimary;
    final textSecondary = isDark ? AppColors.textLightSecondary : AppColors.textDarkSecondary;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;

    return Column(
      children: [
        // Note Input
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: cardBg,
            border: Border(bottom: BorderSide(color: borderColor)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: noteController,
                  maxLines: 3,
                  minLines: 1,
                  style: TextStyle(fontSize: 13.5, color: textPrimary),
                  decoration: InputDecoration(
                    hintText: isArabic ? 'أضف ملاحظة خاصة حول هذا العميل...' : 'Add a private note about this contact...',
                    hintStyle: TextStyle(fontSize: 13, color: textSecondary),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: borderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.primary),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.send_rounded, color: AppColors.primary),
                tooltip: isArabic ? 'إرسال' : 'Send',
                onPressed: onAddNote,
              ),
            ],
          ),
        ),

        // Notes List
        Expanded(
          child: notes.isEmpty
              ? Center(
                  child: Text(
                    isArabic ? 'لا توجد ملاحظات بعد' : 'No notes yet',
                    style: TextStyle(color: textSecondary),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: notes.length,
                  itemBuilder: (context, index) {
                    final note = notes[index];
                    final date = note['createdAt'] as DateTime;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                note['author']?.toString() ?? (isArabic ? 'أنت' : 'You'),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                              Text(
                                DateFormat('d MMM yyyy, h:mm a').format(date),
                                style: TextStyle(fontSize: 11, color: textSecondary),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            note['content']?.toString() ?? '',
                            style: TextStyle(fontSize: 13.5, color: textPrimary, height: 1.4),
                          ),
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
