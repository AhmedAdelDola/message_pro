import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/network/websocket_client.dart';
import '../../data/models/message.dart';
import '../../data/repositories/conversation_repository.dart';
import 'chat_state.dart';

class ChatCubit extends Cubit<ChatState> {
  final int conversationId;
  final IConversationRepository repo;
  final ActionCableClient ws;
  StreamSubscription<RealtimeEvent>? _eventSub;

  ChatCubit({
    required this.conversationId,
    required this.repo,
    required this.ws,
  }) : super(ChatState(conversationId: conversationId)) {
    loadMessages();
    loadCannedResponses();
    _listenToRealtime();
    repo.markAsRead(conversationId);
  }

  void _listenToRealtime() {
    _eventSub = ws.events.listen((event) {
      final name = event.event;
      final payload = event.data;

      if (name == 'message.created') {
        final convId = payload['conversation_id'];
        if (convId != null && convId == conversationId) {
          final msg = Message.fromJson(payload);
          if (!state.messages.any((m) => m.id == msg.id)) {
            emit(state.copyWith(messages: [...state.messages, msg]));
            repo.markAsRead(conversationId);
          }
        }
      } else if (name == 'conversation.typing_on') {
        final convId = payload['conversation_id'];
        if (convId != null && convId == conversationId) {
          final user = payload['user'];
          final name = user is Map ? user['name']?.toString() ?? 'User' : 'Customer';
          emit(state.copyWith(typingUsers: {...state.typingUsers, name}));
        }
      } else if (name == 'conversation.typing_off') {
        final convId = payload['conversation_id'];
        if (convId != null && convId == conversationId) {
          final user = payload['user'];
          final name = user is Map ? user['name']?.toString() ?? 'User' : 'Customer';
          final updated = Set<String>.from(state.typingUsers)..remove(name);
          emit(state.copyWith(typingUsers: updated));
        }
      }
    });
  }

  Future<void> loadMessages() async {
    emit(state.copyWith(isLoading: true));
    final result = await repo.getMessages(conversationId);
    result.fold(
      (failure) => emit(state.copyWith(isLoading: false, errorMessage: failure.message)),
      (list) => emit(state.copyWith(messages: list, isLoading: false, errorMessage: null)),
    );
  }

  Future<void> loadCannedResponses() async {
    final result = await repo.fetchCannedResponses();
    result.fold((_) {}, (list) {
      emit(state.copyWith(cannedResponses: list));
    });
  }

  Future<bool> sendMessage({
    required String content,
    bool isPrivate = false,
    List<String>? attachmentPaths,
  }) async {
    emit(state.copyWith(isSending: true));
    final result = await repo.sendMessage(
      conversationId: conversationId,
      content: content,
      isPrivate: isPrivate,
      attachmentPaths: attachmentPaths,
    );

    return result.fold(
      (failure) {
        emit(state.copyWith(isSending: false, errorMessage: failure.message));
        return false;
      },
      (sent) {
        if (!state.messages.any((m) => m.id == sent.id)) {
          emit(state.copyWith(
            messages: [...state.messages, sent],
            isSending: false,
          ));
        } else {
          emit(state.copyWith(isSending: false));
        }
        return true;
      },
    );
  }

  Future<void> toggleStatus(String newStatus) async {
    final result = await repo.toggleStatus(conversationId, newStatus);
    result.fold((_) {}, (_) {
      emit(state.copyWith(status: newStatus));
    });
  }

  Future<void> assignAgent(int? agentId) async {
    await repo.assignAgent(conversationId, agentId);
  }

  Future<void> assignTeam(int? teamId) async {
    await repo.assignTeam(conversationId, teamId);
  }

  Future<void> updateLifecycleStage(int stageId) async {
    await repo.updateLifecycleStage(conversationId, stageId);
  }

  @override
  Future<void> close() {
    _eventSub?.cancel();
    return super.close();
  }
}
