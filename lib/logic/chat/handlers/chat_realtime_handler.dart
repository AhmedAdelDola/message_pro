import 'dart:async';
import 'package:message_pro/core/network/websocket_client.dart';
import 'package:message_pro/data/models/message.dart';

/// Handles WebSocket realtime events specifically for an active chat conversation.
/// Decouples event subscription and payload parsing from [ChatCubit].
class ChatRealtimeHandler {
  final ActionCableClient ws;
  final int conversationId;
  final int? accountId;
  StreamSubscription<RealtimeEvent>? _eventSub;
  StreamSubscription<void>? _reconnectSub;

  ChatRealtimeHandler({
    required this.ws,
    required this.conversationId,
    this.accountId,
  });

  /// Guards against events belonging to other workspaces or other conversations.
  bool isEventForThisChat(Map<String, dynamic> payload) {
    if (accountId != null && accountId! > 0) {
      final eventAccIdRaw = payload['account_id'] ??
          payload['account']?['id'] ??
          payload['conversation']?['account_id'] ??
          payload['message']?['account_id'];
      if (eventAccIdRaw != null) {
        final parsedAcc = eventAccIdRaw is int ? eventAccIdRaw : int.tryParse(eventAccIdRaw.toString());
        if (parsedAcc != null && parsedAcc > 0 && parsedAcc != accountId) {
          return false;
        }
      }
    }

    final rawConvId = payload['conversation_id'] ??
        payload['id'] ??
        payload['conversation']?['id'];
    if (rawConvId != null) {
      final parsedConvId = rawConvId is int ? rawConvId : int.tryParse(rawConvId.toString());
      if (parsedConvId != null && parsedConvId > 0 && parsedConvId != conversationId) {
        return false;
      }
    }

    return true;
  }

  void startListening({
    required void Function(Message msg, Map<String, dynamic> rawPayload) onMessageCreated,
    required void Function(Message updatedMsg) onMessageUpdated,
    required void Function() onCollaboratorsChanged,
    required void Function(DateTime seenDt) onContactLastSeenAt,
    required void Function(String userName) onTypingOn,
    required void Function(String userName) onTypingOff,
    required void Function() onReconnected,
  }) {
    _reconnectSub = ws.onReconnected.listen((_) => onReconnected());

    _eventSub = ws.events.listen((event) {
      final name = event.event;
      final payload = event.data;

      if (!isEventForThisChat(payload)) {
        return;
      }

      if (name == 'message.created') {
        final rawConvId = payload['conversation_id'] ?? payload['conversation']?['id'];
        final convId = rawConvId is int ? rawConvId : int.tryParse(rawConvId?.toString() ?? '');
        if (convId != null && convId == conversationId) {
          final msg = Message.fromJson(payload);
          onMessageCreated(msg, payload);
        }
      } else if (name == 'message.updated' || name == 'message.reactions_updated') {
        final rawConvId = payload['conversation_id'] ?? payload['conversation']?['id'];
        final convId = rawConvId is int ? rawConvId : int.tryParse(rawConvId?.toString() ?? '');
        if (convId != null && convId == conversationId) {
          final msgData = payload['message'] is Map ? payload['message'] : payload;
          final updatedMsg = Message.fromJson(Map<String, dynamic>.from(msgData));
          onMessageUpdated(updatedMsg);
        }
      } else if (name == 'contact.collaborators_changed') {
        onCollaboratorsChanged();
      } else if (name == 'conversation.contact_last_seen_at' || name == 'conversation.read') {
        final rawConvId = payload['id'] ?? payload['conversation_id'];
        final convId = rawConvId is int ? rawConvId : int.tryParse(rawConvId?.toString() ?? '');
        if (convId != null && convId == conversationId) {
          final lastSeen = payload['contact_last_seen_at'];
          if (lastSeen is num && lastSeen > 0) {
            final seenDt = DateTime.fromMillisecondsSinceEpoch(
              lastSeen > 1e11 ? lastSeen.toInt() : (lastSeen * 1000).toInt(),
            );
            onContactLastSeenAt(seenDt);
          }
        }
      } else if (name == 'conversation.typing_on') {
        final rawConvId = payload['conversation_id'];
        final convId = rawConvId is int ? rawConvId : int.tryParse(rawConvId?.toString() ?? '');
        if (convId != null && convId == conversationId) {
          final user = payload['user'];
          final name = user is Map ? user['name']?.toString() ?? 'User' : 'Customer';
          onTypingOn(name);
        }
      } else if (name == 'conversation.typing_off') {
        final rawConvId = payload['conversation_id'];
        final convId = rawConvId is int ? rawConvId : int.tryParse(rawConvId?.toString() ?? '');
        if (convId != null && convId == conversationId) {
          final user = payload['user'];
          final name = user is Map ? user['name']?.toString() ?? 'User' : 'Customer';
          onTypingOff(name);
        }
      }
    });
  }

  void dispose() {
    _eventSub?.cancel();
    _reconnectSub?.cancel();
  }
}
