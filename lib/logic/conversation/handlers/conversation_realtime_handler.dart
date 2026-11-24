import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../core/network/websocket_client.dart';
import '../../../core/services/sound_service.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../../../data/models/conversation.dart';
import '../../../data/models/message.dart';

/// Handles WebSocket real-time events and reconnect triggers for conversations.
/// Follows Single Responsibility Principle by decoupling real-time parsing from Cubit state management.
class ConversationRealtimeHandler {
  final ActionCableClient ws;
  final SecureStorageService storage;
  int? activeAccountId;

  StreamSubscription<RealtimeEvent>? _eventSub;
  StreamSubscription<void>? _reconnectSub;

  ConversationRealtimeHandler({
    required this.ws,
    required this.storage,
    this.activeAccountId,
  });

  /// Verifies whether an incoming real-time payload belongs to the currently active workspace.
  bool isEventForCurrentAccount(Map<String, dynamic> payload, [int? parsedAccountId]) {
    final activeId = activeAccountId ?? storage.activeAccountId;
    if (activeId == null || activeId <= 0) return true;

    final targetAccId = parsedAccountId ??
        payload['account_id'] ??
        payload['account']?['id'] ??
        payload['conversation']?['account_id'] ??
        payload['message']?['account_id'];

    if (targetAccId == null) return true;
    final parsed = targetAccId is int ? targetAccId : int.tryParse(targetAccId.toString());
    return parsed == null || parsed <= 0 || parsed == activeId;
  }

  /// Begins listening to ActionCable real-time events and reconnect notifications.
  void startListening({
    required void Function(Conversation conv) onConversationCreated,
    required void Function(Conversation conv) onConversationUpdated,
    required void Function(int conversationId) onConversationRead,
    required void Function(int conversationId, Message? message, Map<String, dynamic> rawPayload) onMessageCreated,
    required void Function() onReconnected,
  }) {
    _eventSub?.cancel();
    _reconnectSub?.cancel();

    _reconnectSub = ws.onReconnected.listen((_) {
      onReconnected();
    });

    _eventSub = ws.events.listen((event) {
      final name = event.event;
      final payload = event.data;

      // Guard against cross-workspace conversation bleed (fast in-memory check)
      if (!isEventForCurrentAccount(payload)) {
        return;
      }

      switch (name) {
        case 'conversation.created':
          _handleConversationCreated(payload, onConversationCreated);
          break;

        case 'conversation.updated':
        case 'conversation.status_changed':
        case 'assignee.changed':
          _handleConversationUpdated(payload, onConversationUpdated);
          break;

        case 'conversation.read':
          _handleConversationRead(payload, onConversationRead);
          break;

        case 'message.created':
          _handleMessageCreated(payload, onMessageCreated);
          break;

        default:
          break;
      }
    });
  }

  void _handleConversationCreated(
    Map<String, dynamic> payload,
    void Function(Conversation conv) onConversationCreated,
  ) {
    try {
      final conv = Conversation.fromJson(Map<String, dynamic>.from(payload));
      if (!isEventForCurrentAccount(payload, conv.accountId)) return;
      if (conv.id > 0) {
        onConversationCreated(conv);
      }
    } catch (e) {
      debugPrint('[ConversationRealtimeHandler] Error parsing conversation.created: $e');
    }
  }

  void _handleConversationUpdated(
    Map<String, dynamic> payload,
    void Function(Conversation conv) onConversationUpdated,
  ) {
    try {
      final conv = Conversation.fromJson(Map<String, dynamic>.from(payload));
      if (!isEventForCurrentAccount(payload, conv.accountId)) return;
      if (conv.id > 0) {
        onConversationUpdated(conv);
      }
    } catch (e) {
      debugPrint('[ConversationRealtimeHandler] Error parsing conversation.updated: $e');
    }
  }

  void _handleConversationRead(
    Map<String, dynamic> payload,
    void Function(int conversationId) onConversationRead,
  ) {
    final convId = payload['id'] ?? payload['conversation_id'];
    if (convId != null) {
      final id = convId is int ? convId : int.tryParse(convId.toString());
      if (id != null && id > 0) {
        onConversationRead(id);
      }
    }
  }

  void _handleMessageCreated(
    Map<String, dynamic> payload,
    void Function(int conversationId, Message? message, Map<String, dynamic> rawPayload) onMessageCreated,
  ) {
    // Play sound notification for incoming messages from customer
    if (payload['message_type'] == 0) {
      SoundService().playIncomingSound();
    }

    final convId = payload['conversation_id'];
    if (convId != null) {
      final id = convId is int ? convId : int.tryParse(convId.toString());
      if (id != null && id > 0) {
        Message? newMsg;
        try {
          newMsg = Message.fromJson(Map<String, dynamic>.from(payload));
        } catch (_) {}
        onMessageCreated(id, newMsg, payload);
      }
    }
  }

  void dispose() {
    _eventSub?.cancel();
    _reconnectSub?.cancel();
    _eventSub = null;
    _reconnectSub = null;
  }
}
