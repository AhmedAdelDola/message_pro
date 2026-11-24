import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class ContactFieldTile extends StatelessWidget {
  final String label;
  final String value;
  final bool isPlaceholder;
  final VoidCallback? onCopy;
  final IconData? actionIcon;
  final VoidCallback? onAction;

  const ContactFieldTile({
    super.key,
    required this.label,
    required this.value,
    this.isPlaceholder = false,
    this.onCopy,
    this.actionIcon,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textLightPrimary : AppColors.textDarkPrimary;
    final textSecondary = isDark ? AppColors.textLightSecondary : AppColors.textDarkSecondary;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: borderColor, width: 0.8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isPlaceholder ? FontWeight.normal : FontWeight.w500,
                    color: isPlaceholder ? textSecondary.withValues(alpha: 0.7) : textPrimary,
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (actionIcon != null && onAction != null)
                    InkWell(
                      onTap: onAction,
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(actionIcon, size: 16, color: AppColors.primary),
                      ),
                    ),
                  if (onCopy != null) ...[
                    const SizedBox(width: 4),
                    InkWell(
                      onTap: onCopy,
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(Icons.copy_rounded, size: 15, color: textSecondary),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
