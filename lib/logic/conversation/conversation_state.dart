import 'package:equatable/equatable.dart';
import '../../data/models/conversation.dart';
import '../../data/models/contact.dart';
import '../../data/models/user.dart';

class ConversationState extends Equatable {
  final List<Conversation> conversations;
  final bool isLoading;
  final String? errorMessage;
  final String status; // open, resolved, pending, snoozed
  final String assigneeType; // all, me, unassigned
  final int? selectedInboxId;
  final int? selectedTeamId;
  final String? selectedLabel;
  final int? selectedLifecycleStageId;
  final List<Inbox> inboxes;
  final List<Label> labels;
  final List<Team> teams;
  final List<User> agents;
  final List<LifecycleStage> lifecycleStages;

  const ConversationState({
    this.conversations = const [],
    this.isLoading = false,
    this.errorMessage,
    this.status = 'open',
    this.assigneeType = 'all',
    this.selectedInboxId,
    this.selectedTeamId,
    this.selectedLabel,
    this.selectedLifecycleStageId,
    this.inboxes = const [],
    this.labels = const [],
    this.teams = const [],
    this.agents = const [],
    this.lifecycleStages = const [],
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
    List<Inbox>? inboxes,
    List<Label>? labels,
    List<Team>? teams,
    List<User>? agents,
    List<LifecycleStage>? lifecycleStages,
    bool clearInbox = false,
    bool clearTeam = false,
    bool clearLabel = false,
    bool clearStage = false,
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
      inboxes: inboxes ?? this.inboxes,
      labels: labels ?? this.labels,
      teams: teams ?? this.teams,
      agents: agents ?? this.agents,
      lifecycleStages: lifecycleStages ?? this.lifecycleStages,
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
        inboxes,
        labels,
        teams,
        agents,
        lifecycleStages,
      ];
}
