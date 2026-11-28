import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/error/failures.dart';
import '../../core/network/websocket_client.dart';
import '../../core/services/performance_service.dart';
import '../../core/storage/secure_storage_service.dart';
import '../../data/models/contact.dart';
import '../../data/models/conversation.dart';
import '../../data/models/conversation_filter_options.dart';
import '../../data/models/message.dart';
import '../../data/repositories/conversation_repository.dart';
import 'conversation_state.dart';
import 'handlers/conversation_realtime_handler.dart';
import 'services/conversation_filter_helper.dart';

/// Cubit responsible for orchestrating conversation lists, filtering, pagination, and actions.
/// Follows SOLID principles by delegating real-time WebSocket events to [ConversationRealtimeHandler]
/// and filter/sorting logic to [ConversationFilterHelper].
class ConversationCubit extends Cubit<ConversationState> {
  final IConversationRepository repo;
  final ActionCableClient ws;
  final SecureStorageService _storage;
  final Stopwatch renderStopwatch = Stopwatch();
  late final ConversationRealtimeHandler _realtimeHandler;

  ConversationCubit({
    required this.repo,
    required this.ws,
    SecureStorageService? storage,
  })  : _storage = storage ?? SecureStorageService(),
        super(const ConversationState()) {
    _realtimeHandler = ConversationRealtimeHandler(
      ws: ws,
      storage: _storage,
    );
    _init();
  }

  @override
  void emit(ConversationState state) {
    if (!isClosed) {
      super.emit(state);
    }
  }

  // --- Initialization & Realtime ---

  Future<void> _init() async {
    try {
      final activeId = await _storage.getActiveAccountId();
      _realtimeHandler.activeAccountId = activeId;
    } catch (_) {}
    _listenToRealtime();
    loadAuxiliaryData();
    loadFilterOptions();
    loadConversations();
  }

  void _listenToRealtime() {
    _realtimeHandler.startListening(
      onConversationCreated: _handleConversationCreated,
      onConversationUpdated: _handleConversationUpdated,
      onConversationRead: _handleConversationRead,
      onMessageCreated: _handleMessageCreated,
      onPinsChanged: () => loadConversations(refresh: false),
      onReconnected: _handleReconnected,
    );
  }

  void _handleConversationCreated(Conversation conv) {
    if (!ConversationFilterHelper.matchesStatusFilter(conv, state.status)) return;
    if (!state.conversations.any((c) => c.id == conv.id)) {
      emit(state.copyWith(
        conversations: [conv, ...state.conversations],
      ));
    }
  }

  void _handleConversationUpdated(Conversation conv, bool hasExplicitPin) {
    final updated = state.conversations.map((c) {
      if (c.id == conv.id) {
        return hasExplicitPin ? conv : conv.copyWith(isPinned: c.isPinned);
      }
      return c;
    }).toList();
    emit(state.copyWith(conversations: updated));
  }

  void markConversationAsRead(int convId) {
    if (convId <= 0) return;
    _handleConversationRead(convId);
    repo.markAsRead(convId);
  }

  void _handleConversationRead(int convId) {
    final updated = state.conversations.map((c) {
      if (c.id == convId) {
        return c.copyWith(unreadCount: 0);
      }
      return c;
    }).toList();
    emit(state.copyWith(conversations: updated));
  }

  void _handleMessageCreated(int convId, Message? message, Map<String, dynamic> rawPayload) {
    final existingIndex = state.conversations.indexWhere((c) => c.id == convId);
    if (existingIndex >= 0) {
      final existing = state.conversations[existingIndex];
      final isIncoming = rawPayload['message_type'] == 0;
      final updated = existing.copyWith(
        lastMessage: message ?? existing.lastMessage,
        unreadCount: existing.unreadCount + (isIncoming ? 1 : 0),
        updatedAt: DateTime.now(),
      );
      final list = List<Conversation>.from(state.conversations);
      list.removeAt(existingIndex);
      list.insert(0, updated);
      emit(state.copyWith(conversations: list));
    } else if (rawPayload['conversation'] is Map) {
      try {
        final newConv = Conversation.fromJson(Map<String, dynamic>.from(rawPayload['conversation']));
        if (!_realtimeHandler.isEventForCurrentAccount(rawPayload, newConv.accountId)) return;
        if (newConv.id > 0 && ConversationFilterHelper.matchesStatusFilter(newConv, state.status)) {
          if (!state.conversations.any((c) => c.id == newConv.id)) {
            emit(state.copyWith(conversations: [newConv, ...state.conversations]));
          }
        }
      } catch (_) {}
    }
  }

