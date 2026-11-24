import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/contact.dart';

class ContactLifecyclePicker extends StatelessWidget {
  final List<LifecycleStage> lifecycleStages;
  final String currentLifecycleStage;
  final ValueChanged<LifecycleStage> onSelectStage;

  const ContactLifecyclePicker({
    super.key,
    required this.lifecycleStages,
    required this.currentLifecycleStage,
    required this.onSelectStage,
  });

  static Future<void> show({
    required BuildContext context,
    required List<LifecycleStage> lifecycleStages,
    required String currentLifecycleStage,
    required ValueChanged<LifecycleStage> onSelectStage,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;

    return showModalBottomSheet(
      context: context,
      backgroundColor: cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => ContactLifecyclePicker(
        lifecycleStages: lifecycleStages,
        currentLifecycleStage: currentLifecycleStage,
        onSelectStage: onSelectStage,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary = isDark ? AppColors.textLightSecondary : AppColors.textDarkSecondary;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              isArabic ? 'تحديد مرحلة العميل' : 'Select Lifecycle Stage',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          const Divider(),
          Expanded(
            child: lifecycleStages.isEmpty
                ? Center(
                    child: Text(
                      isArabic ? 'لا توجد مراحل محددة في النظام' : 'No lifecycle stages defined on backend',
                      style: TextStyle(color: textSecondary),
                    ),
                  )
                : ListView.builder(
                    itemCount: lifecycleStages.length,
                    itemBuilder: (ctx, index) {
                      final stage = lifecycleStages[index];
                      final emoji = stage.icon ?? LifecycleStage.getEmojiForStage(stage.name);
                      final colorHex = stage.color;
                      final color = Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
                      final cleanName = stage.name.startsWith(emoji)
                          ? stage.name.substring(emoji.length).trim()
                          : stage.name;
                      final isSelected = currentLifecycleStage.contains(cleanName);

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: color.withValues(alpha: 0.15),
                          child: Text(emoji, style: const TextStyle(fontSize: 20)),
                        ),
                        title: Text(
                          cleanName,
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                            color: isSelected ? color : null,
                          ),
                        ),
                        trailing: isSelected
                            ? Icon(Icons.check_circle_rounded, color: color)
                            : null,
                        onTap: () {
                          Navigator.pop(ctx);
                          onSelectStage(stage);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
