import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:message_pro/core/error/failures.dart';
import 'package:message_pro/core/network/websocket_client.dart';
import 'package:message_pro/data/models/message.dart';
import 'package:message_pro/data/models/user.dart';
import 'package:message_pro/data/repositories/conversation_repository.dart';
import 'package:message_pro/logic/chat/chat_cubit.dart';
import 'package:message_pro/ui/screens/chat/widgets/message_bubble.dart';

class MockConversationRepository implements IConversationRepository {
  List<Message> initialMessages = [];
  Message? lastEditedMessage;
  Message? lastReactedMessage;
  String? lastSentEmoji;
  bool shouldFail422 = false;

  @override
  Future<Either<Failure, List<Message>>> getMessages(int conversationId, {int? beforeId, int? afterId}) async {
    return Right(initialMessages);
  }

  @override
  Future<Either<Failure, List<Map<String, String>>>> fetchCannedResponses() async {
    return const Right([]);
  }

  @override
  Future<Either<Failure, void>> markAsRead(int conversationId) async {
    return const Right(null);
  }

  @override
  Future<Either<Failure, Message>> editMessage({
    required int conversationId,
    required int messageId,
    required String content,
  }) async {
    if (shouldFail422) {
      return const Left(ServerFailure('لا يمكن تعديل الرسالة بعد مرور 15 دقيقة'));
    }
    final updated = Message(
      id: messageId,
      conversationId: conversationId,
      messageType: 1,
      content: content,
      createdAt: DateTime.now(),
      contentAttributes: {'edited': true},
    );
    lastEditedMessage = updated;
    return Right(updated);
  }

  @override
  Future<Either<Failure, Message>> sendReaction({
    required int conversationId,
    required int messageId,
    required String emoji,
  }) async {
    lastSentEmoji = emoji;
    final updated = Message(
      id: messageId,
      conversationId: conversationId,
      messageType: 1,
      content: 'Message with reaction',
      createdAt: DateTime.now(),
      reactions: emoji.isNotEmpty
          ? [MessageReaction(emoji: emoji, actor: 'Channel::Whatsapp:1')]
          : [],
    );
    lastReactedMessage = updated;
    return Right(updated);
  }

  @override
  Future<Either<Failure, List<ReactionParticipant>>> getReactions({
    required int conversationId,
    required int messageId,
    Map<String, dynamic>? contentAttributes,
  }) async {
    return Right([
      const ReactionParticipant(
        id: 10,
        name: 'Ahmed Support',
        actor: 'Channel::Whatsapp:1',
        emoji: '👍',
      ),
    ]);
  }

