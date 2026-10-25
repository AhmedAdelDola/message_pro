import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../providers/conversation_provider.dart';

class InboxFilterBar extends ConsumerWidget {
  const InboxFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(conversationProvider);
    final notifier = ref.read(conversationProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Assignee Tabs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              height: 38,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF262626) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  _buildTab(
                    label: 'الكل',
                    isSelected: state.assigneeType == 'all',
                    onTap: () => notifier.setAssigneeType('all'),
                    isDark: isDark,
                  ),
                  _buildTab(
                    label: 'محادثاتي',
                    isSelected: state.assigneeType == 'me',
                    onTap: () => notifier.setAssigneeType('me'),
                    isDark: isDark,
                  ),
                  _buildTab(
                    label: 'غير معين',
                    isSelected: state.assigneeType == 'unassigned',
                    onTap: () => notifier.setAssigneeType('unassigned'),
                    isDark: isDark,
                  ),
                ],
              ),
            ),
          ),

          // Horizontal Filter Chips (Status & Inboxes)
          SizedBox(
            height: 42,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildStatusChip('open', 'مفتوحة (Open)', state.status, notifier),
                _buildStatusChip('pending', 'معلقة (Pending)', state.status, notifier),
                _buildStatusChip('snoozed', 'مؤجلة (Snoozed)', state.status, notifier),
                _buildStatusChip('resolved', 'مغلقة (Resolved)', state.status, notifier),

                if (state.inboxes.isNotEmpty) ...[
                  const VerticalDivider(width: 16, indent: 8, endIndent: 8),
                  ...state.inboxes.map((inbox) {
                    final isSel = state.selectedInboxId == inbox.id;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: FilterChip(
                        selected: isSel,
                        label: Text(inbox.name, style: const TextStyle(fontSize: 12)),
                        onSelected: (_) => notifier.setInboxFilter(isSel ? null : inbox.id),
                        selectedColor: AppColors.primary.withValues(alpha: 0.15),
                        checkmarkColor: AppColors.primary,
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }

  Widget _buildTab({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? AppColors.darkCard : Colors.white)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? AppColors.primaryLight
                    : (isDark ? Colors.grey[400] : Colors.grey[600]),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(
    String statusKey,
    String label,
    String currentStatus,
    ConversationNotifier notifier,
  ) {
    final isSelected = currentStatus == statusKey;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        selected: isSelected,
        label: Text(label, style: const TextStyle(fontSize: 12)),
        onSelected: (selected) {
          if (selected) notifier.setStatus(statusKey);
        },
        selectedColor: AppColors.primary.withValues(alpha: 0.15),
      ),
    );
  }
}
