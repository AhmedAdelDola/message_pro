import 'package:flutter_test/flutter_test.dart';
import 'package:dartz/dartz.dart';
import 'package:message_pro/core/error/failures.dart';
import 'package:message_pro/data/models/conversation_filter_options.dart';
import 'package:message_pro/data/models/contact.dart';
import 'package:message_pro/data/models/user.dart';
import 'package:message_pro/data/models/conversation.dart';
import 'package:message_pro/data/models/message.dart';
import 'package:message_pro/data/models/message_template.dart';
import 'package:message_pro/data/repositories/conversation_repository.dart';
import 'package:message_pro/logic/conversation/conversation_cubit.dart';
import 'package:message_pro/core/network/websocket_client.dart';

class FakeConversationRepository implements IConversationRepository {
  ConversationFilterOptions filterOptionsToReturn = const ConversationFilterOptions();
  int fetchFilterOptionsCallCount = 0;
  Map<String, dynamic> lastGetConversationsParams = {};
  int getConversationsCallCount = 0;

  @override
  Future<Either<Failure, ConversationFilterOptions>> fetchFilterOptions() async {
    fetchFilterOptionsCallCount++;
    return Right(filterOptionsToReturn);
  }

  @override
  Future<Either<Failure, List<Conversation>>> getConversations({
    String status = 'open',
    String assigneeType = 'me',
    int? inboxId,
    int? teamId,
    String? label,
    int? assigneeId,
    int? assigneeAgentBotId,
    int page = 1,
  }) async {
    getConversationsCallCount++;
    lastGetConversationsParams = {
      'status': status,
      'assigneeType': assigneeType,
      'inboxId': inboxId,
      'teamId': teamId,
      'label': label,
      'assigneeId': assigneeId,
      'assigneeAgentBotId': assigneeAgentBotId,
      'page': page,
    };
    return const Right(<Conversation>[]);
  }

  @override
  Future<Either<Failure, List<Inbox>>> fetchInboxes() async => const Right([]);
  @override
  Future<Either<Failure, List<Label>>> fetchLabels() async => const Right([]);
  @override
  Future<Either<Failure, List<Team>>> fetchTeams() async => const Right([]);
  @override
  Future<Either<Failure, List<User>>> fetchAgents() async => const Right([]);
  @override
  Future<Either<Failure, List<User>>> fetchAssignableAgents({int? inboxId, List<int>? inboxIds}) async => const Right([]);
  @override
  Future<Either<Failure, List<LifecycleStage>>> fetchLifecycleStages() async => const Right([]);
  @override
  Future<Either<Failure, List<Map<String, String>>>> fetchCannedResponses() async => const Right([]);
  @override
  Future<Either<Failure, Conversation>> getConversation(int conversationId) async => throw UnimplementedError();
  @override
  Future<Either<Failure, List<Message>>> getMessages(int conversationId, {int? beforeId, int? afterId}) async => const Right([]);
  @override
  Future<Either<Failure, List<Conversation>>> searchConversations(String query, {int page = 1}) async => const Right([]);
  @override
  Future<Either<Failure, Message>> sendMessage({required int conversationId, required String content, bool isPrivate = false, List<String>? attachmentPaths, int? inReplyToId, String? echoId}) async => throw UnimplementedError();
  @override
  Future<Either<Failure, Message>> sendTemplateMessage({required int conversationId, required String templateName, required String category, required String language, required String content, Map<String, dynamic>? processedParams}) async => throw UnimplementedError();
  @override
  Future<Either<Failure, List<MessageTemplate>>> fetchInboxTemplates(int inboxId) async => const Right([]);
  @override
  Future<Either<Failure, List<MessageTemplate>>> fetchConversationTemplates(int conversationId) async => const Right([]);
  @override
  Future<Either<Failure, Message>> sendBrowserWhatsAppList({required int conversationId, required String templateId, required Map<String, dynamic> variables}) async => throw UnimplementedError();
  @override
  Future<Either<Failure, Contact>> getCollaborators(int conversationId) async => throw UnimplementedError();
  @override
  Future<Either<Failure, Contact>> addCollaborator(int conversationId, int userId) async => throw UnimplementedError();
  @override
  Future<Either<Failure, Contact>> removeCollaborator(int conversationId, int userId) async => throw UnimplementedError();
  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getContactableInboxes(int contactId) async => const Right([]);
  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getPhoneDestinations({String? phoneNumber}) async => const Right([]);
  @override
  Future<Either<Failure, Conversation>> startNewConversation({required int contactId, required int inboxId, required String sourceId, String? message}) async => throw UnimplementedError();
  @override
  Future<Either<Failure, Conversation>> startDirectChat({required String phoneNumber, required int inboxId, required String sourceId, String? contactName}) async => throw UnimplementedError();
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
  Future<Either<Failure, void>> muteConversation(int conversationId) async => const Right(null);
  @override
  Future<Either<Failure, void>> unmuteConversation(int conversationId) async => const Right(null);
  @override
  Future<Either<Failure, void>> markAsRead(int conversationId) async => const Right(null);

