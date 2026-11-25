import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../firebase_options.dart';
import '../di/injection_container.dart';
import '../storage/secure_storage_service.dart';
import '../../data/repositories/notification_repository.dart';
import '../../data/repositories/conversation_repository.dart';
import '../../logic/auth/auth_cubit.dart';
import '../../logic/auth/auth_state.dart';
import '../../logic/conversation/conversation_cubit.dart';
import '../../ui/screens/chat/chat_screen.dart';
import '../../ui/screens/main_layout.dart';

/// Top-level background message handler for Firebase Messaging
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    if (Firebase.apps.isEmpty) {
      try {
        await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      } catch (_) {
        await Firebase.initializeApp();
      }
    }
  } catch (e) {
    debugPrint('[PushNotification] Error initializing Firebase in background handler: $e');
  }
  debugPrint('[PushNotification] Background message received: ${message.messageId}, data: ${message.data}');
}

class PushNotificationService {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  static Map<String, dynamic>? pendingNotificationData;

  static const AndroidNotificationChannel _defaultChannel = AndroidNotificationChannel(
    'message_pro_notifications',
    'Message Pro Notifications',
    description: 'Notifications for Message Pro incoming messages and conversations',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  static String? _lastRegisteredToken;

  /// Initialize Firebase, local notifications and listeners
  static Future<void> initialize() async {
    try {
      // 1. Initialize Firebase Core
      if (Firebase.apps.isEmpty) {
        try {
          await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
        } catch (_) {
          await Firebase.initializeApp();
        }
      }

      // 2. Register Background Message Handler
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // 3. Request permissions
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
      debugPrint('[PushNotification] User permission status: ${settings.authorizationStatus}');

      // 4. Configure foreground presentation options (iOS/macOS)
      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // 5. Initialize Flutter Local Notifications
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwinInit = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const initSettings = InitializationSettings(
        android: androidInit,
        iOS: darwinInit,
        macOS: darwinInit,
      );

      await _localNotifications.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          debugPrint('[PushNotification] Local notification tapped with payload: ${response.payload}');
          if (response.payload != null && response.payload!.isNotEmpty) {
            _handlePayloadString(response.payload!);
          }
        },
      );

      // 6. Create Android Notification Channel and request runtime notification permission (Android 13+)
      final androidImplementation =
          _localNotifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidImplementation != null) {
        await androidImplementation.createNotificationChannel(_defaultChannel);
        final granted = await androidImplementation.requestNotificationsPermission();
        debugPrint('[PushNotification] Android notification permission granted: $granted');
      }

