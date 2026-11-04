import 'dart:async';
import 'dart:convert';
import 'dart:math';
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
  bool _wasConnectedBefore = false;
  int _reconnectAttempts = 0;

  String? _lastPubSubToken;
  int? _lastAccountId;
  int? _lastUserId;
  String? _lastCustomWsUrl;

  final _eventController = StreamController<RealtimeEvent>.broadcast();
  Stream<RealtimeEvent> get events => _eventController.stream;

  final _reconnectedController = StreamController<void>.broadcast();
  /// Fires whenever the WebSocket successfully reconnects after a disconnect.
  /// Listeners should use this to refresh/reload conversations and messages.
  Stream<void> get onReconnected => _reconnectedController.stream;

  final _connectionStateController = StreamController<bool>.broadcast();
  Stream<bool> get isConnectedStream => _connectionStateController.stream;

  bool get isConnected => _isConnected;
  bool get isConnecting => _isConnecting;

  final SecureStorageService _storage = SecureStorageService();

  Future<void> connect({
    required String pubSubToken,
    required int accountId,
    required int userId,
    String? customWsUrl,
  }) async {
    _lastPubSubToken = pubSubToken;
    _lastAccountId = accountId;
    _lastUserId = userId;
    _lastCustomWsUrl = customWsUrl;

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

      debugPrint('Connecting to WebSocket: $wsUrl (attempt: $_reconnectAttempts)');
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

      _channel!.stream.listen(
        (dynamic rawMessage) {
          _handleMessage(rawMessage, pubSubToken, accountId, userId);
        },
        onDone: () {
          debugPrint('WebSocket stream closed (onDone)');
          _handleDisconnect();
        },
        onError: (error) {
          debugPrint('WebSocket error: $error');
          _handleDisconnect();
        },
      );

      _isConnected = true;
      _isConnecting = false;
      _connectionStateController.add(true);

      // Subscribe to RoomChannel
      _subscribe(pubSubToken, accountId, userId);

      // Start presence timer
      _startPresenceTimer(pubSubToken, accountId, userId);

      if (_wasConnectedBefore) {
        debugPrint('WebSocket reconnected successfully! Emitting onReconnected');
        _reconnectedController.add(null);
      }
      _wasConnectedBefore = true;
      _reconnectAttempts = 0;
    } catch (e) {
      debugPrint('WebSocket connection failed: $e');
      _handleDisconnect();
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

    try {
      _channel!.sink.add(payload);
    } catch (e) {
      debugPrint('Error subscribing to RoomChannel: $e');
    }
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

        try {
          _channel!.sink.add(payload);
        } catch (_) {}
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

  void _handleDisconnect() {
    _isConnected = false;
    _isConnecting = false;
    _connectionStateController.add(false);
    _presenceTimer?.cancel();
    try {
      _channel?.sink.close();
    } catch (_) {}
    _channel = null;

    if (_lastPubSubToken == null || _lastAccountId == null || _lastUserId == null) {
      return;
    }

    _reconnectAttempts++;
    final delaySeconds = min(20, max(2, pow(2, min(_reconnectAttempts, 4)).toInt()));
    debugPrint('WebSocket disconnected. Reconnecting in $delaySeconds seconds (attempt $_reconnectAttempts)...');

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(seconds: delaySeconds), () {
      if (!_isConnected && !_isConnecting && _lastPubSubToken != null) {
        connect(
          pubSubToken: _lastPubSubToken!,
          accountId: _lastAccountId!,
          userId: _lastUserId!,
          customWsUrl: _lastCustomWsUrl,
        );
      }
    });
  }

  /// Manually force a reconnect and refresh
  Future<void> refreshConnection() async {
    disconnect();
    if (_lastPubSubToken != null && _lastAccountId != null && _lastUserId != null) {
      await connect(
        pubSubToken: _lastPubSubToken!,
        accountId: _lastAccountId!,
        userId: _lastUserId!,
        customWsUrl: _lastCustomWsUrl,
      );
    }
  }

  void disconnect() {
    _presenceTimer?.cancel();
    _reconnectTimer?.cancel();
    try {
      _channel?.sink.close();
    } catch (_) {}
    _channel = null;
    _isConnected = false;
    _isConnecting = false;
    _connectionStateController.add(false);
  }
}