  @override
  void clearCache() {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockActionCableClient implements ActionCableClient {
  final _eventController = StreamController<RealtimeEvent>.broadcast();

  @override
  Stream<RealtimeEvent> get events => _eventController.stream;

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

void main() {
  group('MessageActions & Reaction Models Tests', () {
    test('Parses message_actions with edit, edit_until and react flags', () {
      final nowSec = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final json = {
        'id': 100,
        'message_type': 1,
        'content': 'Test editable message',
        'message_actions': {
          'edit': true,
          'edit_until': nowSec + 600, // 10 minutes in future
          'react': true,
        },
      };

      final msg = Message.fromJson(json);
      expect(msg.messageActions.canEdit, isTrue);
      expect(msg.messageActions.canReact, isTrue);
      expect(msg.messageActions.isEditExpired, isFalse);
      expect(msg.messageActions.remainingEditTime?.inMinutes, greaterThanOrEqualTo(9));
    });

    test('MessageActions expires when edit_until is in the past', () {
      final nowSec = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final json = {
        'id': 101,
        'message_type': 1,
        'content': 'Expired message',
        'message_actions': {
          'edit': true,
          'edit_until': nowSec - 60, // 1 minute in past
          'react': true,
        },
      };

      final msg = Message.fromJson(json);
      expect(msg.messageActions.isEditExpired, isTrue);
      expect(msg.canEditBy(null), isFalse);
    });

    test('canEditBy allows sender or admin, but rejects incoming or attachment messages', () {
      final nowSec = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final normalUser = User(
        id: 1,
        name: 'Sarah',
        email: 'sarah@test.com',
        role: 'agent',
        accountId: 1,
        availabilityStatus: 'online',
        accounts: [],
      );

      final adminUser = User(
        id: 2,
        name: 'Admin Boss',
        email: 'admin@test.com',
        role: 'administrator',
        accountId: 1,
        availabilityStatus: 'online',
        accounts: [],
      );

      // Outgoing text without attachment within edit_until
      final validMsg = Message(
        id: 200,
        messageType: 1, // Outgoing
        content: 'Valid editable text',
        createdAt: DateTime.now(),
        senderName: 'Sarah',
        messageActions: MessageActions(
          canEdit: true,
          editUntil: nowSec + 500,
          canReact: true,
        ),
      );

      expect(validMsg.canEditBy(normalUser), isTrue);
      expect(validMsg.canEditBy(adminUser), isTrue);

      // Incoming message cannot be edited
      final incomingMsg = validMsg.copyWith(messageType: 0);
      expect(incomingMsg.canEditBy(adminUser), isFalse);

      // Message with attachment cannot be edited on WhatsApp QR
      final attMsg = validMsg.copyWith(attachments: [
        MessageAttachment(fileType: 'image', dataUrl: 'http://test.com/img.jpg'),
      ]);
      expect(attMsg.canEditBy(adminUser), isFalse);
    });

    test('Parses reactions and groups reactionSummary correctly', () {
      final json = {
        'id': 300,
        'message_type': 0,
        'content': 'Liked message',
        'reactions': [
          {'emoji': '👍', 'actor': 'Channel::Whatsapp:1'},
          {'emoji': '❤️', 'actor': 'User:12'},
          {'emoji': '👍', 'actor': 'User:13'},
        ],
      };

      final msg = Message.fromJson(json);
      expect(msg.reactions.length, 3);
      expect(msg.reactionsSummary['👍'], 2);
      expect(msg.reactionsSummary['❤️'], 1);
      expect(msg.uniqueReactionEmojis, containsAll(['👍', '❤️']));
    });

    test('Identifies edited messages via isEdited', () {
      final editedMsg1 = Message(
        id: 401,
        messageType: 1,
        createdAt: DateTime.now(),
        contentAttributes: {'edited': true},
      );
      expect(editedMsg1.isEdited, isTrue);

      final editedMsg2 = Message(
        id: 402,
        messageType: 1,
        createdAt: DateTime.now(),
        contentAttributes: {'is_edited': true},
      );
      expect(editedMsg2.isEdited, isTrue);

      final uneditedMsg = Message(
        id: 403,
        messageType: 1,
        createdAt: DateTime.now(),
      );
      expect(uneditedMsg.isEdited, isFalse);
    });
  });

  group('ChatCubit Edit & Reaction Integration Tests', () {
    test('editMessage updates state on success', () async {
      final initialMsg = Message(
        id: 501,
        conversationId: 50,
        messageType: 1,
        content: 'Original message text',
        createdAt: DateTime.now(),
      );
      final repo = MockConversationRepository()..initialMessages = [initialMsg];
      final ws = MockActionCableClient();
      final cubit = ChatCubit(conversationId: 50, repo: repo, ws: ws);
      await pumpEventQueue();

      final error = await cubit.editMessage(501, 'Updated message text');
      expect(error, isNull);
      expect(cubit.state.messages.first.content, 'Updated message text');
      expect(cubit.state.messages.first.isEdited, isTrue);

      await cubit.close();
    });

    test('editMessage returns 422 server error message', () async {
      final initialMsg = Message(
        id: 502,
        conversationId: 50,
        messageType: 1,
        content: 'Cannot edit me',
        createdAt: DateTime.now(),
      );
      final repo = MockConversationRepository()
        ..shouldFail422 = true
        ..initialMessages = [initialMsg];
      final ws = MockActionCableClient();
      final cubit = ChatCubit(conversationId: 50, repo: repo, ws: ws);
      await pumpEventQueue();

      final error = await cubit.editMessage(502, 'New text');
      expect(error, 'لا يمكن تعديل الرسالة بعد مرور 15 دقيقة');
      expect(cubit.state.messages.first.content, 'Cannot edit me');

      await cubit.close();
    });

    test('sendReaction updates message reactions in state', () async {
      final initialMsg = Message(
        id: 503,
        conversationId: 50,
        messageType: 1,
        content: 'Message for reactions',
        createdAt: DateTime.now(),
      );
      final repo = MockConversationRepository()..initialMessages = [initialMsg];
      final ws = MockActionCableClient();
      final cubit = ChatCubit(conversationId: 50, repo: repo, ws: ws);
      await pumpEventQueue();

      // Send reaction 👍
      final err1 = await cubit.sendReaction(503, '👍');
      expect(err1, isNull);
      expect(cubit.state.messages.first.reactions.first.emoji, '👍');

      // Send empty string to remove reaction
      final err2 = await cubit.sendReaction(503, '');
      expect(err2, isNull);
      expect(cubit.state.messages.first.reactions.isEmpty, isTrue);

      await cubit.close();
    });
  });

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

  group('MessageBubble Edit & Reaction UI Tests', () {
    testWidgets('Renders Reactions Pill when message has reactions', (tester) async {
      final msg = Message(
        id: 601,
        messageType: 1, // Outgoing
        content: 'Check out reactions',
        createdAt: DateTime.now(),
        reactions: [
          const MessageReaction(emoji: '👍', actor: 'Channel::Whatsapp:1'),
          const MessageReaction(emoji: '❤️', actor: 'User:10'),
        ],
      );

      bool didTapReactions = false;

      await tester.pumpWidget(
        _wrap(
          MessageBubble(
            message: msg,
            onViewReactions: (_) => didTapReactions = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify emojis are visible in the reaction pill
      expect(find.text('👍'), findsOneWidget);
      expect(find.text('❤️'), findsOneWidget);
      expect(find.text('2'), findsOneWidget); // Count = 2

      // Tap the reactions pill
      await tester.tap(find.text('2'));
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();
      expect(didTapReactions, isTrue);
    });

    testWidgets('Renders (مُعدلة) label when message isEdited', (tester) async {
      final msg = Message(
        id: 602,
        messageType: 1, // Outgoing
        content: 'This message was edited',
        createdAt: DateTime.now(),
        contentAttributes: {'edited': true},
      );

      await tester.pumpWidget(
        _wrap(
          MessageBubble(
            message: msg,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining(RegExp(r'(مُعدلة|Edited)')), findsOneWidget);
    });

    testWidgets('Long press displays Emoji Reaction Bar when canReact = true', (tester) async {
      final msg = Message(
        id: 603,
        messageType: 1,
        content: 'React to me please',
        createdAt: DateTime.now(),
        messageActions: const MessageActions(canReact: true),
      );

      String? selectedEmoji;

      await tester.pumpWidget(
        _wrap(
          MessageBubble(
            message: msg,
            onReact: (_, emoji) => selectedEmoji = emoji,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Long press on message to trigger action sheet
      await tester.longPress(find.text('React to me please'));
      await tester.pumpAndSettle();

      // Verify emoji options appear
      expect(find.text('👍'), findsOneWidget);
      expect(find.text('❤️'), findsOneWidget);
      expect(find.text('😂'), findsOneWidget);

      // Tap on 👍
      await tester.tap(find.text('👍'));
      await tester.pumpAndSettle();

      expect(selectedEmoji, '👍');
    });

    testWidgets('Long press displays Edit Message option when canEditBy = true', (tester) async {
      final nowSec = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final user = User(
        id: 5,
        name: 'Agent Sarah',
        email: 'sarah@test.com',
        role: 'agent',
        accountId: 1,
        availabilityStatus: 'online',
        accounts: [],
      );

      final msg = Message(
        id: 604,
        messageType: 1,
        content: 'I want to fix a typo',
        createdAt: DateTime.now(),
        senderName: 'Agent Sarah',
        messageActions: MessageActions(
          canEdit: true,
          editUntil: nowSec + 900, // 15 mins
        ),
      );

      bool editTriggered = false;

      await tester.pumpWidget(
        _wrap(
          MessageBubble(
            message: msg,
            currentUser: user,
            onEditMessage: (_) => editTriggered = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.longPress(find.text('I want to fix a typo'));
      await tester.pumpAndSettle();

      final editOption = find.textContaining(RegExp(r'(تعديل الرسالة|Edit Message)'));
      expect(editOption, findsOneWidget);

      await tester.tap(editOption);
      await tester.pumpAndSettle();

      expect(editTriggered, isTrue);
    });
  });
}
