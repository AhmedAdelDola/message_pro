import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:message_pro/core/constants/app_colors.dart';
import 'package:message_pro/data/models/conversation_filter_options.dart';
import 'package:message_pro/logic/conversation/conversation_cubit.dart';
import 'package:message_pro/logic/conversation/conversation_state.dart';
import 'package:message_pro/ui/widgets/avatar_widget.dart';
import 'drawer/drawer_collapsible_section.dart';
import 'drawer/drawer_filter_item_tile.dart';
import 'drawer/drawer_channel_logo.dart';
import 'drawer/inbox_drawer_header.dart';

/// Clean, decomposed drawer for filtering conversations by channel, agent, AI bot, or team.
/// Follows Single Responsibility Principle by orchestrating dedicated collapsible drawer components.
class InboxFilterDrawer extends StatefulWidget {
  const InboxFilterDrawer({super.key});

  @override
  State<InboxFilterDrawer> createState() => _InboxFilterDrawerState();
}

class _InboxFilterDrawerState extends State<InboxFilterDrawer> {
  bool _inboxesExpanded = true;
  bool _aiAgentsExpanded = true;
  bool _agentsExpanded = true;
  bool _teamsExpanded = true;

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF131418) : Colors.white;
    final textPrimary = isDark
        ? AppColors.textLightPrimary
        : AppColors.textDarkPrimary;
    final textSecondary = isDark
        ? AppColors.textLightSecondary
        : AppColors.textDarkSecondary;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Drawer(
      backgroundColor: bg,
      elevation: 0,
      width: MediaQuery.of(context).size.width * 0.84,
      child: SafeArea(
        child: BlocBuilder<ConversationCubit, ConversationState>(
          builder: (context, state) {
            final cubit = context.read<ConversationCubit>();
            final options =
                state.filterOptions ?? const ConversationFilterOptions();
            final inboxes = options.inboxes.isNotEmpty
                ? options.inboxes
                : state.inboxes;
            final teams = options.teams.isNotEmpty
                ? options.teams
                : state.teams;
            final agents = options.agents.isNotEmpty
                ? options.agents
                : state.agents;

            final hasActiveFilter =
                state.selectedInboxId != null ||
                state.selectedTeamId != null ||
                state.selectedAssigneeId != null ||
                state.selectedAssigneeAgentBotId != null;

            final hasNoData =
                inboxes.isEmpty &&
                options.aiAgents.isEmpty &&
                (!options.canFilterAgents || agents.isEmpty) &&
                teams.isEmpty;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                InboxDrawerHeader(
                  isDark: isDark,
                  isArabic: isArabic,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                  borderColor: borderColor,
                  hasActiveFilter: hasActiveFilter,
                  cubit: cubit,
                ),
                Expanded(
                  child: state.isLoadingFilters && hasNoData
                      ? const Center(
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        )
                      : hasNoData
                      ? _buildEmptyState(isArabic, textSecondary)
                      : ListView(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          children: [
                            // 1. Channels / Inboxes
                            if (inboxes.isNotEmpty) ...[
                              DrawerCollapsibleSection(
                                title: isArabic ? 'القنوات' : 'Channels',
                                sectionIcon: Icons.hub_rounded,
                                count: inboxes.length,
                                isExpanded: _inboxesExpanded,
                                hasActiveFilter: state.selectedInboxId != null,
                                onToggle: () => setState(
                                  () => _inboxesExpanded = !_inboxesExpanded,
                                ),
                                isDark: isDark,
                                textPrimary: textPrimary,
                                textSecondary: textSecondary,
                                borderColor: borderColor,
                                children: inboxes.map((inbox) {
                                  final isSelected =
                                      state.selectedInboxId == inbox.id;
                                  return DrawerFilterItemTile(
                                    title: inbox.name,
                                    subtitle: inbox.channelType,
                                    leading: DrawerChannelLogo(
                                      channelType: inbox.channelType,
                                      avatarUrl: inbox.avatarUrl,
                                    ),
                                    isSelected: isSelected,
                                    onTap: () {
                                      cubit.setInboxFilter(
                                        isSelected ? null : inbox.id,
                                      );
                                      Navigator.pop(context);
                                    },
                                    isDark: isDark,
                                    textPrimary: textPrimary,
                                    textSecondary: textSecondary,
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 12),
                            ],

                            // 2. AI Agents
                            if (options.aiAgents.isNotEmpty) ...[
                              DrawerCollapsibleSection(
                                title: isArabic
                                    ? 'وكلاء الذكاء الاصطناعي'
                                    : 'AI Agents',
                                sectionIcon: Icons.auto_awesome_rounded,
                                count: options.aiAgents.length,
                                isExpanded: _aiAgentsExpanded,
                                hasActiveFilter:
                                    state.selectedAssigneeAgentBotId != null,
                                onToggle: () => setState(
                                  () => _aiAgentsExpanded = !_aiAgentsExpanded,
                                ),
                                isDark: isDark,
                                textPrimary: textPrimary,
                                textSecondary: textSecondary,
                                borderColor: borderColor,
                                children: options.aiAgents.map((ai) {
                                  final isSelected =
                                      state.selectedAssigneeAgentBotId ==
                                      ai.agentBotId;

                                  Widget aiLeading;
                                  if (ai.avatarUrl != null && ai.avatarUrl!.isNotEmpty) {
                                    aiLeading = AvatarWidget(
                                      avatarUrl: ai.avatarUrl,
                                      name: ai.name,
                                      size: 32,
                                    );
                                  } else {
                                    final cleanName = ai.name.trim();
                                    final emojiStr = (cleanName.isNotEmpty && cleanName.runes.first > 255)
                                        ? String.fromCharCode(cleanName.runes.first)
                                        : '🤖';
                                    aiLeading = Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF5850EC).withValues(alpha: 0.12),
                                        shape: BoxShape.circle,
                                        border: Border.all(color: const Color(0xFF5850EC).withValues(alpha: 0.25)),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(emojiStr, style: const TextStyle(fontSize: 16)),
                                    );
                                  }

                                  return DrawerFilterItemTile(
                                    title: ai.name,
                                    subtitle: ai.description,
                                    leading: aiLeading,
                                    isSelected: isSelected,
                                    onTap: () {
                                      cubit.setAiAgentFilter(
                                        isSelected ? null : ai.agentBotId,
                                      );
                                      Navigator.pop(context);
                                    },
                                    isDark: isDark,
                                    textPrimary: textPrimary,
                                    textSecondary: textSecondary,
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 12),
                            ],

                            // 3. Human Agents
                            if (options.canFilterAgents &&
                                agents.isNotEmpty) ...[
                              DrawerCollapsibleSection(
                                title: isArabic ? 'الموظفين' : 'Agents',
                                sectionIcon: Icons.people_alt_rounded,
                                count: agents.length,
                                isExpanded: _agentsExpanded,
                                hasActiveFilter:
                                    state.selectedAssigneeId != null,
                                onToggle: () => setState(
                                  () => _agentsExpanded = !_agentsExpanded,
                                ),
                                isDark: isDark,
                                textPrimary: textPrimary,
                                textSecondary: textSecondary,
                                borderColor: borderColor,
                                children: agents.map((agent) {
                                  final isSelected =
                                      state.selectedAssigneeId == agent.id;
                                  return DrawerFilterItemTile(
                                    title: agent.name,
                                    subtitle: agent.role,
                                    leading: AvatarWidget(
                                      avatarUrl: agent.avatarUrl,
                                      name: agent.name,
                                      size: 32,
                                    ),
                                    isSelected: isSelected,
                                    onTap: () {
                                      cubit.setAssigneeFilter(
                                        isSelected ? null : agent.id,
                                      );
                                      Navigator.pop(context);
                                    },
                                    isDark: isDark,
                                    textPrimary: textPrimary,
                                    textSecondary: textSecondary,
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 12),
                            ],

                            // 4. Teams
                            if (teams.isNotEmpty) ...[
                              DrawerCollapsibleSection(
                                title: isArabic ? 'الفرق' : 'Teams',
                                sectionIcon: Icons.groups_rounded,
                                count: teams.length,
                                isExpanded: _teamsExpanded,
                                hasActiveFilter: state.selectedTeamId != null,
                                onToggle: () => setState(
                                  () => _teamsExpanded = !_teamsExpanded,
                                ),
                                isDark: isDark,
                                textPrimary: textPrimary,
                                textSecondary: textSecondary,
                                borderColor: borderColor,
                                children: teams.map((team) {
                                  final isSelected =
                                      state.selectedTeamId == team.id;
                                  return DrawerFilterItemTile(
                                    title: team.name,
                                    subtitle: team.description,
                                    leading: Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          0xFF10B981,
                                        ).withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      alignment: Alignment.center,
                                      child: const Icon(
                                        Icons.group_rounded,
                                        color: Color(0xFF10B981),
                                        size: 18,
                                      ),
                                    ),
                                    isSelected: isSelected,
                                    onTap: () {
                                      cubit.setTeamFilter(
                                        isSelected ? null : team.id,
                                      );
                                      Navigator.pop(context);
                                    },
                                    isDark: isDark,
                                    textPrimary: textPrimary,
                                    textSecondary: textSecondary,
                                  );
                                }).toList(),
                              ),
                            ],
                          ],
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isArabic, Color textSecondary) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inbox_rounded,
              size: 40,
              color: textSecondary.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 10),
            Text(
              isArabic ? 'لا توجد فلاتر متاحة' : 'No filters available',
              style: TextStyle(
                fontSize: 14,
                color: textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
