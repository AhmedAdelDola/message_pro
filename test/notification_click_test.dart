import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:message_pro/core/error/failures.dart';
import 'package:message_pro/core/network/websocket_client.dart';
import 'package:message_pro/core/services/push_notification_service.dart';
import 'package:message_pro/data/models/contact.dart';
import 'package:message_pro/data/models/conversation.dart';
import 'package:message_pro/data/models/message.dart';
import 'package:message_pro/data/repositories/conversation_repository.dart';
import 'package:message_pro/logic/chat/chat_cubit.dart';
import 'package:message_pro/ui/screens/chat/widgets/message_bubble.dart';

class MockConversationRepository implements IConversationRepository {
  List<Message> messagesToReturn = [];
  int? lastAfterId;
  int? lastBeforeId;
  int? lastConversationIdRequested;
  bool shouldFail = false;

  @override
  Future<Either<Failure, List<Message>>> getMessages(
    int conversationId, {
    int? beforeId,
    int? afterId,
  }) async {
    lastConversationIdRequested = conversationId;
    lastBeforeId = beforeId;
    lastAfterId = afterId;

    if (shouldFail) {
      return const Left(ServerFailure('Failed to load'));
    }
    return Right(messagesToReturn);
  }

  @override
  Future<Either<Failure, Conversation>> getConversation(int conversationId) async {
    return Right(
      Conversation(
        id: conversationId,
        accountId: 39,
        inboxId: 1,
        status: 'open',
        contact: Contact(id: 1, name: 'Test Contact'),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<Either<Failure, List<Map<String, String>>>> fetchCannedResponses() async => const Right([]);
  @override
  Future<Either<Failure, void>> markAsRead(int conversationId) async => const Right(null);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockActionCableClient implements ActionCableClient {
  final _controller = StreamController<RealtimeEvent>.broadcast();

  @override
  Stream<RealtimeEvent> get events => _controller.stream;
  @override
  Stream<void> get onReconnected => const Stream.empty();
  @override
  Stream<bool> get isConnectedStream => const Stream.empty();
  @override
  bool get isConnected => true;
  @override
  bool get isConnecting => false;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget _wrap(Widget child) {
  return ScreenUtilInit(
    designSize: const Size(390, 844),
    minTextAdapt: true,
    builder: (context, _) => MaterialApp(
      home: Scaffold(
        body: ListView(children: [child]),
      ),
    ),
  );
}

void main() {
  group('Notification Data & Target Message Unit Tests', () {
    test('ChatCubit loadTargetMessage returns true if message is already loaded without API call', () async {
      final initialMsg = Message(
        id: 9001,
        conversationId: 123,
        messageType: 0,
        content: 'Already in memory',
        createdAt: DateTime.now(),
      );

      final repo = MockConversationRepository()..messagesToReturn = [initialMsg];
      final ws = MockActionCableClient();
      final cubit = ChatCubit(conversationId: 123, repo: repo, ws: ws);
      await pumpEventQueue();

      repo.lastAfterId = null;
      repo.lastBeforeId = null;

      final found = await cubit.loadTargetMessage(9001);
      expect(found, isTrue);
      // Ensure no extra call was made since it was already in memory
      expect(repo.lastAfterId, isNull);
      expect(repo.lastBeforeId, isNull);

      await cubit.close();
    });

    test('ChatCubit loadTargetMessage requests after=id & before=id+1 and merges message into state', () async {
      final regularMsg = Message(
        id: 100,
        conversationId: 123,
        messageType: 0,
        content: 'Initial message',
        createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
      );

      final targetMsg = Message(
        id: 9001,
        conversationId: 123,
        messageType: 0,
        content: 'Target notification message',
        createdAt: DateTime.now(),
      );

      final repo = MockConversationRepository()..messagesToReturn = [regularMsg];
      final ws = MockActionCableClient();
      final cubit = ChatCubit(conversationId: 123, repo: repo, ws: ws);
      await pumpEventQueue();

      expect(cubit.state.messages.length, 1);
      expect(cubit.state.messages.any((m) => m.id == 9001), isFalse);

      // Now set repo to return targetMsg when after/before are requested
      repo.messagesToReturn = [targetMsg];

      final found = await cubit.loadTargetMessage(9001);
      expect(found, isTrue);
      expect(repo.lastConversationIdRequested, 123);
      expect(repo.lastAfterId, 9001);
      expect(repo.lastBeforeId, 9002); // 9001 + 1

      // Verify merged into state
      expect(cubit.state.messages.length, 2);
      expect(cubit.state.messages.any((m) => m.id == 9001), isTrue);

      await cubit.close();
    });

    test('ChatCubit loadTargetMessage returns false gracefully if message is not found / deleted', () async {
      final regularMsg = Message(
        id: 100,
        conversationId: 123,
        messageType: 0,
        content: 'Existing message',
        createdAt: DateTime.now(),
      );

      final repo = MockConversationRepository()..messagesToReturn = [regularMsg];
      final ws = MockActionCableClient();
      final cubit = ChatCubit(conversationId: 123, repo: repo, ws: ws);
      await pumpEventQueue();

      // Empty return from backend
      repo.messagesToReturn = [];

      final found = await cubit.loadTargetMessage(9999);
      expect(found, isFalse);
      expect(repo.lastAfterId, 9999);
      expect(repo.lastBeforeId, 10000);

      // Existing messages remain unaffected
      expect(cubit.state.messages.length, 1);

      await cubit.close();
    });

    test('PushNotificationService queues pendingNotificationData when context is null', () {
      PushNotificationService.pendingNotificationData = null;

      final testData = {
        'workspace_id': '39',
        'account_id': '39',
        'conversation_id': '123',
        'message_id': '9001',
        'notification_id': '456',
        'notification_type': 'assigned_conversation_new_message',
      };

      PushNotificationService.handleNotificationData(testData);
      expect(PushNotificationService.pendingNotificationData, isNotNull);
      expect(PushNotificationService.pendingNotificationData?['workspace_id'], '39');
      expect(PushNotificationService.pendingNotificationData?['conversation_id'], '123');
      expect(PushNotificationService.pendingNotificationData?['message_id'], '9001');

      // Clear for subsequent tests
      PushNotificationService.pendingNotificationData = null;
    });
  });

  group('MessageBubble Highlight UI Tests', () {
    testWidgets('MessageBubble applies accent highlight when isHighlighted is true', (tester) async {
      final msg = Message(
        id: 9001,
        messageType: 0,
        content: 'I should be highlighted',
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        _wrap(
          MessageBubble(
            message: msg,
            isHighlighted: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final animatedContainers = tester.widgetList<AnimatedContainer>(find.byType(AnimatedContainer));
      expect(animatedContainers, isNotEmpty);

      // Find the highlight container with non-transparent color
      final highlightContainer = animatedContainers.firstWhere(
        (c) {
          final dec = c.decoration;
          if (dec is BoxDecoration) {
            return dec.color != null && dec.color != Colors.transparent;
          }
          return false;
        },
      );
      final boxDec = highlightContainer.decoration as BoxDecoration;
      expect(boxDec.color, isNotNull);
      expect(boxDec.color, isNot(Colors.transparent));
    });

    testWidgets('MessageBubble renders normal transparent container when isHighlighted is false', (tester) async {
      final msg = Message(
        id: 9002,
        messageType: 0,
        content: 'I am normal',
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        _wrap(
          MessageBubble(
            message: msg,
            isHighlighted: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final animatedContainers = tester.widgetList<AnimatedContainer>(find.byType(AnimatedContainer));
      expect(animatedContainers, isNotEmpty);

      final highlightContainer = animatedContainers.firstWhere(
        (c) {
          final dec = c.decoration;
          if (dec is BoxDecoration) {
            return dec.borderRadius == BorderRadius.circular(16);
          }
          return false;
        },
      );
      final boxDec = highlightContainer.decoration as BoxDecoration;
      expect(boxDec.color, Colors.transparent);
    });
  });

  group('Notification Extraction & Fallback Tests', () {
    test('Payload with string IDs converts correctly to int parameters', () {
      final payload = {
        'workspace_id': '39',
        'account_id': '39',
        'conversation_id': '123',
        'message_id': '9001',
        'notification_id': '456',
        'notification_type': 'assigned_conversation_new_message',
      };

      final workspaceId = int.tryParse(payload['workspace_id'] ?? '');
      final conversationId = int.tryParse(payload['conversation_id'] ?? '');
      final messageId = int.tryParse(payload['message_id'] ?? '');

      expect(workspaceId, 39);
      expect(conversationId, 123);
      expect(messageId, 9001);
    });

    test('Falls back to account_id when workspace_id is absent', () {
      final payload = {
        'account_id': '42',
        'conversation_id': '200',
      };

      final workspaceStr = payload['workspace_id'] ?? payload['account_id'];
      final workspaceId = int.tryParse(workspaceStr ?? '');
      expect(workspaceId, 42);
    });
  });
}
