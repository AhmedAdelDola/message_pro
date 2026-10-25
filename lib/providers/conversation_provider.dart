import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/conversation.dart';
import '../data/models/contact.dart';
import '../data/models/user.dart';
import '../data/repositories/conversation_repository.dart';
import '../core/network/websocket_client.dart';

class ConversationState {
  final List<Conversation> conversations;
  final bool isLoading;
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
}

class ConversationNotifier extends StateNotifier<ConversationState> {
  final ConversationRepository _repo = ConversationRepository();
  final ActionCableClient _ws = ActionCableClient();
  StreamSubscription<RealtimeEvent>? _eventSub;

  ConversationNotifier() : super(const ConversationState()) {
    _listenToRealtime();
    loadAuxiliaryData();
    loadConversations();
  }

  void _listenToRealtime() {
    _eventSub = _ws.events.listen((event) {
      final name = event.event;
      final payload = event.data;

      if (name == 'conversation.created') {
        final conv = Conversation.fromJson(payload);
        state = state.copyWith(
          conversations: [conv, ...state.conversations],
        );
      } else if (name == 'conversation.updated' || name == 'conversation.status_changed' || name == 'assignee.changed') {
        final conv = Conversation.fromJson(payload);
        final updated = state.conversations.map((c) => c.id == conv.id ? conv : c).toList();
        state = state.copyWith(conversations: updated);
      } else if (name == 'conversation.read') {
        final convId = payload['id'] ?? payload['conversation_id'];
        if (convId != null) {
          final id = convId is int ? convId : int.tryParse(convId.toString());
          if (id != null) {
            final updated = state.conversations.map((c) {
              if (c.id == id) {
                return c.copyWith(unreadCount: 0);
              }
              return c;
            }).toList();
            state = state.copyWith(conversations: updated);
          }
        }
      } else if (name == 'message.created') {
        final convId = payload['conversation_id'];
        if (convId != null) {
          final id = convId is int ? convId : int.tryParse(convId.toString());
          if (id != null) {
            final existingIndex = state.conversations.indexWhere((c) => c.id == id);
            if (existingIndex >= 0) {
              final existing = state.conversations[existingIndex];
              final updated = existing.copyWith(
                unreadCount: existing.unreadCount + (payload['message_type'] == 0 ? 1 : 0),
                updatedAt: DateTime.now(),
              );
              final list = List<Conversation>.from(state.conversations);
              list.removeAt(existingIndex);
              list.insert(0, updated);
              state = state.copyWith(conversations: list);
            } else {
              loadConversations();
            }
          }
        }
      }
    });
  }

  Future<void> loadAuxiliaryData() async {
    final results = await Future.wait([
      _repo.fetchInboxes(),
      _repo.fetchLabels(),
      _repo.fetchTeams(),
      _repo.fetchAgents(),
      _repo.fetchLifecycleStages(),
    ]);

    state = state.copyWith(
      inboxes: results[0] as List<Inbox>,
      labels: results[1] as List<Label>,
      teams: results[2] as List<Team>,
      agents: results[3] as List<User>,
      lifecycleStages: results[4] as List<LifecycleStage>,
    );
  }

  Future<void> loadConversations() async {
    state = state.copyWith(isLoading: true);
    try {
      final list = await _repo.getConversations(
        status: state.status,
        assigneeType: state.assigneeType,
        inboxId: state.selectedInboxId,
        teamId: state.selectedTeamId,
        label: state.selectedLabel,
      );
      state = state.copyWith(conversations: list, isLoading: false);
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  void setStatus(String status) {
    if (state.status == status) return;
    state = state.copyWith(status: status);
    loadConversations();
  }

  void setAssigneeType(String type) {
    if (state.assigneeType == type) return;
    state = state.copyWith(assigneeType: type);
    loadConversations();
  }

  void setInboxFilter(int? inboxId) {
    state = state.copyWith(
      selectedInboxId: inboxId,
      clearInbox: inboxId == null,
    );
    loadConversations();
  }

  void setTeamFilter(int? teamId) {
    state = state.copyWith(
      selectedTeamId: teamId,
      clearTeam: teamId == null,
    );
    loadConversations();
  }

  void setLabelFilter(String? label) {
    state = state.copyWith(
      selectedLabel: label,
      clearLabel: label == null,
    );
    loadConversations();
  }

  void setLifecycleStageFilter(int? stageId) {
    state = state.copyWith(
      selectedLifecycleStageId: stageId,
      clearStage: stageId == null,
    );
  }

  List<Conversation> get filteredConversations {
    if (state.selectedLifecycleStageId == null) return state.conversations;
    return state.conversations.where((c) => c.lifecycleStage?.id == state.selectedLifecycleStageId).toList();
  }

  @override
  void dispose() {
    _eventSub?.cancel();
    super.dispose();
  }
}

final conversationProvider = StateNotifierProvider<ConversationNotifier, ConversationState>((ref) {
  return ConversationNotifier();
});
