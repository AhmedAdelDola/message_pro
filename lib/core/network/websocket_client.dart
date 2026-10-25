import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../config/app_config.dart';
import '../storage/secure_storage_service.dart';

class RealtimeEvent {
  final String event;
  final Map<String, dynamic> data;

  RealtimeEvent({required this.event, required this.data});
}

class ActionCableClient {
  static final ActionCableClient _instance = ActionCableClient._internal();
  factory ActionCableClient() => _instance;
  ActionCableClient._internal();

  WebSocketChannel? _channel;
  Timer? _presenceTimer;
  Timer? _reconnectTimer;
  bool _isConnected = false;
  bool _isConnecting = false;

  final _eventController = StreamController<RealtimeEvent>.broadcast();
  Stream<RealtimeEvent> get events => _eventController.stream;

  final SecureStorageService _storage = SecureStorageService();

  Future<void> connect({
    required String pubSubToken,
    required int accountId,
    required int userId,
    String? customWsUrl,
  }) async {
    if (_isConnecting || _isConnected) return;
    _isConnecting = true;

    try {
      String wsUrl = customWsUrl ?? AppConfig.defaultWebSocketUrl;
      final savedBase = await _storage.getBaseUrl();
      if (customWsUrl == null && savedBase.isNotEmpty) {
        final host = savedBase.replaceFirst(RegExp(r'^https?:\/\/'), '').replaceAll(RegExp(r'\/+$'), '');
        final scheme = savedBase.startsWith('http://') ? 'ws://' : 'wss://';
        wsUrl = '$scheme$host/cable';
      }

      debugPrint('Connecting to WebSocket: $wsUrl');
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

      _channel!.stream.listen(
        (dynamic rawMessage) {
          _handleMessage(rawMessage, pubSubToken, accountId, userId);
        },
        onDone: () {
          _handleDisconnect(pubSubToken, accountId, userId);
        },
        onError: (error) {
          debugPrint('WebSocket error: $error');
          _handleDisconnect(pubSubToken, accountId, userId);
        },
      );

      _isConnected = true;
      _isConnecting = false;

      // Subscribe to RoomChannel
      _subscribe(pubSubToken, accountId, userId);

      // Start presence timer
      _startPresenceTimer(pubSubToken, accountId, userId);
    } catch (e) {
      debugPrint('WebSocket connection failed: $e');
      _handleDisconnect(pubSubToken, accountId, userId);
    }
  }

  void _subscribe(String token, int accountId, int userId) {
    if (_channel == null || !_isConnected) return;

    final identifier = jsonEncode({
      'channel': 'RoomChannel',
      'pubsub_token': token,
      'account_id': accountId,
      'user_id': userId,
    });

    final payload = jsonEncode({
      'command': 'subscribe',
      'identifier': identifier,
    });

    _channel!.sink.add(payload);
  }

  void _startPresenceTimer(String token, int accountId, int userId) {
    _presenceTimer?.cancel();
    _presenceTimer = Timer.periodic(const Duration(seconds: 25), (timer) {
      if (_isConnected && _channel != null) {
        final identifier = jsonEncode({
          'channel': 'RoomChannel',
          'pubsub_token': token,
          'account_id': accountId,
          'user_id': userId,
        });

        final payload = jsonEncode({
          'command': 'message',
          'identifier': identifier,
          'data': jsonEncode({'action': 'update_presence'}),
        });

        _channel!.sink.add(payload);
      }
    });
  }

  void _handleMessage(dynamic raw, String token, int accountId, int userId) {
    try {
      final decoded = jsonDecode(raw.toString()) as Map<String, dynamic>;
      // ActionCable ping
      if (decoded['type'] == 'ping') return;
      if (decoded['type'] == 'welcome') return;
      if (decoded['type'] == 'confirm_subscription') {
        debugPrint('ActionCable RoomChannel subscription confirmed!');
        return;
      }

      final message = decoded['message'];
      if (message is Map<String, dynamic>) {
        final event = message['event'];
        final data = message['data'];
        if (event != null && data is Map<String, dynamic>) {
          _eventController.add(RealtimeEvent(event: event, data: data));
        }
      }
    } catch (e) {
      debugPrint('Error parsing ActionCable message: $e');
    }
  }

  void _handleDisconnect(String token, int accountId, int userId) {
    _isConnected = false;
    _isConnecting = false;
    _presenceTimer?.cancel();

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 4), () {
      connect(pubSubToken: token, accountId: accountId, userId: userId);
    });
  }

  void disconnect() {
    _presenceTimer?.cancel();
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _channel = null;
    _isConnected = false;
    _isConnecting = false;
  }
}
