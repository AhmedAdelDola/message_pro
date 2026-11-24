import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:message_pro/data/models/contact.dart';
import '../../core/error/failures.dart';
import '../../core/network/websocket_client.dart';
import '../../core/services/sound_service.dart';
import '../../core/services/performance_service.dart';
import '../../data/models/message.dart';
import '../../data/models/message_template.dart';
import '../../data/models/message_template_registry.dart';
import '../../data/repositories/conversation_repository.dart';
import 'chat_state.dart';
import 'handlers/chat_realtime_handler.dart';

class ChatCubit extends Cubit<ChatState> {
  final int conversationId;
  final IConversationRepository repo;
  final ActionCableClient ws;
  final int? accountId;
  final Stopwatch renderStopwatch = Stopwatch();
  DateTime? contactLastSeenAt;
  late final ChatRealtimeHandler _realtimeHandler;

  static List<Message> _initCachedMessages(
    IConversationRepository repo,
    int id,
  ) {
    if (repo is ConversationRepository) {
      return repo.getCachedMessages(id) ?? const [];
    }
    return const [];
  }

  ChatCubit({
    required this.conversationId,
    this.accountId,
    required this.repo,
    required this.ws,
    this.contactLastSeenAt,
  }) : super(() {
         final cached = _initCachedMessages(repo, conversationId);
         return ChatState(
           conversationId: conversationId,
           messages: cached,
           isLoading: cached.isEmpty && conversationId > 0,
         );
       }()) {
    _realtimeHandler = ChatRealtimeHandler(
      ws: ws,
      conversationId: conversationId,
      accountId: accountId,
    );

    if (conversationId > 0) {
      _initAndLoadMessages();
      _setupRealtime();
      repo.markAsRead(conversationId);
    }
  }

  Future<void> _initAndLoadMessages() async {
    if (state.messages.isEmpty && repo is ConversationRepository) {
      final diskCached = await (repo as ConversationRepository).getLocalCachedMessages(conversationId);
      if (diskCached.isNotEmpty && state.messages.isEmpty && !isClosed) {
        emit(state.copyWith(messages: diskCached, isLoading: false));
      }
    }
    await loadMessages();
    if (!isClosed && state.cannedResponses.isEmpty) {
      loadCannedResponses();
    }
  }

  @override
  void emit(ChatState state) {
    if (!isClosed) {
      super.emit(state);
    }
  }

  void _setupRealtime() {
    _realtimeHandler.startListening(
      onMessageCreated: _handleRealtimeMessageCreated,
      onMessageUpdated: _handleRealtimeMessageUpdated,
      onCollaboratorsChanged: () => loadCollaborators(),
      onContactLastSeenAt: _handleContactLastSeenAt,
      onTypingOn: (name) =>
          emit(state.copyWith(typingUsers: {...state.typingUsers, name})),
      onTypingOff: (name) {
        final updated = Set<String>.from(state.typingUsers)..remove(name);
        emit(state.copyWith(typingUsers: updated));
      },
      onReconnected: () => loadMessages(),
    );
  }

  void _handleRealtimeMessageCreated(
    Message msg,
    Map<String, dynamic> payload,
  ) {
    if (state.messages.any((m) => m.id == msg.id)) return;

    renderStopwatch.reset();
    renderStopwatch.start();

    var currentMessages = List<Message>.from(state.messages);
    final echoId =
        payload['echo_id'] ?? payload['content_attributes']?['echo_id'];
    final optimisticIndex = currentMessages.indexWhere((m) {
      if (m.id >= 0) return false;
      if (echoId != null && m.id.toString() == echoId.toString()) return true;
      if (m.isOutgoing == msg.isOutgoing &&
          m.isPrivateNote == msg.isPrivateNote &&
          (m.content?.trim() ?? '') == (msg.content?.trim() ?? '')) {
        return true;
      }
      return false;
    });

    if (optimisticIndex != -1) {
      currentMessages[optimisticIndex] = msg;
    } else {
      currentMessages.add(msg);
    }

    final seenIds = <int>{};
    currentMessages = currentMessages.where((m) {
      if (m.id < 0) return true;
      return seenIds.add(m.id);
    }).toList();

    if (!msg.isOutgoing && !msg.isPrivateNote && !msg.isActivity) {
      SoundService().playIncomingSound();
      contactLastSeenAt = msg.createdAt;
      currentMessages = currentMessages.map((m) {
        if (m.isOutgoing &&
            !m.isFailed &&
            !m.isPrivateNote &&
            m.status != 'read') {
          return m.copyWith(status: 'read');
        }
        return m;
      }).toList();
    }
    emit(state.copyWith(messages: currentMessages));
    repo.markAsRead(conversationId);
  }

