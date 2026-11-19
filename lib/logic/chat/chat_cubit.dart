import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:message_pro/data/models/contact.dart';
import '../../core/error/failures.dart';
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

  static List<Message> _initCachedMessages(IConversationRepository repo, int id) {
    if (repo is ConversationRepository) {
      return repo.getCachedMessages(id) ?? const [];
    }
    return const [];
  }

  ChatCubit({
    required this.conversationId,
    required this.repo,
    required this.ws,
    this.contactLastSeenAt,
  }) : super(() {
          final cached = _initCachedMessages(repo, conversationId);
          return ChatState(
            conversationId: conversationId,
            messages: cached,
            isLoading: cached.isEmpty,
          );
        }()) {
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
      } else if (name == 'message.updated' || name == 'message.reactions_updated') {
        final convId = payload['conversation_id'];
        if (convId != null && convId == conversationId) {
          final msgData = payload['message'] is Map ? payload['message'] : payload;
          final updatedMsg = Message.fromJson(Map<String, dynamic>.from(msgData));
          final index = state.messages.indexWhere((m) => m.id == updatedMsg.id);
          if (index != -1) {
            final updatedList = List<Message>.from(state.messages);
            updatedList[index] = updatedMsg;
            emit(state.copyWith(messages: updatedList));
          }
        }
      } else if (name == 'contact.collaborators_changed') {
        loadCollaborators();
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
    final hasCached = state.messages.isNotEmpty;
    if (!hasCached) {
      emit(state.copyWith(isLoading: true, hasMoreMessages: true, errorMessage: null));
    }
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
    final oldestMessageId = validMessages.map((m) => m.id).reduce((min, id) => id < min ? id : min);

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

  /// Loads a specific target message by ID if not already present in the list,
  /// using the after=id and before=id+1 parameters per the backend specification.
  Future<bool> loadTargetMessage(int messageId) async {
    if (state.messages.any((m) => m.id == messageId)) {
      return true;
    }

    final result = await repo.getMessages(
      conversationId,
      afterId: messageId,
      beforeId: messageId + 1,
    );

    return result.fold(
      (failure) => false,
      (fetched) {
        if (fetched.isEmpty) return false;

        final existingIds = state.messages.map((m) => m.id).toSet();
        final newItems = fetched.where((m) => !existingIds.contains(m.id)).toList();

        if (newItems.isNotEmpty) {
          final updated = [...state.messages, ...newItems]
            ..sort((a, b) {
              final cmp = a.createdAt.compareTo(b.createdAt);
              if (cmp != 0) return cmp;
              return a.id.compareTo(b.id);
            });
          emit(state.copyWith(messages: updated));
        }

        return state.messages.any((m) => m.id == messageId);
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
    int? inReplyToId,
  }) async {
    emit(state.copyWith(isSending: true));
    final result = await repo.sendMessage(
      conversationId: conversationId,
      content: content,
      isPrivate: isPrivate,
      attachmentPaths: attachmentPaths,
      inReplyToId: inReplyToId,
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

  Future<List<MessageTemplate>> fetchTemplates([int? inboxId]) async {
    // 1. First try new route: GET conversations/:conversationId/message_templates
    final convResult = await repo.fetchConversationTemplates(conversationId);
    if (convResult.isRight() && convResult.getOrElse(() => []).isNotEmpty) {
      return convResult.getOrElse(() => []);
    }
    // 2. Fallback to inbox route
    if (inboxId != null) {
      final inboxResult = await repo.fetchInboxTemplates(inboxId);
      return inboxResult.getOrElse(() => []);
    }
    return [];
  }

  Future<Contact?> loadCollaborators() async {
    final result = await repo.getCollaborators(conversationId);
    return result.fold((_) => null, (contact) => contact);
  }

  Future<bool> addCollaborator(int userId) async {
    final result = await repo.addCollaborator(conversationId, userId);
    return result.isRight();
  }

  Future<bool> removeCollaborator(int userId) async {
    final result = await repo.removeCollaborator(conversationId, userId);
    return result.isRight();
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

  Future<bool> toggleStatus(String newStatus, {String? snoozedUntil}) async {
    final result = await repo.toggleStatus(conversationId, newStatus, snoozedUntil: snoozedUntil);
    return result.fold(
      (failure) {
        emit(state.copyWith(errorMessage: failure.message));
        return false;
      },
      (_) {
        emit(state.copyWith(status: newStatus));
        return true;
      },
    );
  }

  Future<bool> muteConversation() async {
    final result = await repo.muteConversation(conversationId);
    return result.isRight();
  }

  Future<bool> unmuteConversation() async {
    final result = await repo.unmuteConversation(conversationId);
    return result.isRight();
  }

  Future<void> assignAgent(int? agentId, {String? assigneeType}) async {
    await repo.assignAgent(conversationId, agentId, assigneeType: assigneeType);
  }

  Future<void> assignTeam(int? teamId) async {
    await repo.assignTeam(conversationId, teamId);
  }

  Future<void> updateLifecycleStage(int stageId) async {
    await repo.updateLifecycleStage(conversationId, stageId);
  }

  Future<String?> editMessage(int messageId, String newContent) async {
    final result = await repo.editMessage(
      conversationId: conversationId,
      messageId: messageId,
      content: newContent,
    );
    return result.fold(
      (failure) => failure.message,
      (updatedMsg) {
        final index = state.messages.indexWhere((m) => m.id == messageId);
        if (index != -1) {
          final updatedList = List<Message>.from(state.messages);
          updatedList[index] = updatedMsg;
          emit(state.copyWith(messages: updatedList));
        }
        return null;
      },
    );
  }

  Future<String?> sendReaction(int messageId, String emoji) async {
    final result = await repo.sendReaction(
      conversationId: conversationId,
      messageId: messageId,
      emoji: emoji,
    );
    return result.fold(
      (failure) => failure.message,
      (updatedMsg) {
        final index = state.messages.indexWhere((m) => m.id == messageId);
        if (index != -1) {
          final updatedList = List<Message>.from(state.messages);
          updatedList[index] = updatedMsg;
          emit(state.copyWith(messages: updatedList));
        }
        return null;
      },
    );
  }

  Future<Either<Failure, List<ReactionParticipant>>> getReactions(
    int messageId, {
    Map<String, dynamic>? contentAttributes,
  }) async {
    return await repo.getReactions(
      conversationId: conversationId,
      messageId: messageId,
      contentAttributes: contentAttributes,
    );
  }

  @override
  Future<void> close() {
    _eventSub?.cancel();
    _reconnectSub?.cancel();
    return super.close();
  }
}
