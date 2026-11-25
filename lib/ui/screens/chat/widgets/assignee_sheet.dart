import 'package:flutter/material.dart';
import '../../../../data/models/contact.dart';
import '../../../../data/models/user.dart';
import '../../../widgets/avatar_widget.dart';

class AssigneeSheet extends StatefulWidget {
  final List<User> agents;
  final List<User>? aiAgents;
  final List<Team>? teams;
  final User? currentAssignee;
  final bool isStatusBot;
  final Function(int? agentId, {bool isAi, String? assigneeType}) onSelect;

  const AssigneeSheet({
    super.key,
    required this.agents,
    this.aiAgents,
    this.teams,
    this.currentAssignee,
    this.isStatusBot = false,
    required this.onSelect,
  });

  @override
  State<AssigneeSheet> createState() => _AssigneeSheetState();
}

class _AssigneeSheetState extends State<AssigneeSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    final bgColor = isDark ? const Color(0xFF161616) : Colors.white;
    final surfaceColor = isDark
        ? const Color(0xFF1E1F23)
        : const Color(0xFFF4F4F6);
    final borderColor = isDark
        ? const Color(0xFF2B2E35)
        : const Color(0xFFE5E7EB);
    final textPrimary = isDark
        ? const Color(0xFFEDEEF0)
        : const Color(0xFF282E34);
    final textSecondary = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF626F7F);

    // Separate real AI Agents (AgentBot / ai_agent) and Human Agents
    final List<User> realAiAgents = [];
    if (widget.aiAgents != null && widget.aiAgents!.isNotEmpty) {
      realAiAgents.addAll(widget.aiAgents!);
    } else {
      realAiAgents.addAll(
        widget.agents.where(
          (a) =>
              a.isBot || a.assigneeType == 'AgentBot' || a.type == 'ai_agent',
        ),
      );
    }

    final filteredAiAgents = realAiAgents.where((ai) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return ai.name.toLowerCase().contains(q) ||
          (ai.displayName?.toLowerCase().contains(q) ?? false);
    }).toList();

    // Human workspace agents (strictly excluding bots)
    final filteredAgents = widget.agents.where((a) {
      if (a.isBot || a.assigneeType == 'AgentBot' || a.type == 'ai_agent') {
        return false;
      }
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return a.name.toLowerCase().contains(q) ||
          a.email.toLowerCase().contains(q);
    }).toList();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.82,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 38,
                height: 4,
                margin: const EdgeInsets.only(top: 10, bottom: 8),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF333742)
                      : const Color(0xFFD1D5DB),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),

            // Header title & close
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: [
                  Text(
                    isArabic ? 'تعيين المسؤول' : 'Assign Agent',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      size: 20,
                      color: textSecondary,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Search input
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: borderColor),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _searchQuery = v.trim()),
                  style: TextStyle(fontSize: 13, color: textPrimary),
                  decoration: InputDecoration(
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      size: 18,
                      color: textSecondary,
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              Icons.clear_rounded,
                              size: 16,
                              color: textSecondary,
                            ),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    hintText: isArabic
                        ? 'البحث عن مسؤول...'
                        : 'Search agents...',
                    hintStyle: TextStyle(fontSize: 13, color: textSecondary),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    filled: false,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 6),

            // List of choices
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                children: [
                  // 1. AI Agents Section
                  if (filteredAiAgents.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: Row(
                        children: [
                          Text(
                            isArabic ? 'الوكلاء الأذكياء' : 'AI Agents',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: textSecondary,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF5850EC,
                              ).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Text(
                              'AI',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF5850EC),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    ...filteredAiAgents.map((ai) {
                      final isSelected =
                          widget.currentAssignee != null &&
                          widget.currentAssignee!.isBot &&
                          widget.currentAssignee!.id == ai.id;

                      final emojiStr =
                          ai.emoji ??
                          (ai.name.trim().characters.firstOrNull != null &&
                                  ai.name.trim().characters.first.runes.first >
                                      255
                              ? ai.name.trim().characters.first
                              : '🤖');
                      var cleanName = ai.name.trim();
                      if (ai.emoji != null && cleanName.startsWith(ai.emoji!)) {
                        cleanName = cleanName
                            .substring(ai.emoji!.length)
                            .trim();
                      } else if (emojiStr != '🤖' &&
                          cleanName.startsWith(emojiStr)) {
                        cleanName = cleanName.substring(emojiStr.length).trim();
                      }
                      if (cleanName.isEmpty) cleanName = ai.name;

                      return ListTile(
                        dense: true,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        leading: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF5850EC,
                            ).withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(
                                0xFF5850EC,
                              ).withValues(alpha: 0.2),
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            emojiStr,
                            style: const TextStyle(fontSize: 18),
                          ),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                cleanName,
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                  color: textPrimary,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF5850EC,
                                ).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: const Text(
                                'AI',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF5850EC),
                                ),
                              ),
                            ),
                          ],
                        ),

                        trailing: isSelected
                            ? const Icon(
                                Icons.check_rounded,
                                color: Color(0xFF5850EC),
                                size: 20,
                              )
                            : null,
                        onTap: () {
                          Navigator.pop(context);
                          widget.onSelect(
                            ai.id > 0 ? ai.id : null,
                            isAi: true,
                            assigneeType: 'AgentBot',
                          );
                        },
                      );
                    }),
                    Divider(height: 16, color: borderColor),
                  ],

                  // 2. Unassigned
                  ListTile(
                    dense: true,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    leading: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF382E).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.person_off_rounded,
                        color: Color(0xFFFF382E),
                        size: 20,
                      ),
                    ),
                    title: Text(
                      isArabic ? 'غير معين' : 'Unassigned',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),

                    trailing:
                        (widget.currentAssignee == null && !widget.isStatusBot)
                        ? const Icon(
                            Icons.check_rounded,
                            color: Color(0xFF4162E3),
                            size: 20,
                          )
                        : null,
                    onTap: () {
                      Navigator.pop(context);
                      widget.onSelect(null, isAi: false);
                    },
                  ),

                  Divider(height: 16, color: borderColor),

                  // 3. Team members
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    child: Text(
                      isArabic
                          ? 'أعضاء الفريق (${filteredAgents.length})'
                          : 'Team members (${filteredAgents.length})',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: textSecondary,
                      ),
                    ),
                  ),

                  if (filteredAgents.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Text(
                          isArabic
                              ? 'لا يوجد أعضاء مطابقين'
                              : 'No team members match your search',
                          style: TextStyle(fontSize: 12, color: textSecondary),
                        ),
                      ),
                    )
                  else
                    ..._buildGroupedTeamMembers(
                      agents: filteredAgents,
                      teams: widget.teams,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      borderColor: borderColor,
                      isArabic: isArabic,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildGroupedTeamMembers({
    required List<User> agents,
    required List<Team>? teams,
    required Color textPrimary,
    required Color textSecondary,
    required Color borderColor,
    required bool isArabic,
  }) {
    final widgets = <Widget>[];

    // If teams are available, group by teams
    if (teams != null && teams.isNotEmpty) {
      for (final team in teams) {
        // Match agents belonging to this team if account or team mapping exists
        final teamAgents = agents.where((a) {
          final q = team.name.toLowerCase();
          return a.accounts.any((acc) => acc.name.toLowerCase().contains(q));
        }).toList();

        if (teamAgents.isNotEmpty) {
          widgets.add(
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
              child: Row(
                children: [
                  Icon(
                    Icons.groups_rounded,
                    size: 16,
                    color: const Color(0xFF4162E3),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    team.name,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF4162E3),
                    ),
                  ),
                ],
              ),
            ),
          );
          for (final a in teamAgents) {
            widgets.add(_buildAgentTile(a, textPrimary, textSecondary));
          }
        }
      }

      // Remaining agents not in specific team
      final assignedAgentIds = widgets.isNotEmpty
          ? agents
                .where((a) {
                  return teams.any(
                    (t) => a.accounts.any(
                      (acc) =>
                          acc.name.toLowerCase().contains(t.name.toLowerCase()),
                    ),
                  );
                })
                .map((a) => a.id)
                .toSet()
          : <int>{};
      final remaining = agents
          .where((a) => !assignedAgentIds.contains(a.id))
          .toList();

      if (remaining.isNotEmpty) {
        if (widgets.isNotEmpty) {
          widgets.add(
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
              child: Text(
                isArabic ? 'أعضاء آخرون' : 'Other Members',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: textSecondary,
                ),
              ),
            ),
          );
        }
        for (final a in remaining) {
          widgets.add(_buildAgentTile(a, textPrimary, textSecondary));
        }
      }
    } else {
      // No teams specified, render clean agent tiles without email
      for (final a in agents) {
        widgets.add(_buildAgentTile(a, textPrimary, textSecondary));
      }
    }

    return widgets;
  }

  Widget _buildAgentTile(User agent, Color textPrimary, Color textSecondary) {
    final isSelected =
        widget.currentAssignee != null &&
        !widget.currentAssignee!.isBot &&
        widget.currentAssignee!.id == agent.id;
    final isOnline = agent.availabilityStatus == 'online';

    return ListTile(
      dense: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      leading: AvatarWidget(
        avatarUrl: agent.avatarUrl,
        name: agent.name,
        size: 36,
        isOnline: isOnline,
        showStatus: true,
      ),
      title: Text(
        agent.name,
        style: TextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check_rounded, color: Color(0xFF4162E3), size: 20)
          : null,
      onTap: () {
        Navigator.pop(context);
        widget.onSelect(agent.id, isAi: false, assigneeType: 'User');
      },
    );
  }
}
