import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:message_pro/core/error/failures.dart';
import 'package:message_pro/core/network/websocket_client.dart';
import 'package:message_pro/data/models/contact.dart';
import 'package:message_pro/data/models/conversation.dart';
import 'package:message_pro/data/models/message.dart';
import 'package:message_pro/data/models/user.dart';
import 'package:message_pro/data/models/message_template.dart';
import 'package:message_pro/data/models/conversation_filter_options.dart';
import 'package:message_pro/data/repositories/conversation_repository.dart';
import 'package:message_pro/logic/chat/chat_cubit.dart';
import 'package:message_pro/logic/conversation/conversation_cubit.dart';

class FakeConversationRepository implements IConversationRepository {
  List<Conversation> Function(int page)? getConversationsHandler;
  List<Message> Function(int conversationId, int? beforeId)? getMessagesHandler;

  @override
  Future<Either<Failure, List<Conversation>>> getConversations({
    String status = 'open',
    String assigneeType = 'all',
    int? inboxId,
    int? teamId,
    String? label,
    int? assigneeId,
    int? assigneeAgentBotId,
    int? lifecycleStageId,
    int page = 1,
  }) async {
    if (getConversationsHandler != null) {
      return Right(getConversationsHandler!(page));
    }
    return const Right([]);
  }

  @override
  Future<Either<Failure, List<Conversation>>> searchConversations(String query, {int page = 1}) async {
    return const Right([]);
  }

  @override
  Future<Either<Failure, Conversation>> getConversation(int conversationId) async {
    return const Left(ServerFailure('Not implemented'));
  }

  @override
  Future<Either<Failure, List<Message>>> getMessages(int conversationId, {int? beforeId, int? afterId}) async {
    if (getMessagesHandler != null) {
      return Right(getMessagesHandler!(conversationId, beforeId));
    }
    return const Right([]);
  }

