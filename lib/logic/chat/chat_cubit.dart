import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/network/websocket_client.dart';
import '../../core/services/sound_service.dart';
import '../../data/models/message.dart';
import '../../data/models/message_template.dart';
import '../../data/models/message_template_registry.dart';
import '../../data/repositories/conversation_repository.dart';
import 'chat_state.dart';

class ChatCubit extends Cubit<ChatState> {
  final int conversationId;
  final IConversationRepository repo;
  final ActionCableClient ws;
  DateTime? contactLastSeenAt;
  StreamSubscription<RealtimeEvent>? _eventSub;
  StreamSubscription<void>? _reconnectSub;

  ChatCubit({
    required this.conversationId,
    required this.repo,
    required this.ws,
    this.contactLastSeenAt,
  }) : super(ChatState(conversationId: conversationId)) {
    loadMessages();
    loadCannedResponses();
    _listenToRealtime();
    _listenToReconnect();
    repo.markAsRead(conversationId);
  }

  void _listenToReconnect() {
    _reconnectSub = ws.onReconnected.listen((_) {
      loadMessages();
    });
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
            var currentMessages = [...state.messages, msg];
            // If the contact sends a message, all prior outgoing messages have been seen
            if (!msg.isOutgoing && !msg.isPrivateNote && !msg.isActivity) {
              SoundService().playIncomingSound();
              contactLastSeenAt = msg.createdAt;
              currentMessages = currentMessages.map((m) {
                if (m.isOutgoing && !m.isFailed && !m.isPrivateNote && m.status != 'read') {
                  return m.copyWith(status: 'read');
                }
                return m;
              }).toList();
            }
            emit(state.copyWith(messages: currentMessages));
            repo.markAsRead(conversationId);
          }
        }
      } else if (name == 'message.updated') {
        final convId = payload['conversation_id'];
        if (convId != null && convId == conversationId) {
          final updatedMsg = Message.fromJson(payload);
          final index = state.messages.indexWhere((m) => m.id == updatedMsg.id);
          if (index != -1) {
            final updatedList = List<Message>.from(state.messages);
            updatedList[index] = updatedMsg;
            emit(state.copyWith(messages: updatedList));
          }
        }
      } else if (name == 'conversation.contact_last_seen_at' || name == 'conversation.read') {
        final convId = payload['id'] ?? payload['conversation_id'];
        if (convId != null && convId == conversationId) {
          final lastSeen = payload['contact_last_seen_at'];
          if (lastSeen is num && lastSeen > 0) {
            final seenDt = DateTime.fromMillisecondsSinceEpoch(
              lastSeen > 1e11 ? lastSeen.toInt() : (lastSeen * 1000).toInt(),
            );
            contactLastSeenAt = seenDt;
            final updatedList = state.messages.map((m) {
              if (m.isOutgoing && !m.isFailed && (m.createdAt.isBefore(seenDt) || m.createdAt.isAtSameMomentAs(seenDt))) {
                return m.copyWith(status: 'read');
              }
              return m;
            }).toList();
            emit(state.copyWith(messages: updatedList));
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
    emit(state.copyWith(isLoading: true, hasMoreMessages: true, errorMessage: null));
    final result = await repo.getMessages(conversationId);
    result.fold(
      (failure) => emit(state.copyWith(isLoading: false, errorMessage: failure.message)),
      (list) {
        final sorted = List<Message>.from(list)
          ..sort((a, b) {
            final cmp = a.createdAt.compareTo(b.createdAt);
            if (cmp != 0) return cmp;
            return a.id.compareTo(b.id);
          });

        // Resolve seen statuses for outgoing messages based on contact activity
        DateTime? effectiveSeen = contactLastSeenAt;
        for (final m in sorted) {
          if (!m.isOutgoing && !m.isPrivateNote && !m.isActivity) {
            if (effectiveSeen == null || m.createdAt.isAfter(effectiveSeen)) {
              effectiveSeen = m.createdAt;
            }
          }
        }

        final resolved = sorted.map((m) {
          if (m.isOutgoing && !m.isFailed && !m.isPrivateNote) {
            if (effectiveSeen != null &&
                (m.createdAt.isBefore(effectiveSeen) || m.createdAt.isAtSameMomentAs(effectiveSeen))) {
              return m.copyWith(status: 'read');
            }
          }
          return m;
        }).toList();

        emit(state.copyWith(
          messages: resolved,
          isLoading: false,
          errorMessage: null,
          hasMoreMessages: list.isNotEmpty,
        ));
      },
    );
  }

  Future<void> loadPreviousMessages() async {
    if (state.isLoadingOlder || !state.hasMoreMessages || state.isLoading || state.messages.isEmpty) {
      return;
    }

    final validMessages = state.messages.where((m) => m.id > 0);
    if (validMessages.isEmpty) return;
    final oldestMessageId = validMessages.first.id;

    emit(state.copyWith(isLoadingOlder: true));

    final result = await repo.getMessages(conversationId, beforeId: oldestMessageId);
    result.fold(
      (failure) => emit(state.copyWith(isLoadingOlder: false)),
      (olderList) {
        if (olderList.isEmpty) {
          emit(state.copyWith(
            isLoadingOlder: false,
            hasMoreMessages: false,
          ));
          return;
        }

        final existingIds = state.messages.map((m) => m.id).toSet();
        final filteredOlder = olderList.where((m) => !existingIds.contains(m.id)).toList();

        if (filteredOlder.isEmpty) {
          emit(state.copyWith(
            isLoadingOlder: false,
            hasMoreMessages: false,
          ));
          return;
        }

        final combined = [...filteredOlder, ...state.messages]
          ..sort((a, b) {
            final cmp = a.createdAt.compareTo(b.createdAt);
            if (cmp != 0) return cmp;
            return a.id.compareTo(b.id);
          });

        emit(state.copyWith(
          messages: combined,
          isLoadingOlder: false,
          hasMoreMessages: olderList.length >= 15,
        ));
      },
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
        // Prominently add failed message so user sees exactly what failed and can retry
        final failedMsg = Message(
          id: -DateTime.now().millisecondsSinceEpoch,
          content: content,
          conversationId: conversationId,
          messageType: 1, // outgoing
          private: isPrivate,
          status: 'failed',
          createdAt: DateTime.now(),
          contentAttributes: {
            'external_error': failure.message,
            'delivery_status': 'failed',
          },
        );
        emit(state.copyWith(
          messages: [...state.messages, failedMsg],
          isSending: false,
          errorMessage: failure.message,
        ));
        return false;
      },
      (sent) {
        SoundService().playOutgoingSound();
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

  Future<List<MessageTemplate>> fetchTemplates(int inboxId) async {
    final result = await repo.fetchInboxTemplates(inboxId);
    return result.getOrElse(() => []);
  }

  Future<bool> sendTemplate({
    required String templateName,
    required String category,
    required String language,
    required String content,
    Map<String, dynamic>? processedParams,
  }) async {
    emit(state.copyWith(isSending: true));
    final result = await repo.sendTemplateMessage(
      conversationId: conversationId,
      templateName: templateName,
      category: category,
      language: language,
      content: content,
      processedParams: processedParams,
    );

    return result.fold(
      (failure) {
        // Prominently add failed template message so user sees retry badge and error
        final failedMsg = Message(
          id: -DateTime.now().millisecondsSinceEpoch,
          content: content,
          conversationId: conversationId,
          messageType: 1, // outgoing
          private: false,
          status: 'failed',
          createdAt: DateTime.now(),
          contentAttributes: {
            'external_error': failure.message,
            'delivery_status': 'failed',
            'template_params': {
              'name': templateName,
              'category': category,
              'language': language,
            },
          },
          additionalAttributes: {
            'template_name': templateName,
          },
        );
        emit(state.copyWith(
          messages: [...state.messages, failedMsg],
          isSending: false,
          errorMessage: failure.message,
        ));
        return false;
      },
      (sent) {
        SoundService().playOutgoingSound();
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

  Future<void> retryMessage(Message message) async {
    // Remove the failed placeholder from the UI
    final updatedList = state.messages.where((m) => m.id != message.id).toList();
    emit(state.copyWith(messages: updatedList));

    if (message.isTemplate && message.templateName != null) {
      final tpl = MessageTemplateRegistry.find(message.templateName);
      await sendTemplate(
        templateName: message.templateName!,
        category: tpl?.category ?? 'MARKETING',
        language: tpl?.language ?? 'ar_EG',
        content: message.content ?? tpl?.body ?? '',
      );
    } else {
      await sendMessage(
        content: message.content ?? '',
        isPrivate: message.isPrivateNote,
      );
    }
  }

  Future<void> toggleStatus(String newStatus, {String? snoozedUntil}) async {
    final result = await repo.toggleStatus(conversationId, newStatus, snoozedUntil: snoozedUntil);
    result.fold((_) {}, (_) {
      emit(state.copyWith(status: newStatus));
    });
  }

  Future<bool> muteConversation() async {
    final result = await repo.muteConversation(conversationId);
    return result.isRight();
  }

  Future<bool> unmuteConversation() async {
    final result = await repo.unmuteConversation(conversationId);
    return result.isRight();
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
    _reconnectSub?.cancel();
    return super.close();
  }
}