  void _handleReconnected() async {
    final accId = await _storage.getActiveAccountId();
    _realtimeHandler.activeAccountId = accId;
    loadAuxiliaryData();
    loadFilterOptions();
    loadConversations(refresh: false);
  }

  // --- Auxiliary & Filter Options ---

  Future<void> loadAuxiliaryData() async {
    final inboxesFuture = repo.fetchInboxes();
    final labelsFuture = repo.fetchLabels();
    final teamsFuture = repo.fetchTeams();
    final stagesFuture = repo.fetchLifecycleStages();

    final inboxesRes = await inboxesFuture;
    final labelsRes = await labelsFuture;
    final teamsRes = await teamsFuture;
    final stagesRes = await stagesFuture;

    if (isClosed) return;

    final inboxes = inboxesRes.getOrElse(() => []);
    final labels = labelsRes.getOrElse(() => []);
    final teams = teamsRes.getOrElse(() => []);
    final stages = stagesRes.getOrElse(() => []);

    final agentsRes = await repo.fetchAssignableAgents(
      inboxIds: inboxes.map((i) => i.id).toList(),
    );
    if (isClosed) return;

    emit(state.copyWith(
      inboxes: inboxes,
      labels: labels,
      teams: teams,
      agents: agentsRes.getOrElse(() => []),
      lifecycleStages: stages,
    ));
  }

  Future<void> loadFilterOptions() async {
    if (isClosed) return;
    await PerformanceService.traceAsync('load_filter_options', () async {
      if (state.inboxes.isEmpty) {
        emit(state.copyWith(isLoadingFilters: true));
      }
      final res = await repo.fetchFilterOptions();
      if (isClosed) return;
      res.fold(
        (_) {
          if (!isClosed) emit(state.copyWith(isLoadingFilters: false));
        },
        (options) {
          if (!isClosed) {
            emit(state.copyWith(
              filterOptions: options,
              isLoadingFilters: false,
              inboxes: options.inboxes.isNotEmpty ? options.inboxes : state.inboxes,
              teams: options.teams.isNotEmpty ? options.teams : state.teams,
              agents: options.agents.isNotEmpty ? options.agents : state.agents,
            ));
          }
        },
      );
    });
  }

  // --- Conversations Loading & Pagination ---