  @override
  Future<Either<Failure, Message>> sendMessage({
    required int conversationId,
    required String content,
    bool isPrivate = false,
    List<String>? attachmentPaths,
    int? inReplyToId,
    String? echoId,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, Message>> sendTemplateMessage({
    required int conversationId,
    required String templateName,
    required String category,
    required String language,
    required String content,
    Map<String, dynamic>? processedParams,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, List<MessageTemplate>>> fetchInboxTemplates(int inboxId) async => const Right([]);

  @override
  Future<Either<Failure, void>> toggleStatus(int conversationId, String status, {String? snoozedUntil}) async => const Right(null);

  @override
  Future<Either<Failure, void>> assignAgent(int conversationId, int? agentId, {String? assigneeType}) async => const Right(null);

  @override
  Future<Either<Failure, List<int>>> fetchPinnedConversationIds() async => const Right([]);

  @override
  Future<Either<Failure, void>> pinConversation(int conversationId) async => const Right(null);

  @override
  Future<Either<Failure, void>> unpinConversation(int conversationId) async => const Right(null);

  @override
  Future<Either<Failure, void>> assignTeam(int conversationId, int? teamId) async => const Right(null);

  @override
  Future<Either<Failure, void>> updateLabels(int conversationId, List<String> labels) async => const Right(null);

  @override
  Future<Either<Failure, void>> updateLifecycleStage(int conversationId, int stageId) async => const Right(null);

  @override
  Future<Either<Failure, void>> updateConversationCustomAttributes(int conversationId, Map<String, dynamic> customAttributes) async => const Right(null);

  @override
  Future<Either<Failure, void>> markAsRead(int conversationId) async => const Right(null);

  @override
  Future<Either<Failure, List<Inbox>>> fetchInboxes() async => const Right([]);

  @override
  Future<Either<Failure, List<Label>>> fetchLabels() async => const Right([]);

  @override
  Future<Either<Failure, List<LifecycleStage>>> fetchLifecycleStages() async => const Right([]);

  @override
  Future<Either<Failure, List<Team>>> fetchTeams() async => const Right([]);

  @override
  Future<Either<Failure, List<User>>> fetchAgents() async => const Right([]);

  @override
  Future<Either<Failure, List<User>>> fetchAssignableAgents({int? inboxId, List<int>? inboxIds}) async => const Right([]);

  @override
  Future<Either<Failure, List<Map<String, String>>>> fetchCannedResponses() async => const Right([]);

  @override
  Future<Either<Failure, ConversationFilterOptions>> fetchFilterOptions() async => const Right(ConversationFilterOptions());

  @override
  Future<Either<Failure, void>> muteConversation(int conversationId) async => const Right(null);

  @override
  Future<Either<Failure, void>> unmuteConversation(int conversationId) async => const Right(null);

  @override
  Future<Either<Failure, List<MessageTemplate>>> fetchConversationTemplates(int conversationId) async => const Right([]);

  @override
  Future<Either<Failure, Message>> sendBrowserWhatsAppList({
    required int conversationId,
    required String templateId,
    required Map<String, dynamic> variables,
  }) async => throw UnimplementedError();

  @override
  Future<Either<Failure, Contact>> getCollaborators(int conversationId) async => throw UnimplementedError();

  @override
  Future<Either<Failure, Contact>> addCollaborator(int conversationId, int userId) async => throw UnimplementedError();

  @override
  Future<Either<Failure, Contact>> removeCollaborator(int conversationId, int userId) async => throw UnimplementedError();

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getContactableInboxes(int contactId) async => const Right([]);

  @override
  Future<Either<Failure, Conversation>> startNewConversation({
    required int contactId,
    required int inboxId,
    required String sourceId,
    String? message,
  }) async => throw UnimplementedError();

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getPhoneDestinations({String? phoneNumber}) async => const Right([]);

  @override
  Future<Either<Failure, Conversation>> startDirectChat({
    required int inboxId,
    required String phoneNumber,
    required String sourceId,
    String? contactName,
  }) async => throw UnimplementedError();

  @override
  void clearCache() {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Conversation makeFakeConversation(int id) {
  return Conversation(
    id: id,
    accountId: 1,
    inboxId: 1,
    status: 'open',
    contact: Contact(id: id, name: 'Contact $id'),
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
}

Message makeFakeMessage(int id, DateTime createdAt) {
  return Message(
    id: id,
    content: 'Message $id',
    createdAt: createdAt,
    messageType: 0,
    status: 'sent',
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Pagination tests', () {
    late FakeConversationRepository repo;
    late ActionCableClient ws;

    setUp(() {
      repo = FakeConversationRepository();
      ws = ActionCableClient();
    });

    test('ConversationCubit paginates with loadMoreConversations', () async {
      repo.getConversationsHandler = (page) {
        if (page == 1) {
          return List.generate(20, (i) => makeFakeConversation(i + 1));
        } else if (page == 2) {
          return List.generate(10, (i) => makeFakeConversation(i + 21));
        }
        return [];
      };

      final cubit = ConversationCubit(repo: repo, ws: ws);

      // Wait for initial load
      await Future.delayed(const Duration(milliseconds: 50));
      expect(cubit.state.conversations.length, 20);
      expect(cubit.state.page, 1);
      expect(cubit.state.hasMore, true);

      // Load more
      await cubit.loadMoreConversations();
      expect(cubit.state.conversations.length, 30);
      expect(cubit.state.page, 2);
      expect(cubit.state.hasMore, false); // page 2 returned 10 (< 20)

      await cubit.close();
    });

    test('ChatCubit loads previous messages with beforeId and prepends them', () async {
      final baseDate = DateTime(2026, 1, 1, 10, 0);

      repo.getMessagesHandler = (conversationId, beforeId) {
        if (beforeId == null) {
          // Page 1: messages 21..40
          return List.generate(20, (i) => makeFakeMessage(i + 21, baseDate.add(Duration(minutes: i + 21))));
        } else {
          // Older page: messages 1..20
          return List.generate(20, (i) => makeFakeMessage(i + 1, baseDate.add(Duration(minutes: i + 1))));
        }
      };

      final chatCubit = ChatCubit(conversationId: 99, repo: repo, ws: ws);

      // Wait for initial load
      await Future.delayed(const Duration(milliseconds: 50));
      expect(chatCubit.state.messages.length, 20);
      expect(chatCubit.state.messages.first.id, 21);
      expect(chatCubit.state.messages.last.id, 40);
      expect(chatCubit.state.hasMoreMessages, true);

      // Load previous messages
      await chatCubit.loadPreviousMessages();
      expect(chatCubit.state.messages.length, 40);
      expect(chatCubit.state.messages.first.id, 1); // Older message prepended
      expect(chatCubit.state.messages.last.id, 40); // Newest message still at end

      await chatCubit.close();
    });
  });
}
