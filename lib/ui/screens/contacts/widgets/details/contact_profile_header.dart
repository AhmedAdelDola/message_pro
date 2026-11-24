import 'package:flutter/material.dart';
import 'package:message_pro/core/constants/app_colors.dart';
import 'package:message_pro/data/models/contact.dart';
import 'package:message_pro/logic/contacts/contact_details_state.dart';
import 'package:message_pro/ui/widgets/avatar_widget.dart';

class ContactProfileHeader extends StatelessWidget {
  final ContactDetailsState state;
  final VoidCallback onLifecycleTap;
  final VoidCallback onAddLabelTap;
  final ValueChanged<String> onRemoveLabel;

  const ContactProfileHeader({
    super.key,
    required this.state,
    required this.onLifecycleTap,
    required this.onAddLabelTap,
    required this.onRemoveLabel,
  });

  @override
  Widget build(BuildContext context) {
    final contact = state.contact;
    final lifecycleStage = state.activeLifecycleStage;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textLightPrimary : AppColors.textDarkPrimary;
    final textSecondary = isDark ? AppColors.textLightSecondary : AppColors.textDarkSecondary;

    final stageColorHex = LifecycleStage.getColorForStage(lifecycleStage);
    final stageColor = Color(int.parse(stageColorHex.replaceFirst('#', '0xFF')));
    final stageEmoji = LifecycleStage.getEmojiForStage(lifecycleStage);
    final cleanStageName = lifecycleStage.startsWith(stageEmoji)
        ? lifecycleStage.substring(stageEmoji.length).trim()
        : lifecycleStage;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AvatarWidget(
            avatarUrl: contact.avatarUrl,
            name: contact.name,
            size: 58,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contact.name,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      'ID: #${contact.id > 0 ? contact.id : 10990}',
                      style: TextStyle(fontSize: 12.5, color: textSecondary),
                    ),
                    if (contact.identifier != null && contact.identifier!.isNotEmpty) ...[
                      Text(' • ', style: TextStyle(color: textSecondary)),
                      Flexible(
                        child: Text(
                          contact.identifier!,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12.5, color: textSecondary),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    InkWell(
                      onTap: onLifecycleTap,
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: stageColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: stageColor.withValues(alpha: 0.35),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(stageEmoji, style: const TextStyle(fontSize: 12)),
                            const SizedBox(width: 4),
                            Text(
                              cleanStageName,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: stageColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    for (final lbl in state.labels)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 0.8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              lbl,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 4),
                            InkWell(
                              onTap: () => onRemoveLabel(lbl),
                              child: const Icon(Icons.close_rounded, size: 12, color: AppColors.primary),
                            ),
                          ],
                        ),
                      ),
                    InkWell(
                      onTap: onAddLabelTap,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF22242B) : const Color(0xFFF1F2F4),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: const Icon(Icons.add_rounded, size: 14, color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
