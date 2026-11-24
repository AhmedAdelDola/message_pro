import 'package:flutter/material.dart';
import 'package:message_pro/data/models/user.dart';

class WorkspaceAccountTile extends StatelessWidget {
  final Account account;
  final bool isActive;
  final bool isDark;
  final bool isArabic;
  final Color borderColor;
  final VoidCallback onTap;

  const WorkspaceAccountTile({
    super.key,
    required this.account,
    required this.isActive,
    required this.isDark,
    required this.isArabic,
    required this.borderColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? const Color(0xFFFAFAFA) : const Color(0xFF0D0D0D);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isActive
                ? (isDark ? const Color(0xFF131D2D) : const Color(0xFFEFF6FF))
                : (isDark ? const Color(0xFF1E1F24) : const Color(0xFFF9FAFB)),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive ? const Color(0xFF4162E3) : borderColor,
              width: isActive ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF131D2D)
                      : (isActive ? Colors.white : const Color(0xFFEFF6FF)),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF4162E3),
                    width: 1.5,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  account.name.trim().isNotEmpty
                      ? account.name.trim()[0].toUpperCase()
                      : 'E',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4162E3),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            account.name,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isActive) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF4162E3).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              isArabic ? 'الحالية' : 'Current',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF4162E3),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${isArabic ? "المعرف" : "ID"}: #${account.id} • ${account.role.isNotEmpty ? account.role : (isArabic ? "عضو" : "Member")}',
                      style: TextStyle(
                        fontSize: 12,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (isActive)
                const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF4162E3),
                  size: 20,
                )
              else
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: textSecondary.withValues(alpha: 0.5),
                  size: 14,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
