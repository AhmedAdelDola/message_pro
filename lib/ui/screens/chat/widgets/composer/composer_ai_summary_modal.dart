import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

class ComposerAiSummaryModal {
  static void show({
    required BuildContext context,
    required void Function(String summary) onAddPrivateNote,
  }) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return SafeArea(
          child: Container(
            color: isDark ? const Color(0xFF161616) : Colors.white,
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const HugeIcon(
                      icon: HugeIcons.strokeRoundedSparkles,
                      color: Color(0xFF7C3AED),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isArabic
                          ? 'ملخص المحادثة بالذكاء الاصطناعي'
                          : 'AI Conversation Summary',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF212121)
                        : const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF2C2C2E)
                          : const Color(0xFFE5E7EB),
                    ),
                  ),
                  child: Text(
                    isArabic
                        ? 'العميل مهتم بمعرفة أسعار وباقات Message Pro وميزات الربط مع واتساب وكول سنتر السحابي. تم إرسال العرض المبدئي ومطلوب متابعة للتأكيد.'
                        : 'Customer inquired about Message Pro pricing plans and integrations with WhatsApp & Cloud Call Center. Initial proposal shared; awaiting confirmation follow-up.',
                    style: const TextStyle(fontSize: 13, height: 1.45),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    final summary = isArabic
                        ? 'ملخص: العميل مهتم بباقات Message Pro وميزات الربط مع واتساب.'
                        : 'Summary: Customer inquired about Message Pro pricing & WhatsApp integration.';
                    onAddPrivateNote(summary);
                    Navigator.pop(ctx);
                  },
                  icon: const HugeIcon(
                    icon: HugeIcons.strokeRoundedNote01,
                    color: Colors.white,
                    size: 16,
                  ),
                  label: Text(
                    isArabic ? 'إضافة كملاحظة خاصة' : 'Add as Private Note',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4162E3),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
