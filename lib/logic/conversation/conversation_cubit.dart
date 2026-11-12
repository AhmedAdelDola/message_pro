import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:message_pro/data/models/message.dart';
import '../../core/network/websocket_client.dart';
import '../../core/services/sound_service.dart';
import '../../core/storage/secure_storage_service.dart';
import '../../data/models/contact.dart';
import '../../data/models/conversation.dart';
import '../../data/repositories/conversation_repository.dart';
import 'conversation_state.dart';

class ConversationCubit extends Cubit<ConversationState> {
  final IConversationRepository repo;
  final ActionCableClient ws;
  final SecureStorageService _storage = SecureStorageService();
  StreamSubscription<RealtimeEvent>? _eventSub;
  StreamSubscription<void>? _reconnectSub;

  ConversationCubit({
    required this.repo,
    required this.ws,
  }) : super(const ConversationState()) {
    _listenToRealtime();
    _listenToReconnect();
    loadAuxiliaryData();
    loadConversations();
  }

  void _listenToReconnect() {
    _reconnectSub = ws.onReconnected.listen((_) {
      loadAuxiliaryData();
      loadConversations(refresh: false);
    });
  }

  void _listenToRealtime() {
    _eventSub = ws.events.listen((event) async {
      final name = event.event;
      final payload = event.data;

      // Filter by active account ID to prevent cross-workspace conversation bleed
      final activeAccId = await _storage.getActiveAccountId();
      final eventAccId = payload['account_id'] ?? payload['account']?['id'];
      if (activeAccId != null && activeAccId > 0 && eventAccId != null) {
        final parsedAcc = eventAccId is int ? eventAccId : int.tryParse(eventAccId.toString());
        if (parsedAcc != null && parsedAcc > 0 && parsedAcc != activeAccId) {
          return; // Ignore event belonging to another workspace!
        }
      }

      if (name == 'conversation.created') {
        try {
          final conv = Conversation.fromJson(Map<String, dynamic>.from(payload));
          if (activeAccId != null && activeAccId > 0 && conv.accountId > 0 && conv.accountId != activeAccId) {
            return;
          }
          final matchesStatus = state.status == 'all' || conv.status == state.status;
          if (matchesStatus && conv.id > 0 && !state.conversations.any((c) => c.id == conv.id)) {
            emit(state.copyWith(
              conversations: [conv, ...state.conversations],
            ));
          }
        } catch (_) {}
      } else if (name == 'conversation.updated' ||
          name == 'conversation.status_changed' ||
          name == 'assignee.changed') {
        try {
          final conv = Conversation.fromJson(Map<String, dynamic>.from(payload));
          if (activeAccId != null && activeAccId > 0 && conv.accountId > 0 && conv.accountId != activeAccId) {
            return;
          }
          if (conv.id > 0) {
            final updated = state.conversations.map((c) => c.id == conv.id ? conv : c).toList();
            emit(state.copyWith(conversations: updated));
          }
        } catch (_) {}
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
        if (payload['message_type'] == 0) {
          SoundService().playIncomingSound();
        }
        final convId = payload['conversation_id'];
        if (convId != null) {
          final id = convId is int ? convId : int.tryParse(convId.toString());
          if (id != null) {
            final existingIndex = state.conversations.indexWhere((c) => c.id == id);
            if (existingIndex >= 0) {
              final existing = state.conversations[existingIndex];
              Message? newMsg;
              try {
                newMsg = Message.fromJson(Map<String, dynamic>.from(payload));
              } catch (_) {}
              final updated = existing.copyWith(
                lastMessage: newMsg ?? existing.lastMessage,
                unreadCount: existing.unreadCount + (payload['message_type'] == 0 ? 1 : 0),
                updatedAt: DateTime.now(),
              );
              final list = List<Conversation>.from(state.conversations);
              list.removeAt(existingIndex);
              list.insert(0, updated);
              emit(state.copyWith(conversations: list));
            } else if (payload['conversation'] is Map) {
              try {
                final newConv = Conversation.fromJson(Map<String, dynamic>.from(payload['conversation']));
                if (activeAccId != null && activeAccId > 0 && newConv.accountId > 0 && newConv.accountId != activeAccId) {
                  return;
                }
                final matchesStatus = state.status == 'all' || newConv.status == state.status;
                if (matchesStatus && !state.conversations.any((c) => c.id == newConv.id)) {
                  emit(state.copyWith(conversations: [newConv, ...state.conversations]));
                }
              } catch (_) {}
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
    final agentsRes = await repo.fetchAssignableAgents();
    final stagesRes = await repo.fetchLifecycleStages();

    emit(state.copyWith(
      inboxes: inboxesRes.getOrElse(() => []),
      labels: labelsRes.getOrElse(() => []),
      teams: teamsRes.getOrElse(() => []),
      agents: agentsRes.getOrElse(() => []),
      lifecycleStages: stagesRes.getOrElse(() => []),
    ));
  }

  Future<void> loadConversations({bool refresh = true}) async {
    if (refresh) {
      emit(state.copyWith(conversations: [], isLoading: true, page: 1, hasMore: true, errorMessage: null));
    } else {
      emit(state.copyWith(isLoading: true));
    }

    final result = await repo.getConversations(
      status: state.status,
      assigneeType: state.assigneeType,
      inboxId: state.selectedInboxId,
      teamId: state.selectedTeamId,
      label: state.selectedLabel,
      page: 1,
    );

    result.fold(
      (failure) => emit(state.copyWith(isLoading: false, errorMessage: failure.message)),
      (list) => emit(state.copyWith(
        conversations: list,
        isLoading: false,
        errorMessage: null,
        page: 1,
        hasMore: list.isNotEmpty,
      )),
    );
  }

  Future<void> loadMoreConversations() async {
    if (!state.hasMore || state.isLoadingMore || state.isLoading) return;

    emit(state.copyWith(isLoadingMore: true));
    final nextPage = state.page + 1;

    final result = await repo.getConversations(
      status: state.status,
      assigneeType: state.assigneeType,
      inboxId: state.selectedInboxId,
      teamId: state.selectedTeamId,
      label: state.selectedLabel,
      page: nextPage,
    );

    result.fold(
      (failure) => emit(state.copyWith(isLoadingMore: false)),
      (list) {
        if (list.isEmpty) {
          emit(state.copyWith(
            isLoadingMore: false,
            hasMore: false,
          ));
          return;
        }

        final existingIds = state.conversations.map((c) => c.id).toSet();
        final newItems = list.where((c) => !existingIds.contains(c.id)).toList();

        if (newItems.isEmpty) {
          emit(state.copyWith(
            isLoadingMore: false,
            hasMore: false,
          ));
          return;
        }

        emit(state.copyWith(
          conversations: [...state.conversations, ...newItems],
          isLoadingMore: false,
          page: nextPage,
          hasMore: list.length >= 15,
        ));
      },
    );
  }

  Future<void> onWorkspaceSwitched(int newAccountId) async {
    // Reset filters because inbox/team/label/stage IDs from previous workspace do not exist in the new workspace.
    // Clear previous conversations list and pagination immediately to prevent stale cross-workspace data bleed.
    emit(state.copyWith(
      conversations: const [],
      inboxes: const [],
      labels: const [],
      teams: const [],
      agents: const [],
      lifecycleStages: const [],
      page: 1,
      hasMore: true,
      isLoading: true,
      errorMessage: null,
      status: 'all',
      assigneeType: 'all',
      clearInbox: true,
      clearTeam: true,
      clearLabel: true,
      clearStage: true,
    ));

    // Re-fetch auxiliary data (inboxes, labels, teams, agents, lifecycle stages)
    await loadAuxiliaryData();

    // Re-fetch conversations for the new workspace
    await loadConversations(refresh: true);
  }

  void selectDrawerFilter({
    required String assigneeType,
    int? inboxId,
    String? label,
    int? stageId,
  }) {
    emit(state.copyWith(
      assigneeType: assigneeType,
      selectedInboxId: inboxId,
      clearInbox: inboxId == null,
      selectedLabel: label,
      clearLabel: label == null,
      selectedLifecycleStageId: stageId,
      clearStage: stageId == null,
    ));
    loadConversations();
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
    if (state.selectedInboxId == inboxId) return;
    emit(state.copyWith(
      selectedInboxId: inboxId,
      clearInbox: inboxId == null,
    ));
    loadConversations();
  }

  void setTeamFilter(int? teamId) {
    if (state.selectedTeamId == teamId) return;
    emit(state.copyWith(
      selectedTeamId: teamId,
      clearTeam: teamId == null,
    ));
    loadConversations();
  }

  void setLabelFilter(String? label) {
    if (state.selectedLabel == label) return;
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
    return state.conversations.where((c) => (c.effectiveLifecycleStage?.id ?? c.lifecycleStage?.id) == state.selectedLifecycleStageId).toList();
  }

  void updateContactLifecycleStage(int contactId, String stageName, {int? conversationId}) {
    final parsedStage = LifecycleStage.fromString(stageName);
    final updatedList = state.conversations.map((c) {
      if (c.contact.id == contactId || (conversationId != null && c.id == conversationId)) {
        final updatedContact = c.contact.copyWith(
          lifecycleStage: parsedStage,
          customAttributes: {
            ...c.contact.customAttributes,
            'lifecycle_stage': stageName,
            'lead_status': stageName,
          },
        );
        return c.copyWith(
          contact: updatedContact,
          lifecycleStage: parsedStage,
          customAttributes: {
            ...c.customAttributes,
            'lifecycle_stage': stageName,
            'lead_status': stageName,
          },
        );
      }
      return c;
    }).toList();

    emit(state.copyWith(conversations: updatedList));
  }

  @override
  Future<void> close() {
    _eventSub?.cancel();
    _reconnectSub?.cancel();
    return super.close();
  }
}
