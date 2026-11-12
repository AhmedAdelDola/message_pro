import 'package:flutter/material.dart';
import '../../../../data/models/user.dart';
import '../../../widgets/avatar_widget.dart';

class AssigneeSheet extends StatefulWidget {
  final List<User> agents;
  final User? currentAssignee;
  final bool isStatusBot;
  final Function(int? agentId, {bool isAi}) onSelect;

  const AssigneeSheet({
    super.key,
    required this.agents,
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
    final surfaceColor = isDark ? const Color(0xFF1E1F23) : const Color(0xFFF4F4F6);
    final borderColor = isDark ? const Color(0xFF2B2E35) : const Color(0xFFE5E7EB);
    final textPrimary = isDark ? const Color(0xFFEDEEF0) : const Color(0xFF282E34);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF626F7F);

    // AI Agents list - Virtual AI Bot
    final List<Map<String, dynamic>> aiAgents = [
      {
        'id': -1,
        'name': 'Sales agent',
        'emoji': '🤠',
        'role': isArabic ? 'مساعد المبيعات الذكي' : 'AI Sales Assistant',
      },
    ];

    final filteredAiAgents = aiAgents.where((ai) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      final name = (ai['name'] as String).toLowerCase();
      return name.contains(q);
    }).toList();

    // ALL workspace agents are team members
    final filteredAgents = widget.agents.where((a) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return a.name.toLowerCase().contains(q) || a.email.toLowerCase().contains(q);
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
                  color: isDark ? const Color(0xFF333742) : const Color(0xFFD1D5DB),
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
                      fontFamily: 'Gontserrat',
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.close_rounded, size: 20, color: textSecondary),
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
                  style: TextStyle(
                    fontSize: 13,
                    color: textPrimary,
                    fontFamily: 'Gontserrat',
                  ),
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.search_rounded, size: 18, color: textSecondary),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear_rounded, size: 16, color: textSecondary),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    hintText: isArabic ? 'البحث عن مسؤول...' : 'Search agents...',
                    hintStyle: TextStyle(
                      fontSize: 13,
                      color: textSecondary,
                      fontFamily: 'Gontserrat',
                    ),
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
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: Row(
                        children: [
                          Text(
                            isArabic ? 'الوكلاء الأذكياء' : 'AI Agents',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: textSecondary,
                              fontFamily: 'Gontserrat',
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF5850EC).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Text(
                              'AI',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF5850EC),
                                fontFamily: 'Gontserrat',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    ...filteredAiAgents.map((ai) {
                      final isSelected = widget.isStatusBot;

                      return ListTile(
                        dense: true,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        leading: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: const Color(0xFF5850EC).withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFF5850EC).withValues(alpha: 0.2)),
                          ),
                          alignment: Alignment.center,
                          child: Text(ai['emoji'], style: const TextStyle(fontSize: 18)),
                        ),
                        title: Text(
                          ai['name'],
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: textPrimary,
                            fontFamily: 'Gontserrat',
                          ),
                        ),
                        subtitle: Text(
                          ai['role'],
                          style: TextStyle(
                            fontSize: 11,
                            color: textSecondary,
                            fontFamily: 'Gontserrat',
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(Icons.check_rounded, color: Color(0xFF5850EC), size: 20)
                            : null,
                        onTap: () {
                          Navigator.pop(context);
                          widget.onSelect(null, isAi: true);
                        },
                      );
                    }),
                    Divider(height: 16, color: borderColor),
                  ],

                  // 2. Unassigned
                  ListTile(
                    dense: true,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
                        fontFamily: 'Gontserrat',
                      ),
                    ),
                    subtitle: Text(
                      isArabic ? 'إزالة تعيين المحادثة' : 'Clear conversation assignee',
                      style: TextStyle(
                        fontSize: 11,
                        color: textSecondary,
                        fontFamily: 'Gontserrat',
                      ),
                    ),
                    trailing: (widget.currentAssignee == null && !widget.isStatusBot)
                        ? const Icon(Icons.check_rounded, color: Color(0xFF4162E3), size: 20)
                        : null,
                    onTap: () {
                      Navigator.pop(context);
                      widget.onSelect(null, isAi: false);
                    },
                  ),

                  Divider(height: 16, color: borderColor),

                  // 3. Team members
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: Text(
                      isArabic
                          ? 'أعضاء الفريق (${filteredAgents.length})'
                          : 'Team members (${filteredAgents.length})',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: textSecondary,
                        fontFamily: 'Gontserrat',
                      ),
                    ),
                  ),

                  if (filteredAgents.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Text(
                          isArabic ? 'لا يوجد أعضاء مطابقين' : 'No team members match your search',
                          style: TextStyle(fontSize: 12, color: textSecondary, fontFamily: 'Gontserrat'),
                        ),
                      ),
                    )
                  else
                    ...filteredAgents.map((agent) {
                      final isSelected = widget.currentAssignee?.id == agent.id && !widget.isStatusBot;
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
                            fontFamily: 'Gontserrat',
                          ),
                        ),
                        subtitle: Text(
                          agent.email,
                          style: TextStyle(
                            fontSize: 11,
                            color: textSecondary,
                            fontFamily: 'Gontserrat',
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(Icons.check_rounded, color: Color(0xFF4162E3), size: 20)
                            : null,
                        onTap: () {
                          Navigator.pop(context);
                          widget.onSelect(agent.id, isAi: false);
                        },
                      );
                    }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