      // 7. Setup Foreground message listener
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('[PushNotification] Foreground message received: ${message.messageId}, notification: ${message.notification?.title}');
        _showForegroundNotification(message);
      });

      // 8. Setup Notification Click when app is running in background
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('[PushNotification] Notification clicked from background: ${message.messageId}, data: ${message.data}');
        handleNotificationData(message.data);
      });

      // 9. Handle notification that launched the app from terminated state
      final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        debugPrint('[PushNotification] App launched from terminated state via message: ${initialMessage.messageId}');
        pendingNotificationData = Map<String, dynamic>.from(initialMessage.data);
      }

      // 10. Listen to token refresh
      // ignore: deprecated_member_use
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        debugPrint('[PushNotification] FCM Token refreshed: $newToken');
        _lastRegisteredToken = null;
        registerDeviceToken();
      });

      debugPrint('[PushNotification] Service successfully initialized');
    } catch (e, stack) {
      debugPrint('[PushNotification] Initialization error: $e\n$stack');
    }
  }

  /// Show heads-up local notification in the foreground
  static Future<void> _showForegroundNotification(RemoteMessage message) async {
    try {
      final notification = message.notification;
      final data = message.data;

      // Extract title and body
      String title = notification?.title ?? '';
      String body = notification?.body ?? '';

      if (title.isEmpty && data.isNotEmpty) {
        title = data['title']?.toString() ??
            data['sender_name']?.toString() ??
            'Message Pro';
      }
      if (body.isEmpty && data.isNotEmpty) {
        body = data['content']?.toString() ??
            data['message']?.toString() ??
            data['body']?.toString() ??
            '';
      }

      if (title.isEmpty && body.isEmpty) {
        title = 'Message Pro';
        body = 'لديك رسالة جديدة';
      }

      final notificationId = message.hashCode & 0x7FFFFFFF;
      final payload = jsonEncode(data);

      final androidDetails = AndroidNotificationDetails(
        _defaultChannel.id,
        _defaultChannel.name,
        channelDescription: _defaultChannel.description,
        importance: Importance.max,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        playSound: true,
        enableVibration: true,
      );

      const darwinDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
        macOS: darwinDetails,
      );

      await _localNotifications.show(
        id: notificationId,
        title: title,
        body: body,
        notificationDetails: platformDetails,
        payload: payload,
      );
    } catch (e) {
      debugPrint('[PushNotification] Error showing foreground notification: $e');
    }
  }

  /// Central handler for notification payloads from background, terminated, or foreground clicks
  static Future<void> handleNotificationData(Map<dynamic, dynamic> rawData) async {
    final data = Map<String, dynamic>.from(rawData);
    debugPrint('[PushNotification] handleNotificationData: $data');

    final workspaceStr = data['workspace_id']?.toString() ?? data['account_id']?.toString();
    final workspaceId = int.tryParse(workspaceStr ?? '');
    final convId = _extractConversationId(data);
    final msgIdStr = data['message_id']?.toString();
    final messageId = int.tryParse(msgIdStr ?? '');
    final notifType = data['notification_type']?.toString();

    final navState = navigatorKey.currentState;
    final context = navState?.context ?? navigatorKey.currentContext;

    if (context == null) {
      debugPrint('[PushNotification] Context not ready, storing pending notification data');
      pendingNotificationData = data;
      return;
    }

    try {
      final authCubit = context.read<AuthCubit>();
      if (authCubit.state is! Authenticated) {
        debugPrint('[PushNotification] User not authenticated yet, storing pending notification data');
        pendingNotificationData = data;
        return;
      }

      final currentUser = (authCubit.state as Authenticated).user;

      // 1. Workspace Switch if payload specifies a different workspace
      if (workspaceId != null && workspaceId > 0 && workspaceId != currentUser.accountId) {
        debugPrint('[PushNotification] Switching workspace from ${currentUser.accountId} to $workspaceId');
        await authCubit.switchAccount(workspaceId);
        try {
          final switchCtx = navigatorKey.currentContext;
          if (switchCtx != null && switchCtx.mounted) {
            await switchCtx.read<ConversationCubit>().onWorkspaceSwitched(workspaceId);
          }
        } catch (e) {
          debugPrint('[PushNotification] Error notifying ConversationCubit of workspace switch: $e');
        }
      }

      // 2. Conversation Navigation
      if (convId != null && convId > 0) {
        await navigateToConversation(convId, messageId: messageId, fallbackType: notifType);
      } else {
        // Fallback for notifications without a conversation ID
        _navigateToFallback(notifType);
      }
    } catch (e) {
      debugPrint('[PushNotification] Error processing notification: $e');
      if (convId != null && convId > 0) {
        await navigateToConversation(convId, messageId: messageId);
      }
    }
  }

  /// Process pending notification once session is restored and UI is mounted
  static void processPendingNotification() {
    if (pendingNotificationData != null) {
      final data = pendingNotificationData!;
      pendingNotificationData = null;
      debugPrint('[PushNotification] Processing pending notification after session restore: $data');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        handleNotificationData(data);
      });
    }
  }

  static void _navigateToFallback(String? notifType) {
    final ctx = navigatorKey.currentContext;
    if (ctx == null || !ctx.mounted) return;
    if (notifType != null && (notifType.contains('call') || notifType.contains('missed'))) {
      MainLayout.switchTab(ctx, 0); // Calls tab
    } else {
      MainLayout.switchTab(ctx, 3); // Notifications tab
    }
  }

  /// Handle notification message navigation
  static void handleNotificationMessage(RemoteMessage message) {
    handleNotificationData(message.data);
  }

  /// Handle payload string from local notifications
  static void _handlePayloadString(String payloadStr) {
    try {
      final decoded = jsonDecode(payloadStr);
      if (decoded is Map) {
        handleNotificationData(Map<String, dynamic>.from(decoded));
      } else if (decoded is int) {
        handleNotificationData({'conversation_id': decoded.toString()});
      }
    } catch (_) {
      final parsed = int.tryParse(payloadStr);
      if (parsed != null) {
        handleNotificationData({'conversation_id': parsed.toString()});
      }
    }
  }

  /// Extract conversation_id from Chatwoot push payload
  static int? _extractConversationId(Map<dynamic, dynamic> data) {
    // 1. Direct conversation_id / conversationId
    if (data['conversation_id'] != null) {
      return int.tryParse(data['conversation_id'].toString());
    }
    if (data['conversationId'] != null) {
      return int.tryParse(data['conversationId'].toString());
    }

    // 2. Chatwoot nested primary_actor / conversation object
    if (data['primary_actor_id'] != null && data['primary_actor_type'] == 'Conversation') {
      return int.tryParse(data['primary_actor_id'].toString());
    }

    // 3. Parsed notification string if nested
    if (data['notification'] != null) {
      try {
        final nested = data['notification'] is String
            ? jsonDecode(data['notification'] as String)
            : data['notification'];
        if (nested is Map) {
          if (nested['primary_actor_id'] != null) {
            return int.tryParse(nested['primary_actor_id'].toString());
          }
          if (nested['conversation_id'] != null) {
            return int.tryParse(nested['conversation_id'].toString());
          }
        }
      } catch (_) {}
    }

    // 4. Fallback id
    if (data['id'] != null) {
      return int.tryParse(data['id'].toString());
    }

    return null;
  }

  /// Fetch conversation and push ChatScreen
  static Future<void> navigateToConversation(
    int conversationId, {
    int? messageId,
    String? fallbackType,
  }) async {
    final nav = navigatorKey.currentState;
    if (nav == null) {
      debugPrint('[PushNotification] Navigator not available yet for conversation #$conversationId');
      return;
    }

    debugPrint('[PushNotification] Navigating to conversation #$conversationId with messageId: $messageId');
    try {
      final repo = sl<IConversationRepository>();
      final result = await repo.getConversation(conversationId);
      result.fold(
        (failure) {
          debugPrint('[PushNotification] Failed to load conversation #$conversationId: ${failure.message}');
          _navigateToFallback(fallbackType);
        },
        (conversation) {
          nav.push(
            MaterialPageRoute(
              builder: (_) => ChatScreen(
                conversation: conversation,
                initialMessageId: messageId,
              ),
            ),
          );
        },
      );
    } catch (e) {
      debugPrint('[PushNotification] Error navigating to conversation: $e');
    }
  }

  /// Register FCM device token with the backend (POST /api/v1/notification_subscriptions)
  static Future<void> registerDeviceToken() async {
    try {
      final storage = sl<SecureStorageService>();
      final authHeaders = await storage.getAuthHeaders();
      // Only register if user is logged in
      if (authHeaders == null || authHeaders['access-token'] == null) {
        debugPrint('[PushNotification] User not authenticated, skipping token registration');
        return;
      }

      // On iOS, wait for APNs token to be set by the system before requesting FCM token
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        String? apnsToken = await FirebaseMessaging.instance.getAPNSToken();
        int retries = 0;
        while (apnsToken == null && retries < 5) {
          retries++;
          debugPrint('[PushNotification] Waiting for iOS APNs token (attempt $retries/5)...');
          await Future.delayed(const Duration(seconds: 2));
          apnsToken = await FirebaseMessaging.instance.getAPNSToken();
        }
        if (apnsToken == null) {
          debugPrint('[PushNotification] ⚠️ iOS APNs token is still null (Simulator or missing Push capability/APNs key)');
        }
      }

      String? token;
      try {
        // ignore: deprecated_member_use
        token = await FirebaseMessaging.instance.getToken();
      } catch (e) {
        debugPrint('[PushNotification] Initial getToken failed: $e');
      }
      if ((token == null || token.isEmpty) && defaultTargetPlatform == TargetPlatform.iOS) {
        await Future.delayed(const Duration(seconds: 3));
        try {
          // ignore: deprecated_member_use
          token = await FirebaseMessaging.instance.getToken();
        } catch (e) {
          debugPrint('[PushNotification] Retry getToken failed: $e');
        }
      }
      if (token == null || token.isEmpty) {
        debugPrint('[PushNotification] FCM token is null or empty');
        return;
      }

      if (_lastRegisteredToken == token) {
        debugPrint('[PushNotification] FCM token already registered with backend');
        return;
      }

      debugPrint('[PushNotification] Registering FCM token with backend...');
      final notifRepo = sl<INotificationRepository>();
      final result = await notifRepo.registerPushToken(token, deviceName: defaultTargetPlatform.name);
      result.fold(
        (failure) {
          debugPrint('[PushNotification] Failed to register push token: ${failure.message}');
        },
        (_) async {
          debugPrint('[PushNotification] FCM token registered successfully with backend!');
          _lastRegisteredToken = token;

          // Verify and activate push notification flags if empty
          try {
            final settingsResult = await notifRepo.getNotificationSettings();
            settingsResult.fold(
              (_) {},
              (settings) async {
                if (settings.selectedPushFlags.isEmpty) {
                  debugPrint('[PushNotification] Enabling default mobile push flags...');
                  final flagsToEnable = [
                    'mobile_push_conversation_creation',
                    'mobile_push_conversation_assignment',
                    'mobile_push_assigned_conversation_new_message',
                    'mobile_push_participating_conversation_new_message',
                    'mobile_push_conversation_mention',
                  ];
                  await notifRepo.updateNotificationSettings(
                    settings.copyWith(selectedPushFlags: flagsToEnable),
                  );
                  debugPrint('[PushNotification] Mobile push flags successfully activated');
                }
              },
            );
          } catch (e) {
            debugPrint('[PushNotification] Note: Could not auto-sync notification flags: $e');
          }
        },
      );
    } catch (e) {
      debugPrint('[PushNotification] Error registering push token: $e');
    }
  }

  /// Unregister FCM device token on logout (DELETE /api/v1/notification_subscriptions)
  static Future<void> unregisterDeviceToken() async {
    try {
      // ignore: deprecated_member_use
      final token = _lastRegisteredToken ?? await FirebaseMessaging.instance.getToken();
      if (token != null && token.isNotEmpty) {
        final notifRepo = sl<INotificationRepository>();
        await notifRepo.unregisterPushToken(token);
      }
      _lastRegisteredToken = null;
    } catch (e) {
      debugPrint('[PushNotification] Error unregistering push token: $e');
    }
  }
}
