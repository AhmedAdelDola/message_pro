import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:message_pro/core/constants/app_colors.dart';
import 'package:message_pro/logic/conversation/conversation_cubit.dart';
import 'package:message_pro/logic/conversation/conversation_state.dart';

class InboxActiveFilterBar extends StatelessWidget {
  final bool isDark;
  final bool isArabic;

  const InboxActiveFilterBar({
    super.key,
    required this.isDark,
    required this.isArabic,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConversationCubit, ConversationState>(
      builder: (context, state) {
        final cubit = context.read<ConversationCubit>();
        String? activeFilterName;

        if (state.selectedAssigneeAgentBotId != null) {
          final ai = state.filterOptions?.aiAgents
              .where((a) => a.agentBotId == state.selectedAssigneeAgentBotId)
              .firstOrNull;
          activeFilterName = '${isArabic ? "بوت ذكي" : "AI Agent"}: ${ai?.name ?? "#${state.selectedAssigneeAgentBotId}"}';
        } else if (state.selectedAssigneeId != null) {
          final agent = state.filterOptions?.agents
              .where((a) => a.id == state.selectedAssigneeId)
              .firstOrNull;
          activeFilterName = '${isArabic ? "موظف" : "Agent"}: ${agent?.name ?? "#${state.selectedAssigneeId}"}';
        } else if (state.selectedInboxId != null) {
          final inbox = state.filterOptions?.inboxes
              .where((i) => i.id == state.selectedInboxId)
              .firstOrNull;
          activeFilterName = '${isArabic ? "قناة" : "Channel"}: ${inbox?.name ?? "#${state.selectedInboxId}"}';
        } else if (state.selectedTeamId != null) {
          final team = state.filterOptions?.teams
              .where((t) => t.id == state.selectedTeamId)
              .firstOrNull;
          activeFilterName = '${isArabic ? "فريق" : "Team"}: ${team?.name ?? "#${state.selectedTeamId}"}';
        }

        if (activeFilterName == null) return const SizedBox.shrink();

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: isDark ? 0.2 : 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.filter_alt_rounded, size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  activeFilterName,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              InkWell(
                onTap: () => cubit.clearAllFilters(),
                borderRadius: BorderRadius.circular(12),
                child: const Padding(
                  padding: EdgeInsets.all(2),
                  child: Icon(Icons.close_rounded, size: 16, color: AppColors.primary),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