  @override
  void clearCache() {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeWebSocketClient implements ActionCableClient {
  @override
  Stream<RealtimeEvent> get events => const Stream<RealtimeEvent>.empty();

  @override
  Stream<void> get onReconnected => const Stream<void>.empty();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('ConversationFilterOptions Model Tests', () {
    test('Parses direct JSON response accurately', () {
      final json = {
        'inboxes': [
          {'id': 10, 'name': 'Support WhatsApp', 'channel_type': 'Channel::Whatsapp'},
          {'id': 11, 'name': 'Sales Web', 'channel_type': 'Channel::WebWidget'}
        ],
        'agents': [
          {'id': 5, 'name': 'Ahmed Ali', 'email': 'ahmed@company.com', 'role': 'agent'}
        ],
        'ai_agents': [
          {'id': 1, 'agent_bot_id': 19, 'name': 'Sales Bot AI', 'role': 'ai_bot'},
          {'id': 2, 'agent_bot_id': 24, 'name': 'Support GPT', 'role': 'ai_bot'}
        ],
        'teams': [
          {'id': 3, 'name': 'Customer Care', 'description': 'Main support team'}
        ],
        'can_filter_agents': true,
      };

      final options = ConversationFilterOptions.fromJson(json);

      expect(options.inboxes.length, 2);
      expect(options.inboxes.first.name, 'Support WhatsApp');
      expect(options.agents.length, 1);
      expect(options.agents.first.name, 'Ahmed Ali');
      expect(options.aiAgents.length, 2);
      expect(options.aiAgents.first.name, 'Sales Bot AI');
      expect(options.aiAgents.first.agentBotId, 19);
      expect(options.aiAgents[1].agentBotId, 24);
      expect(options.teams.length, 1);
      expect(options.teams.first.name, 'Customer Care');
      expect(options.canFilterAgents, isTrue);
    });

    test('Handles missing or empty fields safely', () {
      final options = ConversationFilterOptions.fromJson({});
      expect(options.inboxes, isEmpty);
      expect(options.agents, isEmpty);
      expect(options.aiAgents, isEmpty);
      expect(options.teams, isEmpty);
      expect(options.canFilterAgents, isFalse);
    });
  });

  group('ConversationCubit Filter Integration Tests', () {
    late FakeConversationRepository fakeRepo;
    late FakeWebSocketClient fakeWs;
    late ConversationCubit cubit;

    setUp(() {
      fakeRepo = FakeConversationRepository();
      fakeWs = FakeWebSocketClient();

      fakeRepo.filterOptionsToReturn = ConversationFilterOptions.fromJson({
        'inboxes': [
          {'id': 10, 'name': 'WhatsApp Main', 'channel_type': 'Channel::Whatsapp'}
        ],
        'agents': [
          {'id': 7, 'name': 'Karim', 'email': 'karim@test.com'}
        ],
        'ai_agents': [
          {'id': 1, 'agent_bot_id': 19, 'name': 'Antigravity AI'}
        ],
        'teams': [
          {'id': 2, 'name': 'VIP Support'}
        ],
        'can_filter_agents': true,
      });

      cubit = ConversationCubit(repo: fakeRepo, ws: fakeWs);
    });

    tearDown(() {
      cubit.close();
    });

    test('loadFilterOptions loads filter options into state', () async {
      await cubit.loadFilterOptions();
      expect(cubit.state.filterOptions, isNotNull);
      expect(cubit.state.filterOptions!.aiAgents.length, 1);
      expect(cubit.state.filterOptions!.aiAgents.first.agentBotId, 19);
      expect(cubit.state.filterOptions!.canFilterAgents, isTrue);
    });

    test('setAiAgentFilter resets page to 1, sets assigneeType to all and triggers getConversations with assigneeAgentBotId', () async {
      cubit.setAiAgentFilter(19);

      expect(cubit.state.selectedAssigneeAgentBotId, 19);
      expect(cubit.state.selectedAssigneeId, isNull);
      expect(cubit.state.selectedInboxId, isNull);
      expect(cubit.state.assigneeType, 'all');
      expect(cubit.state.page, 1);

      expect(fakeRepo.lastGetConversationsParams['assigneeAgentBotId'], 19);
      expect(fakeRepo.lastGetConversationsParams['assigneeType'], 'all');
      expect(fakeRepo.lastGetConversationsParams['page'], 1);
    });

    test('setAssigneeFilter sets assignee_id and resets others', () async {
      cubit.setAssigneeFilter(7);

      expect(cubit.state.selectedAssigneeId, 7);
      expect(cubit.state.selectedAssigneeAgentBotId, isNull);
      expect(cubit.state.assigneeType, 'all');

      expect(fakeRepo.lastGetConversationsParams['assigneeId'], 7);
      expect(fakeRepo.lastGetConversationsParams['assigneeAgentBotId'], isNull);
      expect(fakeRepo.lastGetConversationsParams['assigneeType'], 'all');
      expect(fakeRepo.lastGetConversationsParams['page'], 1);
    });

    test('clearAllFilters resets all filters to clean state', () async {
      cubit.setAiAgentFilter(19);
      cubit.clearAllFilters();

      expect(cubit.state.selectedAssigneeAgentBotId, isNull);
      expect(cubit.state.selectedAssigneeId, isNull);
      expect(cubit.state.selectedInboxId, isNull);
      expect(cubit.state.selectedTeamId, isNull);
      expect(cubit.state.assigneeType, 'all');
    });

    test('onWorkspaceSwitched clears filters and re-fetches', () async {
      cubit.setAiAgentFilter(19);
      final initialCalls = fakeRepo.fetchFilterOptionsCallCount;
      await cubit.onWorkspaceSwitched(999);

      expect(cubit.state.selectedAssigneeAgentBotId, isNull);
      expect(cubit.state.selectedAssigneeId, isNull);
      expect(cubit.state.selectedInboxId, isNull);
      expect(cubit.state.page, 1);
      expect(fakeRepo.fetchFilterOptionsCallCount, greaterThan(initialCalls));
    });
  });
}
