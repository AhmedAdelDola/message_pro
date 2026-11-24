import 'package:flutter/material.dart';
import 'package:message_pro/core/constants/app_colors.dart';

class DrawerFilterItemTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget leading;
  final Widget? trailing;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;
  final Color textPrimary;
  final Color textSecondary;

  const DrawerFilterItemTile({
    super.key,
    required this.title,
    this.subtitle,
    required this.leading,
    this.trailing,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
    required this.textPrimary,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    final itemBgColor = isSelected
        ? AppColors.primary.withValues(alpha: isDark ? 0.2 : 0.1)
        : Colors.transparent;

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: isSelected
            ? Border.all(color: AppColors.primary.withValues(alpha: 0.5), width: 1.2)
            : null,
      ),
      child: Material(
        color: itemBgColor,
        borderRadius: BorderRadius.circular(10),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
          visualDensity: const VisualDensity(horizontal: 0, vertical: -1.5),
          leading: leading,
          title: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? AppColors.primary : textPrimary,
            ),
          ),
          subtitle: subtitle != null && subtitle!.isNotEmpty
              ? Text(
                  subtitle!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 10.5, color: textSecondary),
                )
              : null,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (trailing != null) trailing!,
              if (isSelected) ...[
                if (trailing != null) const SizedBox(width: 6),
                const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 18),
              ],
            ],
          ),
          onTap: onTap,
        ),
      ),
    );
  }
}
