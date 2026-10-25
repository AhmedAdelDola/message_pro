import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/network/websocket_client.dart';
import '../../data/models/conversation.dart';
import '../../data/repositories/conversation_repository.dart';
import 'conversation_state.dart';

class ConversationCubit extends Cubit<ConversationState> {
  final IConversationRepository repo;
  final ActionCableClient ws;
  StreamSubscription<RealtimeEvent>? _eventSub;

  ConversationCubit({
    required this.repo,
    required this.ws,
  }) : super(const ConversationState()) {
    _listenToRealtime();
    loadAuxiliaryData();
    loadConversations();
  }

  void _listenToRealtime() {
    _eventSub = ws.events.listen((event) {
      final name = event.event;
      final payload = event.data;

      if (name == 'conversation.created') {
        final conv = Conversation.fromJson(payload);
        emit(state.copyWith(
          conversations: [conv, ...state.conversations],
        ));
      } else if (name == 'conversation.updated' ||
          name == 'conversation.status_changed' ||
          name == 'assignee.changed') {
        final conv = Conversation.fromJson(payload);
        final updated = state.conversations.map((c) => c.id == conv.id ? conv : c).toList();
        emit(state.copyWith(conversations: updated));
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
            emit(state.copyWith(conversations: updated));
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
              emit(state.copyWith(conversations: list));
            } else {
              loadConversations();
            }
          }
        }
      }
    });
  }

  Future<void> loadAuxiliaryData() async {
    final inboxesRes = await repo.fetchInboxes();
    final labelsRes = await repo.fetchLabels();
    final teamsRes = await repo.fetchTeams();
    final agentsRes = await repo.fetchAgents();
    final stagesRes = await repo.fetchLifecycleStages();

    emit(state.copyWith(
      inboxes: inboxesRes.getOrElse(() => []),
      labels: labelsRes.getOrElse(() => []),
      teams: teamsRes.getOrElse(() => []),
      agents: agentsRes.getOrElse(() => []),
      lifecycleStages: stagesRes.getOrElse(() => []),
    ));
  }

  Future<void> loadConversations() async {
    emit(state.copyWith(isLoading: true));
    final result = await repo.getConversations(
      status: state.status,
      assigneeType: state.assigneeType,
      inboxId: state.selectedInboxId,
      teamId: state.selectedTeamId,
      label: state.selectedLabel,
    );

    result.fold(
      (failure) => emit(state.copyWith(isLoading: false, errorMessage: failure.message)),
      (list) => emit(state.copyWith(conversations: list, isLoading: false, errorMessage: null)),
    );
  }

  void setStatus(String status) {
    if (state.status == status) return;
    emit(state.copyWith(status: status));
    loadConversations();
  }

  void setAssigneeType(String type) {
    if (state.assigneeType == type) return;
    emit(state.copyWith(assigneeType: type));
    loadConversations();
  }

  void setInboxFilter(int? inboxId) {
    emit(state.copyWith(
      selectedInboxId: inboxId,
      clearInbox: inboxId == null,
    ));
    loadConversations();
  }

  void setTeamFilter(int? teamId) {
    emit(state.copyWith(
      selectedTeamId: teamId,
      clearTeam: teamId == null,
    ));
    loadConversations();
  }

  void setLabelFilter(String? label) {
    emit(state.copyWith(
      selectedLabel: label,
      clearLabel: label == null,
    ));
    loadConversations();
  }

  void setLifecycleStageFilter(int? stageId) {
    emit(state.copyWith(
      selectedLifecycleStageId: stageId,
      clearStage: stageId == null,
    ));
  }

  List<Conversation> get filteredConversations {
    if (state.selectedLifecycleStageId == null) return state.conversations;
    return state.conversations.where((c) => c.lifecycleStage?.id == state.selectedLifecycleStageId).toList();
  }

  @override
  Future<void> close() {
    _eventSub?.cancel();
    return super.close();
  }
}
