import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:message_pro/core/constants/app_colors.dart';
import 'package:message_pro/logic/conversation/conversation_cubit.dart';
import 'package:message_pro/logic/conversation/conversation_state.dart';

class ConversationAdvancedFiltersSheet extends StatelessWidget {
  final String activeKey;
  final void Function(String key, String label) onSelectFilter;

  const ConversationAdvancedFiltersSheet({
    super.key,
    required this.activeKey,
    required this.onSelectFilter,
  });

  static Future<void> show({
    required BuildContext context,
    required String activeKey,
    required void Function(String key, String label) onSelectFilter,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF161616) : Colors.white;

    return showModalBottomSheet(
      context: context,
      backgroundColor: cardBg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => ConversationAdvancedFiltersSheet(
        activeKey: activeKey,
        onSelectFilter: onSelectFilter,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final textPrimary = isDark ? const Color(0xFFFAFAFA) : const Color(0xFF0D0D0D);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final dividerColor = isDark ? const Color(0xFF262626) : const Color(0xFFE5E7EB);

    return SafeArea(
      child: BlocBuilder<ConversationCubit, ConversationState>(
        builder: (context, state) {
          final stages = state.lifecycleStages;
          final labels = state.labels;

          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF333333) : const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Text(
                      isArabic ? 'تصفية متقدمة' : 'Advanced Filters',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                    const Spacer(),
                    if (activeKey != 'all')
                      TextButton(
                        onPressed: () {
                          onSelectFilter('all', 'All');
                          Navigator.pop(context);
                        },
                        child: Text(
                          isArabic ? 'إعادة ضبط' : 'Reset',
                          style: const TextStyle(color: AppColors.primary),
                        ),
                      ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      color: textSecondary,
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.55,
                  ),
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      if (stages.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                          child: Text(
                            isArabic ? 'مراحل العميل' : 'Lifecycle Stages',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: textSecondary,
                            ),
                          ),
                        ),
                        ...stages.map((stage) {
                          final sKey = 'stage_${stage.id}';
                          final isSelected = activeKey == sKey;
                          return ListTile(
                            dense: true,
                            leading: Text(stage.icon ?? '🌱', style: const TextStyle(fontSize: 16)),
                            title: Text(
                              stage.name,
                              style: TextStyle(
                                color: textPrimary,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            trailing: isSelected
                                ? const Icon(Icons.check_rounded, color: AppColors.primary, size: 18)
                                : null,
                            onTap: () {
                              onSelectFilter(sKey, stage.name);
                              Navigator.pop(context);
                            },
                          );
                        }),
                        Divider(color: dividerColor, height: 20),
                      ],
                      if (labels.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                          child: Text(
                            isArabic ? 'التصنيفات' : 'Labels',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: textSecondary,
                            ),
                          ),
                        ),
                        ...labels.map((lbl) {
                          final lKey = 'label_${lbl.title}';
                          final isSelected = activeKey == lKey;
                          final cleanColor = lbl.color.replaceAll('#', '');
                          final colorVal = int.tryParse('0xFF$cleanColor') ?? 0xFF4162E3;

                          return ListTile(
                            dense: true,
                            leading: Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: Color(colorVal),
                                shape: BoxShape.circle,
                              ),
                            ),
                            title: Text(
                              lbl.title,
                              style: TextStyle(
                                color: textPrimary,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            trailing: isSelected
                                ? const Icon(Icons.check_rounded, color: AppColors.primary, size: 18)
                                : null,
                            onTap: () {
                              onSelectFilter(lKey, lbl.title);
                              Navigator.pop(context);
                            },
                          );
                        }),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
