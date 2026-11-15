import 'package:equatable/equatable.dart';
import '../../data/models/conversation.dart';
import '../../data/models/contact.dart';
import '../../data/models/user.dart';
import '../../data/models/conversation_filter_options.dart';

class ConversationState extends Equatable {
  final List<Conversation> conversations;
  final bool isLoading;
  final String? errorMessage;
  final String status; // all, open, resolved, pending, snoozed
  final String assigneeType; // all, me, unassigned
  final int? selectedInboxId;
  final int? selectedTeamId;
  final String? selectedLabel;
  final int? selectedLifecycleStageId;
  final int? selectedAssigneeId;
  final int? selectedAssigneeAgentBotId;
  final ConversationFilterOptions? filterOptions;
  final bool isLoadingFilters;
  final List<Inbox> inboxes;
  final List<Label> labels;
  final List<Team> teams;
  final List<User> agents;
  final List<LifecycleStage> lifecycleStages;
  final int page;
  final bool isLoadingMore;
  final bool hasMore;

  const ConversationState({
    this.conversations = const [],
    this.isLoading = false,
    this.errorMessage,
    this.status = 'all',
    this.assigneeType = 'all',
    this.selectedInboxId,
    this.selectedTeamId,
    this.selectedLabel,
    this.selectedLifecycleStageId,
    this.selectedAssigneeId,
    this.selectedAssigneeAgentBotId,
    this.filterOptions,
    this.isLoadingFilters = false,
    this.inboxes = const [],
    this.labels = const [],
    this.teams = const [],
    this.agents = const [],
    this.lifecycleStages = const [],
    this.page = 1,
    this.isLoadingMore = false,
    this.hasMore = true,
  });

  ConversationState copyWith({
    List<Conversation>? conversations,
    bool? isLoading,
    String? errorMessage,
    String? status,
    String? assigneeType,
    int? selectedInboxId,
    int? selectedTeamId,
    String? selectedLabel,
    int? selectedLifecycleStageId,
    int? selectedAssigneeId,
    int? selectedAssigneeAgentBotId,
    ConversationFilterOptions? filterOptions,
    bool? isLoadingFilters,
    List<Inbox>? inboxes,
    List<Label>? labels,
    List<Team>? teams,
    List<User>? agents,
    List<LifecycleStage>? lifecycleStages,
    int? page,
    bool? isLoadingMore,
    bool? hasMore,
    bool clearInbox = false,
    bool clearTeam = false,
    bool clearLabel = false,
    bool clearStage = false,
    bool clearAssignee = false,
    bool clearAgentBot = false,
  }) {
    return ConversationState(
      conversations: conversations ?? this.conversations,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      status: status ?? this.status,
      assigneeType: assigneeType ?? this.assigneeType,
      selectedInboxId: clearInbox ? null : (selectedInboxId ?? this.selectedInboxId),
      selectedTeamId: clearTeam ? null : (selectedTeamId ?? this.selectedTeamId),
      selectedLabel: clearLabel ? null : (selectedLabel ?? this.selectedLabel),
      selectedLifecycleStageId: clearStage ? null : (selectedLifecycleStageId ?? this.selectedLifecycleStageId),
      selectedAssigneeId: clearAssignee ? null : (selectedAssigneeId ?? this.selectedAssigneeId),
      selectedAssigneeAgentBotId: clearAgentBot ? null : (selectedAssigneeAgentBotId ?? this.selectedAssigneeAgentBotId),
      filterOptions: filterOptions ?? this.filterOptions,
      isLoadingFilters: isLoadingFilters ?? this.isLoadingFilters,
      inboxes: inboxes ?? this.inboxes,
      labels: labels ?? this.labels,
      teams: teams ?? this.teams,
      agents: agents ?? this.agents,
      lifecycleStages: lifecycleStages ?? this.lifecycleStages,
      page: page ?? this.page,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
    );
  }

  @override
  List<Object?> get props => [
        conversations,
        isLoading,
        errorMessage,
        status,
        assigneeType,
        selectedInboxId,
        selectedTeamId,
        selectedLabel,
        selectedLifecycleStageId,
        selectedAssigneeId,
        selectedAssigneeAgentBotId,
        filterOptions,
        isLoadingFilters,
        inboxes,
        labels,
        teams,
        agents,
        lifecycleStages,
        page,
        isLoadingMore,
        hasMore,
      ];
}
