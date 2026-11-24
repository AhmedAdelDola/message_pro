import '../../../data/models/conversation.dart';

/// Helper utility for client-side conversation filtering and sorting.
class ConversationFilterHelper {
  ConversationFilterHelper._();

  /// Filters conversations by lifecycle stage and sorts pinned conversations to the top only in the 'all' tab.
  static List<Conversation> applyFiltersAndSorting(
    List<Conversation> conversations, {
    int? selectedLifecycleStageId,
    bool isAllTab = true,
  }) {
    var list = conversations;
    if (selectedLifecycleStageId != null) {
      list = list.where((c) {
        final stageId = c.effectiveLifecycleStage?.id ?? c.lifecycleStage?.id;
        return stageId == selectedLifecycleStageId;
      }).toList();
    }

    if (!isAllTab) {
      return list;
    }

    final sorted = List<Conversation>.from(list);
    sorted.sort((a, b) {
      if (a.isPinned != b.isPinned) {
        return a.isPinned ? -1 : 1;
      }
      return 0;
    });
    return sorted;
  }

  /// Determines if a conversation matches the current status filter.
  static bool matchesStatusFilter(Conversation conv, String currentStatus) {
    if (currentStatus == 'all') return true;
    return conv.status.toLowerCase() == currentStatus.toLowerCase();
  }
}
