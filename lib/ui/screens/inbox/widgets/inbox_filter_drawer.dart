import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/conversation_filter_options.dart';
import '../../../../logic/auth/auth_cubit.dart';
import '../../../../logic/auth/auth_state.dart';
import '../../../../logic/conversation/conversation_cubit.dart';
import '../../../../logic/conversation/conversation_state.dart';
import '../../../widgets/avatar_widget.dart';

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
    final textPrimary = isDark ? AppColors.textLightPrimary : AppColors.textDarkPrimary;
    final textSecondary = isDark ? AppColors.textLightSecondary : AppColors.textDarkSecondary;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Drawer(
      backgroundColor: bg,
      elevation: 0,
      width: MediaQuery.of(context).size.width * 0.84,
      child: SafeArea(
        child: BlocBuilder<ConversationCubit, ConversationState>(
          builder: (context, state) {
            final cubit = context.read<ConversationCubit>();
            final options = state.filterOptions ?? const ConversationFilterOptions();

            final hasActiveFilter = state.selectedInboxId != null ||
                state.selectedTeamId != null ||
                state.selectedAssigneeId != null ||
                state.selectedAssigneeAgentBotId != null;

            final hasNoData = options.inboxes.isEmpty &&
                options.aiAgents.isEmpty &&
                (!options.canFilterAgents || options.agents.isEmpty) &&
                options.teams.isEmpty;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Drawer Header
                _buildHeader(context, isDark, isArabic, textPrimary, textSecondary, borderColor, hasActiveFilter, cubit),

                // Content list
                Expanded(
                  child: state.isLoadingFilters && hasNoData
                      ? const Center(
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        )
                      : hasNoData
                          ? _buildEmptyState(isArabic, textSecondary)
                          : ListView(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              children: [
                                // 1. Channels / Inboxes (Collapsible)
                                if (options.inboxes.isNotEmpty) ...[
                                  _buildCollapsibleSection(
                                    context: context,
                                    title: isArabic ? 'القنوات' : 'Channels',
                                    sectionIcon: Icons.hub_rounded,
                                    count: options.inboxes.length,
                                    isExpanded: _inboxesExpanded,
                                    hasActiveFilter: state.selectedInboxId != null,
                                    onToggle: () => setState(() => _inboxesExpanded = !_inboxesExpanded),
                                    isDark: isDark,
                                    textPrimary: textPrimary,
                                    textSecondary: textSecondary,
                                    borderColor: borderColor,
                                    children: options.inboxes.map((inbox) {
                                      final isSelected = state.selectedInboxId == inbox.id;
                                      return _buildFilterItemTile(
                                        context: context,
                                        title: inbox.name,
                                        subtitle: inbox.channelType,
                                        leading: _buildChannelLogo(inbox.channelType, inbox.avatarUrl),
                                        isSelected: isSelected,
                                        onTap: () {
                                          cubit.setInboxFilter(isSelected ? null : inbox.id);
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

                                // 2. AI Agents (Collapsible)
                                if (options.aiAgents.isNotEmpty) ...[
                                  _buildCollapsibleSection(
                                    context: context,
                                    title: isArabic ? 'وكلاء الذكاء الاصطناعي' : 'AI Agents',
                                    sectionIcon: Icons.auto_awesome_rounded,
                                    count: options.aiAgents.length,
                                    isExpanded: _aiAgentsExpanded,
                                    hasActiveFilter: state.selectedAssigneeAgentBotId != null,
                                    onToggle: () => setState(() => _aiAgentsExpanded = !_aiAgentsExpanded),
                                    isDark: isDark,
                                    textPrimary: textPrimary,
                                    textSecondary: textSecondary,
                                    borderColor: borderColor,
                                    children: options.aiAgents.map((ai) {
                                      final isSelected = state.selectedAssigneeAgentBotId == ai.agentBotId;
                                      return _buildFilterItemTile(
                                        context: context,
                                        title: ai.name,
                                        subtitle: ai.description ?? (isArabic ? 'وكيل ذكي' : 'AI Assistant'),
                                        leading: _buildAiAgentAvatar(ai),
                                        trailing: _buildAiBadge(),
                                        isSelected: isSelected,
                                        onTap: () {
                                          cubit.setAiAgentFilter(isSelected ? null : ai.agentBotId);
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

                                // 3. Employees / Agents (Collapsible)
                                if (options.canFilterAgents && options.agents.isNotEmpty) ...[
                                  _buildCollapsibleSection(
                                    context: context,
                                    title: isArabic ? 'الموظفين' : 'Employees',
                                    sectionIcon: Icons.badge_rounded,
                                    count: options.agents.length,
                                    isExpanded: _agentsExpanded,
                                    hasActiveFilter: state.selectedAssigneeId != null,
                                    onToggle: () => setState(() => _agentsExpanded = !_agentsExpanded),
                                    isDark: isDark,
                                    textPrimary: textPrimary,
                                    textSecondary: textSecondary,
                                    borderColor: borderColor,
                                    children: options.agents.map((agent) {
                                      final isSelected = state.selectedAssigneeId == agent.id;
                                      return _buildFilterItemTile(
                                        context: context,
                                        title: agent.name,
                                        subtitle: agent.email,
                                        leading: AvatarWidget(
                                          avatarUrl: agent.avatarUrl,
                                          name: agent.name,
                                          size: 32,
                                          availabilityStatus: agent.availabilityStatus,
                                          showStatus: true,
                                        ),
                                        isSelected: isSelected,
                                        onTap: () {
                                          cubit.setAssigneeFilter(isSelected ? null : agent.id);
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

                                // 4. Teams (Collapsible)
                                if (options.teams.isNotEmpty) ...[
                                  _buildCollapsibleSection(
                                    context: context,
                                    title: isArabic ? 'فرق العمل' : 'Teams',
                                    sectionIcon: Icons.groups_rounded,
                                    count: options.teams.length,
                                    isExpanded: _teamsExpanded,
                                    hasActiveFilter: state.selectedTeamId != null,
                                    onToggle: () => setState(() => _teamsExpanded = !_teamsExpanded),
                                    isDark: isDark,
                                    textPrimary: textPrimary,
                                    textSecondary: textSecondary,
                                    borderColor: borderColor,
                                    children: options.teams.map((team) {
                                      final isSelected = state.selectedTeamId == team.id;
                                      return _buildFilterItemTile(
                                        context: context,
                                        title: team.name,
                                        subtitle: team.description,
                                        leading: _buildTeamAvatar(),
                                        isSelected: isSelected,
                                        onTap: () {
                                          cubit.setTeamFilter(isSelected ? null : team.id);
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

                                const SizedBox(height: 24),
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

  Widget _buildHeader(
    BuildContext context,
    bool isDark,
    bool isArabic,
    Color textPrimary,
    Color textSecondary,
    Color borderColor,
    bool hasActiveFilter,
    ConversationCubit cubit,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: borderColor, width: 1)),
      ),
      child: Row(
        children: [
          BlocBuilder<AuthCubit, AuthState>(
            builder: (context, authState) {
              final user = authState is Authenticated ? authState.user : null;
              final activeAccount = user != null && user.accounts.isNotEmpty
                  ? user.accounts.firstWhere(
                      (a) => a.id == user.accountId,
                      orElse: () => user.accounts.first,
                    )
                  : null;
              final initial = (activeAccount?.name.trim().isNotEmpty == true)
                  ? activeAccount!.name.trim()[0].toUpperCase()
                  : 'W';

              return Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.primary, width: 1.5),
                ),
                alignment: Alignment.center,
                child: Text(
                  initial,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isArabic ? 'القنوات والفلاتر' : 'Channels & Filters',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                    fontFamily: 'Gontserrat',
                  ),
                ),
                Text(
                  isArabic ? 'تصفح حسب القناة أو الوكيل' : 'Filter by channel or agent',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: textSecondary,
                    fontFamily: 'Gontserrat',
                  ),
                ),
              ],
            ),
          ),
          if (hasActiveFilter)
            TextButton(
              onPressed: () {
                cubit.clearAllFilters();
                Navigator.pop(context);
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                isArabic ? 'إعادة ضبط' : 'Reset',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isArabic, Color textSecondary) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.filter_list_off_rounded, size: 48, color: textSecondary.withValues(alpha: 0.5)),
          const SizedBox(height: 12),
          Text(
            isArabic ? 'لا توجد قنوات أو فلاتر متاحة' : 'No channels or filters available',
            style: TextStyle(
              fontSize: 13,
              color: textSecondary,
              fontFamily: 'Gontserrat',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCollapsibleSection({
    required BuildContext context,
    required String title,
    required IconData sectionIcon,
    required int count,
    required bool isExpanded,
    required bool hasActiveFilter,
    required VoidCallback onToggle,
    required List<Widget> children,
    required bool isDark,
    required Color textPrimary,
    required Color textSecondary,
    required Color borderColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Section Header (Clickable)
        InkWell(
          onTap: onToggle,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            child: Row(
              children: [
                Icon(
                  sectionIcon,
                  size: 16,
                  color: hasActiveFilter ? AppColors.primary : textSecondary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: hasActiveFilter ? AppColors.primary : textPrimary,
                          fontFamily: 'Gontserrat',
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: hasActiveFilter
                              ? AppColors.primary.withValues(alpha: 0.15)
                              : (isDark ? const Color(0xFF23252C) : const Color(0xFFEAECEF)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$count',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: hasActiveFilter ? AppColors.primary : textSecondary,
                          ),
                        ),
                      ),
                      if (hasActiveFilter) ...[
                        const SizedBox(width: 6),
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                AnimatedRotation(
                  turns: isExpanded ? 0.0 : -0.25,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 20,
                    color: textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Expandable Content
        AnimatedCrossFade(
          firstChild: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
          secondChild: const SizedBox.shrink(),
          crossFadeState: isExpanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
          duration: const Duration(milliseconds: 220),
        ),
      ],
    );
  }

  Widget _buildFilterItemTile({
    required BuildContext context,
    required String title,
    String? subtitle,
    required Widget leading,
    Widget? trailing,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.primary.withValues(alpha: isDark ? 0.2 : 0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: isSelected
            ? Border.all(color: AppColors.primary.withValues(alpha: 0.5), width: 1.2)
            : null,
      ),
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
            fontFamily: 'Gontserrat',
          ),
        ),
        subtitle: subtitle != null && subtitle.isNotEmpty
            ? Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10.5,
                  color: textSecondary,
                  fontFamily: 'Gontserrat',
                ),
              )
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (trailing != null) trailing,
            if (isSelected) ...[
              if (trailing != null) const SizedBox(width: 6),
              const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 18),
            ],
          ],
        ),
        onTap: onTap,
      ),
    );
  }

  // --- Channel Logos ---
  Widget _buildChannelLogo(String? channelType, String? avatarUrl, {double size = 32}) {
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CachedNetworkImage(
          imageUrl: avatarUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorWidget: (_, __, ___) => _buildChannelDefaultIcon(channelType, size: size),
        ),
      );
    }
    return _buildChannelDefaultIcon(channelType, size: size);
  }

  Widget _buildChannelDefaultIcon(String? channelType, {double size = 32}) {
    final lower = (channelType ?? '').toLowerCase();

    if (lower.contains('whatsapp')) {
      return Container(
        width: size,
        height: size,
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: const Color(0xFF25D366).withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF25D366).withValues(alpha: 0.3), width: 1),
        ),
        child: Image.asset(
          'assets/images/channels/whatsapp.png',
          width: size - 10,
          height: size - 10,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const Icon(
            Icons.chat_bubble_rounded,
            size: 18,
            color: Color(0xFF25D366),
          ),
        ),
      );
    }

    if (lower.contains('facebook') || lower.contains('messenger')) {
      return Container(
        width: size,
        height: size,
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: const Color(0xFF0084FF).withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF0084FF).withValues(alpha: 0.3), width: 1),
        ),
        child: Image.asset(
          'assets/images/channels/messenger.png',
          width: size - 10,
          height: size - 10,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const Icon(
            Icons.bolt_rounded,
            size: 18,
            color: Color(0xFF0084FF),
          ),
        ),
      );
    }

    if (lower.contains('instagram')) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF833AB4), Color(0xFFFD1D1D), Color(0xFFFCB045)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Icon(
            Icons.camera_alt_rounded,
            size: 17,
            color: Colors.white,
          ),
        ),
      );
    }

    if (lower.contains('telegram')) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: const Color(0xFF229ED9).withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF229ED9).withValues(alpha: 0.3), width: 1),
        ),
        child: const Center(
          child: Icon(
            Icons.send_rounded,
            size: 16,
            color: Color(0xFF229ED9),
          ),
        ),
      );
    }

    if (lower.contains('email') || lower.contains('mail')) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: const Color(0xFFEA4335).withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFEA4335).withValues(alpha: 0.3), width: 1),
        ),
        child: const Center(
          child: Icon(
            Icons.mail_rounded,
            size: 16,
            color: Color(0xFFEA4335),
          ),
        ),
      );
    }

    if (lower.contains('sms')) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: const Color(0xFF10B981).withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3), width: 1),
        ),
        child: const Center(
          child: Icon(
            Icons.sms_rounded,
            size: 16,
            color: Color(0xFF10B981),
          ),
        ),
      );
    }

    if (lower.contains('web')) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: const Color(0xFF0284C7).withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.3), width: 1),
        ),
        child: const Center(
          child: Icon(
            Icons.language_rounded,
            size: 17,
            color: Color(0xFF0284C7),
          ),
        ),
      );
    }

    if (lower.contains('api') || lower.contains('webhook')) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: const Color(0xFF8B5CF6).withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF8B5CF6).withValues(alpha: 0.3), width: 1),
        ),
        child: const Center(
          child: Icon(
            Icons.code_rounded,
            size: 17,
            color: Color(0xFF8B5CF6),
          ),
        ),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: Icon(
          Icons.inbox_rounded,
          size: 17,
          color: AppColors.primary,
        ),
      ),
    );
  }

  // --- AI Agent Avatars & Badges ---
  Widget _buildAiAgentAvatar(AiAgentItem ai, {double size = 32}) {
    if (ai.avatarUrl != null && ai.avatarUrl!.isNotEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: const Color(0xFF8B5CF6), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF8B5CF6).withValues(alpha: 0.25),
              blurRadius: 4,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(7.5),
          child: CachedNetworkImage(
            imageUrl: ai.avatarUrl!,
            fit: BoxFit.cover,
            errorWidget: (_, __, ___) => _buildDefaultAiIcon(size: size),
          ),
        ),
      );
    }
    return _buildDefaultAiIcon(size: size);
  }

  Widget _buildDefaultAiIcon({double size = 32}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(9),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
            blurRadius: 5,
            offset: const Offset(0, 1.5),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          Icons.smart_toy_rounded,
          color: Colors.white,
          size: size * 0.58,
        ),
      ),
    );
  }

  Widget _buildAiBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: const Color(0xFF8B5CF6).withValues(alpha: 0.3), width: 1),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome_rounded, size: 9, color: Color(0xFF8B5CF6)),
          SizedBox(width: 3),
          Text(
            'AI',
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.bold,
              color: Color(0xFF8B5CF6),
            ),
          ),
        ],
      ),
    );
  }

  // --- Team Avatar ---
  Widget _buildTeamAvatar({double size = 32}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF10B981), Color(0xFF059669)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(9),
      ),
      child: const Center(
        child: Icon(
          Icons.groups_rounded,
          color: Colors.white,
          size: 17,
        ),
      ),
    );
  }
}