  Future<void> loadConversations({bool refresh = true}) async {
    if (isClosed) return;
    final hasActiveFilter = state.selectedInboxId != null ||
        state.selectedTeamId != null ||
        state.selectedLabel != null ||
        state.selectedLifecycleStageId != null ||
        state.selectedAssigneeId != null ||
        state.selectedAssigneeAgentBotId != null ||
        state.status != 'all' ||
        state.assigneeType != 'all';

    final hasExistingData = state.conversations.isNotEmpty;
    if (!hasExistingData && !hasActiveFilter) {
      final activeAcc = _realtimeHandler.activeAccountId ?? _storage.activeAccountId;
      if (activeAcc != null && activeAcc > 0 && repo is ConversationRepository) {
        try {
          final cached = await (repo as ConversationRepository).getCachedConversations(activeAcc);
          if (cached.isNotEmpty && state.conversations.isEmpty && !isClosed) {
            emit(state.copyWith(conversations: cached, isLoading: false));
          }
        } catch (_) {}
      }
    }

    final hasDataNow = state.conversations.isNotEmpty;
    if (refresh && !hasDataNow) {
      emit(state.copyWith(conversations: [], isLoading: true, page: 1, hasMore: true, errorMessage: null));
    } else {
      emit(state.copyWith(isLoading: true));
    }

    final totalStopwatch = Stopwatch()..start();
    final fetchStopwatch = Stopwatch()..start();

    await PerformanceService.traceAsync(
      'load_conversations',
      () async {
        final result = await repo.getConversations(
          status: state.status,
          assigneeType: state.assigneeType,
          inboxId: state.selectedInboxId,
          teamId: state.selectedTeamId,
          label: state.selectedLabel,
          assigneeId: state.selectedAssigneeId,
          assigneeAgentBotId: state.selectedAssigneeAgentBotId,
          lifecycleStageId: state.selectedLifecycleStageId,
          page: 1,
        );
        fetchStopwatch.stop();
        final serverDurationMs = fetchStopwatch.elapsedMilliseconds;

        if (isClosed) return;

        result.fold(
          (failure) {
            if (!isClosed) emit(state.copyWith(isLoading: false, errorMessage: failure.message));
          },
          (list) {
            if (!isClosed) {
              renderStopwatch.reset();
              renderStopwatch.start();
              emit(state.copyWith(
                conversations: list,
                isLoading: false,
                errorMessage: null,
                page: 1,
                hasMore: list.isNotEmpty,
              ));
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (renderStopwatch.isRunning) {
                  renderStopwatch.stop();
                  totalStopwatch.stop();
                  final renderDurationMs = renderStopwatch.elapsedMilliseconds;
                  final totalDurationMs = totalStopwatch.elapsedMilliseconds;
                  debugPrint(
                    '════════════════════════════════════════════════════════\n'
                    '📊 [PERF METRICS] فلتر المحادثات (Status: ${state.status} | Assignee: ${state.assigneeType}):\n'
                    '   🌐 وقت استجابة السيرفر والشبكة: ${serverDurationMs}ms\n'
                    '   🎨 وقت رسم الواجهة وظهورها على الشاشة: ${renderDurationMs}ms\n'
                    '   ⏱️ إجمالي الوقت من لحظة الضغط حتى الظهور الفعلي: ${totalDurationMs}ms\n'
                    '════════════════════════════════════════════════════════',
                  );
                }
              });
              _prefetchTopConversations(list);
            }
          },
        );
      },
      attributes: {
        'status': state.status,
        'assignee_type': state.assigneeType,
        'refresh': refresh.toString(),
      },
      onResult: (trace, _) {
        trace.setMetric('conversation_count', state.conversations.length);
      },
    );
  }

  void _prefetchTopConversations(List<Conversation> list) {
    if (repo is! ConversationRepository) return;
    for (final c in list.take(3)) {
      if (repo.getCachedMessages(c.id) == null) {
        repo.getMessages(c.id);
      }
    }
  }

  Future<void> loadMoreConversations() async {
    if (!state.hasMore || state.isLoadingMore || state.isLoading || isClosed) return;

    emit(state.copyWith(isLoadingMore: true));
    final nextPage = state.page + 1;

    await PerformanceService.traceAsync(
      'load_more_conversations',
      () async {
        final result = await repo.getConversations(
          status: state.status,
          assigneeType: state.assigneeType,
          inboxId: state.selectedInboxId,
          teamId: state.selectedTeamId,
          label: state.selectedLabel,
          assigneeId: state.selectedAssigneeId,
          assigneeAgentBotId: state.selectedAssigneeAgentBotId,
          lifecycleStageId: state.selectedLifecycleStageId,
          page: nextPage,
        );

        if (isClosed) return;

        result.fold(
          (failure) => emit(state.copyWith(isLoadingMore: false)),
          (list) {
            if (list.isEmpty) {
              emit(state.copyWith(isLoadingMore: false, hasMore: false));
              return;
            }

            final existingIds = state.conversations.map((c) => c.id).toSet();
            final newItems = list.where((c) => !existingIds.contains(c.id)).toList();

            if (newItems.isEmpty) {
              emit(state.copyWith(isLoadingMore: false, hasMore: false));
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
      },
      attributes: {'page': nextPage.toString()},
      onResult: (trace, _) {
        trace.setMetric('loaded_count', state.conversations.length);
      },
    );
  }

  // --- Workspace & Cache Lifecycle ---

  void reset() {
    repo.clearCache();
    emit(const ConversationState());
  }

  int? _switchingAccountId;

  Future<void> onWorkspaceSwitched(int newAccountId) async {
    if (_switchingAccountId == newAccountId) return;
    if (_realtimeHandler.activeAccountId == newAccountId && state.conversations.isNotEmpty) {
      return;
    }
    _switchingAccountId = newAccountId;
    try {
      await PerformanceService.traceAsync('workspace_switch', () async {
        _realtimeHandler.activeAccountId = newAccountId;
        repo.clearCache();

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
          isLoadingFilters: true,
          errorMessage: null,
          status: 'all',
          assigneeType: 'all',
          clearInbox: true,
          clearTeam: true,
          clearLabel: true,
          clearStage: true,
          clearAssignee: true,
          clearAgentBot: true,
          filterOptions: const ConversationFilterOptions(),
        ));

        await Future.wait([
          loadAuxiliaryData(),
          loadFilterOptions(),
          loadConversations(refresh: true),
        ]);
      }, attributes: {'account_id': newAccountId.toString()});
    } finally {
      if (_switchingAccountId == newAccountId) {
        _switchingAccountId = null;
      }
    }
  }

  // --- Filters Management ---

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
      clearAssignee: true,
      clearAgentBot: true,
      conversations: const [],
      isLoading: true,
      page: 1,
      hasMore: true,
    ));
    loadConversations(refresh: true);
  }

  void setStatus(String status) {
    if (state.status == status) return;
    emit(state.copyWith(status: status, isLoading: true, page: 1));
    loadConversations();
  }

  void setAssigneeType(String type) {
    if (state.assigneeType == type && state.selectedAssigneeId == null && state.selectedAssigneeAgentBotId == null) return;
    emit(state.copyWith(
      assigneeType: type,
      clearAssignee: true,
      clearAgentBot: true,
      isLoading: true,
      page: 1,
    ));
    loadConversations();
  }

  void setAssigneeFilter(int? agentId) {
    if (state.selectedAssigneeId == agentId) return;
    emit(state.copyWith(
      selectedAssigneeId: agentId,
      clearAssignee: agentId == null,
      clearAgentBot: true,
      clearInbox: true,
      clearTeam: true,
      assigneeType: 'all',
      isLoading: true,
      page: 1,
    ));
    loadConversations();
  }

  void setAiAgentFilter(int? agentBotId) {
    if (state.selectedAssigneeAgentBotId == agentBotId) return;
    emit(state.copyWith(
      selectedAssigneeAgentBotId: agentBotId,
      clearAgentBot: agentBotId == null,
      clearAssignee: true,
      clearInbox: true,
      clearTeam: true,
      assigneeType: 'all',
      isLoading: true,
      page: 1,
    ));
    loadConversations();
  }

  void setInboxFilter(int? inboxId) {
    if (state.selectedInboxId == inboxId) return;
    emit(state.copyWith(
      selectedInboxId: inboxId,
      clearInbox: inboxId == null,
      clearAssignee: true,
      clearAgentBot: true,
      clearTeam: true,
      assigneeType: 'all',
      isLoading: true,
      page: 1,
    ));
    loadConversations();
  }

  void setTeamFilter(int? teamId) {
    if (state.selectedTeamId == teamId) return;
    emit(state.copyWith(
      selectedTeamId: teamId,
      clearTeam: teamId == null,
      clearAssignee: true,
      clearAgentBot: true,
      clearInbox: true,
      assigneeType: 'all',
      page: 1,
    ));
    loadConversations();
  }

  void clearAllFilters() {
    emit(state.copyWith(
      clearInbox: true,
      clearTeam: true,
      clearLabel: true,
      clearStage: true,
      clearAssignee: true,
      clearAgentBot: true,
      assigneeType: 'all',
      page: 1,
    ));
    loadConversations();
  }

  void setLabelFilter(String? label) {
    if (state.selectedLabel == label) return;
    emit(state.copyWith(
      selectedLabel: label,
      clearLabel: label == null,
      assigneeType: 'all',
      clearInbox: true,
      clearTeam: true,
      clearStage: true,
      clearAssignee: true,
      clearAgentBot: true,
      conversations: const [],
      isLoading: true,
      page: 1,
      hasMore: true,
    ));
    loadConversations(refresh: true);
  }

  void setLifecycleStageFilter(int? stageId) {
    if (state.selectedLifecycleStageId == stageId) return;
    emit(state.copyWith(
      selectedLifecycleStageId: stageId,
      clearStage: stageId == null,
      assigneeType: 'all',
      clearInbox: true,
      clearTeam: true,
      clearLabel: true,
      clearAssignee: true,
      clearAgentBot: true,
      conversations: const [],
      isLoading: true,
      page: 1,
      hasMore: true,
    ));
    loadConversations(refresh: true);
  }

  /// Sorted and filtered conversations based on active filters and pinned status.
  List<Conversation> get filteredConversations {
    return ConversationFilterHelper.applyFiltersAndSorting(
      state.conversations,
      selectedLifecycleStageId: state.selectedLifecycleStageId,
      isAllTab: state.assigneeType == 'all',
    );
  }

  // --- Conversation Actions ---

  Future<Either<Failure, void>> togglePinConversation(int conversationId) async {
    final index = state.conversations.indexWhere((c) => c.id == conversationId);
    if (index == -1) return const Right(null);
    final isCurrentlyPinned = state.conversations[index].isPinned;

    final updatedList = List<Conversation>.from(state.conversations);
    updatedList[index] = updatedList[index].copyWith(isPinned: !isCurrentlyPinned);
    emit(state.copyWith(conversations: updatedList));

    final res = isCurrentlyPinned
        ? await repo.unpinConversation(conversationId)
        : await repo.pinConversation(conversationId);

    res.fold(
      (failure) {
        final rollbackList = List<Conversation>.from(state.conversations);
        final rIndex = rollbackList.indexWhere((c) => c.id == conversationId);
        if (rIndex != -1) {
          rollbackList[rIndex] = rollbackList[rIndex].copyWith(isPinned: isCurrentlyPinned);
          emit(state.copyWith(conversations: rollbackList));
        }
      },
      (_) {},
    );
    return res;
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

  Future<Either<Failure, void>> toggleConversationStatus(int conversationId, String status) async {
    final res = await repo.toggleStatus(conversationId, status);
    res.fold((_) {}, (_) {
      loadConversations();
    });
    return res;
  }

  Future<void> muteConversation(int conversationId) async {
    await repo.muteConversation(conversationId);
    loadConversations();
  }

  Future<void> unmuteConversation(int conversationId) async {
    await repo.unmuteConversation(conversationId);
    loadConversations();
  }

  Future<Either<Failure, List<Conversation>>> searchConversations(String query) async {
    return await repo.searchConversations(query);
  }

  Future<Either<Failure, Conversation>> getConversation(int id) async {
    return await repo.getConversation(id);
  }

  Future<Either<Failure, List<Map<String, dynamic>>>> getPhoneDestinations({String? phoneNumber}) async {
    return await repo.getPhoneDestinations(phoneNumber: phoneNumber);
  }

  Future<Either<Failure, Conversation>> startDirectChat({
    required String phoneNumber,
    required int inboxId,
    String? sourceId,
    String? contactName,
  }) async {
    final res = await repo.startDirectChat(
      phoneNumber: phoneNumber,
      inboxId: inboxId,
      sourceId: sourceId ?? phoneNumber,
      contactName: contactName,
    );
    res.fold((_) {}, (_) {
      loadConversations(refresh: true);
    });
    return res;
  }

  @override
  Future<void> close() {
    _realtimeHandler.dispose();
    return super.close();
  }
}