  void _handleRealtimeMessageUpdated(Message updatedMsg) {
    final index = state.messages.indexWhere((m) => m.id == updatedMsg.id);
    if (index != -1) {
      final updatedList = List<Message>.from(state.messages);
      updatedList[index] = updatedMsg;
      emit(state.copyWith(messages: updatedList));
    }
  }

  void _handleContactLastSeenAt(DateTime seenDt) {
    contactLastSeenAt = seenDt;
    final updatedList = state.messages.map((m) {
      if (m.isOutgoing &&
          !m.isFailed &&
          (m.createdAt.isBefore(seenDt) ||
              m.createdAt.isAtSameMomentAs(seenDt))) {
        return m.copyWith(status: 'read');
      }
      return m;
    }).toList();
    emit(state.copyWith(messages: updatedList));
  }

  Future<void> loadMessages() async {
    if (conversationId <= 0) {
      emit(state.copyWith(isLoading: false));
      return;
    }
    final hasCached = state.messages.isNotEmpty;
    if (!hasCached) {
      emit(
        state.copyWith(
          isLoading: true,
          hasMoreMessages: true,
          errorMessage: null,
        ),
      );
    }
    final fetchStopwatch = Stopwatch()..start();
    await PerformanceService.traceAsync(
      'load_chat_messages',
      () async {
        final result = await repo.getMessages(conversationId);
        fetchStopwatch.stop();
        final serverMs = fetchStopwatch.elapsedMilliseconds;
        if (isClosed) return;
        renderStopwatch.reset();
        renderStopwatch.start();
        result.fold(
          (failure) => emit(
            state.copyWith(isLoading: false, errorMessage: failure.message),
          ),
          (list) {
            if (isClosed) return;
            final sorted = List<Message>.from(list)
              ..sort((a, b) {
                final cmp = a.createdAt.compareTo(b.createdAt);
                if (cmp != 0) return cmp;
                return a.id.compareTo(b.id);
              });

            DateTime? effectiveSeen = contactLastSeenAt;
            for (final m in sorted) {
              if (!m.isOutgoing && !m.isPrivateNote && !m.isActivity) {
                if (effectiveSeen == null ||
                    m.createdAt.isAfter(effectiveSeen)) {
                  effectiveSeen = m.createdAt;
                }
              }
            }

            final resolved = sorted.map((m) {
              if (m.isOutgoing && !m.isFailed && !m.isPrivateNote) {
                if (effectiveSeen != null &&
                    (m.createdAt.isBefore(effectiveSeen) ||
                        m.createdAt.isAtSameMomentAs(effectiveSeen))) {
                  return m.copyWith(status: 'read');
                }
              }
              return m;
            }).toList();

            emit(
              state.copyWith(
                messages: resolved,
                isLoading: false,
                errorMessage: null,
                hasMoreMessages: list.isNotEmpty,
              ),
            );
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (renderStopwatch.isRunning) {
                renderStopwatch.stop();
                final renderMs = renderStopwatch.elapsedMilliseconds;
                debugPrint(
                  '════════════════════════════════════════════════════════\n'
                  '📊 [CHAT PERF METRICS] محادثة #$conversationId:\n'
                  '   🌐 وقت استجابة السيرفر والشبكة: ${serverMs}ms\n'
                  '   🎨 وقت رسم الرسائل على الشاشة: ${renderMs}ms\n'
                  '   ⏱️ إجمالي الوقت حتى الظهور: ${serverMs + renderMs}ms\n'
                  '════════════════════════════════════════════════════════',
                );
              }
            });
          },
        );
      },
      attributes: {'conversation_id': conversationId.toString()},
      onResult: (trace, _) {
        trace.setMetric('messages_count', state.messages.length);
      },
    );
  }

  Future<void> loadPreviousMessages() async {
    if (state.isLoadingOlder ||
        !state.hasMoreMessages ||
        state.isLoading ||
        state.messages.isEmpty) {
      return;
    }

    final validMessages = state.messages.where((m) => m.id > 0);
    if (validMessages.isEmpty) return;
    final oldestMessageId = validMessages
        .map((m) => m.id)
        .reduce((min, id) => id < min ? id : min);

    emit(state.copyWith(isLoadingOlder: true));

    await PerformanceService.traceAsync(
      'load_previous_chat_messages',
      () async {
        final result = await repo.getMessages(
          conversationId,
          beforeId: oldestMessageId,
        );
        if (isClosed) return;
        result.fold((failure) => emit(state.copyWith(isLoadingOlder: false)), (
          olderList,
        ) {
          if (olderList.isEmpty) {
            emit(state.copyWith(isLoadingOlder: false, hasMoreMessages: false));
            return;
          }

          final existingIds = state.messages.map((m) => m.id).toSet();
          final filteredOlder = olderList
              .where((m) => !existingIds.contains(m.id))
              .toList();

          if (filteredOlder.isEmpty) {
            emit(state.copyWith(isLoadingOlder: false, hasMoreMessages: false));
            return;
          }

          final combined = [...filteredOlder, ...state.messages]
            ..sort((a, b) {
              final cmp = a.createdAt.compareTo(b.createdAt);
              if (cmp != 0) return cmp;
              return a.id.compareTo(b.id);
            });

          emit(
            state.copyWith(
              messages: combined,
              isLoadingOlder: false,
              hasMoreMessages: olderList.length >= 15,
            ),
          );
        });
      },
      attributes: {
        'conversation_id': conversationId.toString(),
        'before_id': oldestMessageId.toString(),
      },
      onResult: (trace, _) {
        trace.setMetric('messages_count', state.messages.length);
      },
    );
  }

  Future<bool> loadTargetMessage(int messageId) async {
    if (state.messages.any((m) => m.id == messageId)) {
      return true;
    }

    final result = await repo.getMessages(
      conversationId,
      afterId: messageId,
      beforeId: messageId + 1,
    );

    return result.fold((failure) => false, (fetched) {
      if (fetched.isEmpty) return false;

      final existingIds = state.messages.map((m) => m.id).toSet();
      final newItems = fetched
          .where((m) => !existingIds.contains(m.id))
          .toList();

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
    });
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
    final tempId = -DateTime.now().millisecondsSinceEpoch;
    final optimisticMsg = Message(
      id: tempId,
      content: content,
      conversationId: conversationId,
      messageType: 1, // outgoing
      private: isPrivate,
      status: 'sending',
      createdAt: DateTime.now(),
      contentAttributes: inReplyToId != null
          ? {'in_reply_to': inReplyToId}
          : const {},
    );

    emit(
      state.copyWith(
        messages: [...state.messages, optimisticMsg],
        isSending: true,
        errorMessage: null,
      ),
    );

    final result = await PerformanceService.traceAsync(
      'send_message',
      () => repo.sendMessage(
        conversationId: conversationId,
        content: content,
        isPrivate: isPrivate,
        attachmentPaths: attachmentPaths,
        inReplyToId: inReplyToId,
        echoId: tempId.toString(),
      ),
      attributes: {
        'has_attachments': (attachmentPaths?.isNotEmpty == true).toString(),
        'is_private': isPrivate.toString(),
      },
    );

    return result.fold(
      (failure) {
        final failedMsg = optimisticMsg.copyWith(
          status: 'failed',
          contentAttributes: {
            'external_error': failure.message,
            'delivery_status': 'failed',
            if (inReplyToId != null) 'in_reply_to': inReplyToId,
            'echo_id': tempId.toString(),
          },
        );
        final updatedList = state.messages
            .map((m) => m.id == tempId ? failedMsg : m)
            .toList();
        emit(
          state.copyWith(
            messages: updatedList,
            isSending: false,
            errorMessage: failure.message,
          ),
        );
        return false;
      },
      (sent) {
        SoundService().playOutgoingSound();
        final seenIds = <int>{};
        final updatedList = <Message>[];
        bool sentPlaced = false;

        for (final m in state.messages) {
          if (m.id == tempId) {
            if (!sentPlaced && seenIds.add(sent.id)) {
              updatedList.add(sent);
              sentPlaced = true;
            }
          } else if (m.id == sent.id) {
            if (!sentPlaced && seenIds.add(sent.id)) {
              updatedList.add(sent);
              sentPlaced = true;
            }
          } else {
            if (m.id < 0 || seenIds.add(m.id)) {
              updatedList.add(m);
            }
          }
        }

        if (!sentPlaced && seenIds.add(sent.id)) {
          updatedList.add(sent);
        }

        emit(state.copyWith(messages: updatedList, isSending: false));
        return true;
      },
    );
  }

  Future<List<MessageTemplate>> fetchTemplates([int? inboxId]) async {
    final convResult = await repo.fetchConversationTemplates(conversationId);
    if (convResult.isRight() && convResult.getOrElse(() => []).isNotEmpty) {
      return convResult.getOrElse(() => []);
    }
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

  Future<Either<Failure, Contact>> fetchCollaborators() async {
    return await repo.getCollaborators(conversationId);
  }

  Future<Either<Failure, Contact>> addCollaboratorAction(int userId) async {
    return await repo.addCollaborator(conversationId, userId);
  }

  Future<Either<Failure, Contact>> removeCollaboratorAction(int userId) async {
    return await repo.removeCollaborator(conversationId, userId);
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
        final failedMsg = Message(
          id: -DateTime.now().millisecondsSinceEpoch,
          content: content,
          conversationId: conversationId,
          messageType: 1,
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
          additionalAttributes: {'template_name': templateName},
        );
        emit(
          state.copyWith(
            messages: [...state.messages, failedMsg],
            isSending: false,
            errorMessage: failure.message,
          ),
        );
        return false;
      },
      (sent) {
        SoundService().playOutgoingSound();
        if (!state.messages.any((m) => m.id == sent.id)) {
          emit(
            state.copyWith(
              messages: [...state.messages, sent],
              isSending: false,
            ),
          );
        } else {
          emit(state.copyWith(isSending: false));
        }
        return true;
      },
    );
  }

  Future<void> retryMessage(Message message) async {
    final updatedList = state.messages
        .where((m) => m.id != message.id)
        .toList();
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
    final result = await repo.toggleStatus(
      conversationId,
      newStatus,
      snoozedUntil: snoozedUntil,
    );
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
    return result.fold((failure) => failure.message, (updatedMsg) {
      final index = state.messages.indexWhere((m) => m.id == messageId);
      if (index != -1) {
        final updatedList = List<Message>.from(state.messages);
        updatedList[index] = updatedMsg;
        emit(state.copyWith(messages: updatedList));
      }
      return null;
    });
  }

  Future<String?> deleteMessage(int messageId, {bool everyone = true}) async {
    final result = await repo.deleteMessage(
      conversationId: conversationId,
      messageId: messageId,
      everyone: everyone,
    );
    return result.fold((failure) => failure.message, (updatedMsg) {
      final index = state.messages.indexWhere((m) => m.id == messageId);
      if (index != -1) {
        final updatedList = List<Message>.from(state.messages);
        updatedList[index] = updatedMsg;
        emit(state.copyWith(messages: updatedList));
      }
      return null;
    });
  }

  Future<String?> sendReaction(int messageId, String emoji) async {
    final result = await repo.sendReaction(
      conversationId: conversationId,
      messageId: messageId,
      emoji: emoji,
    );
    return result.fold((failure) => failure.message, (updatedMsg) {
      final index = state.messages.indexWhere((m) => m.id == messageId);
      if (index != -1) {
        final updatedList = List<Message>.from(state.messages);
        updatedList[index] = updatedMsg;
        emit(state.copyWith(messages: updatedList));
      }
      return null;
    });
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
    _realtimeHandler.dispose();
    return super.close();
  }
}
