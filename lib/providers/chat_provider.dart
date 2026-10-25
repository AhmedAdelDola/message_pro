import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/message.dart';
import '../data/repositories/conversation_repository.dart';
import '../core/network/websocket_client.dart';

class ChatState {
  final int conversationId;
  final List<Message> messages;
  final bool isLoading;
  final bool isSending;
  final String status;
  final Set<String> typingUsers;
  final List<Map<String, String>> cannedResponses;

  const ChatState({
    required this.conversationId,
    this.messages = const [],
    this.isLoading = false,
    this.isSending = false,
    this.status = 'open',
    this.typingUsers = const {},
    this.cannedResponses = const [],
  });

  ChatState copyWith({
    int? conversationId,
    List<Message>? messages,
    bool? isLoading,
    bool? isSending,
    String? status,
    Set<String>? typingUsers,
    List<Map<String, String>>? cannedResponses,
  }) {
    return ChatState(
      conversationId: conversationId ?? this.conversationId,
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isSending: isSending ?? this.isSending,
      status: status ?? this.status,
      typingUsers: typingUsers ?? this.typingUsers,
      cannedResponses: cannedResponses ?? this.cannedResponses,
    );
  }
}

class ChatNotifier extends StateNotifier<ChatState> {
  final int conversationId;
  final ConversationRepository _repo = ConversationRepository();
  final ActionCableClient _ws = ActionCableClient();
  StreamSubscription<RealtimeEvent>? _eventSub;

  ChatNotifier(this.conversationId) : super(ChatState(conversationId: conversationId)) {
    loadMessages();
    loadCannedResponses();
    _listenToRealtime();
    _repo.markAsRead(conversationId);
  }

  void _listenToRealtime() {
    _eventSub = _ws.events.listen((event) {
      final name = event.event;
      final payload = event.data;

      if (name == 'message.created') {
        final convId = payload['conversation_id'];
        if (convId != null && convId == conversationId) {
          final msg = Message.fromJson(payload);
          // Check if message already exists
          if (!state.messages.any((m) => m.id == msg.id)) {
            state = state.copyWith(messages: [...state.messages, msg]);
            _repo.markAsRead(conversationId);
          }
        }
      } else if (name == 'conversation.typing_on') {
        final convId = payload['conversation_id'];
        if (convId != null && convId == conversationId) {
          final user = payload['user'];
          final name = user is Map ? user['name']?.toString() ?? 'User' : 'Customer';
          state = state.copyWith(typingUsers: {...state.typingUsers, name});
        }
      } else if (name == 'conversation.typing_off') {
        final convId = payload['conversation_id'];
        if (convId != null && convId == conversationId) {
          final user = payload['user'];
          final name = user is Map ? user['name']?.toString() ?? 'User' : 'Customer';
          final updated = Set<String>.from(state.typingUsers)..remove(name);
          state = state.copyWith(typingUsers: updated);
        }
      }
    });
  }

  Future<void> loadMessages() async {
    state = state.copyWith(isLoading: true);
    try {
      final list = await _repo.getMessages(conversationId);
      state = state.copyWith(messages: list, isLoading: false);
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> loadCannedResponses() async {
    final list = await _repo.fetchCannedResponses();
    state = state.copyWith(cannedResponses: list);
  }

  Future<bool> sendMessage({
    required String content,
    bool isPrivate = false,
    List<String>? attachmentPaths,
  }) async {
    state = state.copyWith(isSending: true);
    try {
      final sent = await _repo.sendMessage(
        conversationId: conversationId,
        content: content,
        isPrivate: isPrivate,
        attachmentPaths: attachmentPaths,
      );

      if (!state.messages.any((m) => m.id == sent.id)) {
        state = state.copyWith(
          messages: [...state.messages, sent],
          isSending: false,
        );
      } else {
        state = state.copyWith(isSending: false);
      }
      return true;
    } catch (_) {
      state = state.copyWith(isSending: false);
      return false;
    }
  }

  Future<void> toggleStatus(String newStatus) async {
    try {
      await _repo.toggleStatus(conversationId, newStatus);
      state = state.copyWith(status: newStatus);
    } catch (_) {}
  }

  Future<void> assignAgent(int? agentId) async {
    await _repo.assignAgent(conversationId, agentId);
  }

  Future<void> assignTeam(int? teamId) async {
    await _repo.assignTeam(conversationId, teamId);
  }

  Future<void> updateLifecycleStage(int stageId) async {
    await _repo.updateLifecycleStage(conversationId, stageId);
  }

  @override
  void dispose() {
    _eventSub?.cancel();
    super.dispose();
  }
}

final chatProvider = StateNotifierProvider.family<ChatNotifier, ChatState, int>((ref, conversationId) {
  return ChatNotifier(conversationId);
});
