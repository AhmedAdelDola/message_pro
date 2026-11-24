import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../logic/conversation/conversation_cubit.dart';
import '../../../../../logic/conversation/conversation_state.dart';

class InboxDrawerButton extends StatelessWidget {
  final VoidCallback onTap;

  const InboxDrawerButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final textPrimary = isDark ? AppColors.textLightPrimary : AppColors.textDarkPrimary;

    return BlocBuilder<ConversationCubit, ConversationState>(
      builder: (context, state) {
        final hasActiveFilter = state.selectedInboxId != null ||
            state.selectedTeamId != null ||
            state.selectedAssigneeId != null ||
            state.selectedAssigneeAgentBotId != null;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1F24) : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: hasActiveFilter
                        ? AppColors.primary
                        : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                    width: 1.2,
                  ),
                ),
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedMenu01,
                  color: hasActiveFilter ? AppColors.primary : textPrimary,
                  size: 20,
                ),
              ),
            ),
            if (hasActiveFilter)
              Positioned(
                top: -2,
                right: isArabic ? null : -2,
                left: isArabic ? -2 : null,
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? const Color(0xFF131418) : Colors.white,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
