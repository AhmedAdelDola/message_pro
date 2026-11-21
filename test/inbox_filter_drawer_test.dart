import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:message_pro/core/error/failures.dart';
import 'package:message_pro/core/network/websocket_client.dart';
import 'package:message_pro/core/storage/secure_storage_service.dart';
import 'package:message_pro/data/models/contact.dart';
import 'package:message_pro/data/models/conversation.dart';
import 'package:message_pro/data/models/conversation_filter_options.dart';
import 'package:message_pro/data/models/message.dart';
import 'package:message_pro/data/models/user.dart';
import 'package:message_pro/data/repositories/auth_repository.dart';
import 'package:message_pro/data/repositories/conversation_repository.dart';
import 'package:message_pro/logic/auth/auth_cubit.dart';
import 'package:message_pro/logic/conversation/conversation_cubit.dart';
import 'package:message_pro/ui/screens/inbox/widgets/inbox_filter_drawer.dart';

class MockConversationRepository implements IConversationRepository {
  @override
  Future<Either<Failure, ConversationFilterOptions>> fetchFilterOptions() async {
    return Right(
      ConversationFilterOptions(
        inboxes: [
          Inbox(id: 101, name: 'WhatsApp Support', channelType: 'channel_whatsapp'),
          Inbox(id: 102, name: 'Facebook Sales', channelType: 'channel_facebook_page'),
        ],
        aiAgents: [
          const AiAgentItem(agentBotId: 501, name: 'Support Bot', description: 'Smart assistant'),
        ],
        agents: [
          User(
            id: 301,
            name: 'Ahmed Ali',
            email: 'ahmed@test.com',
            accountId: 1,
            role: 'agent',
          ),
        ],
        teams: [
          Team(id: 401, name: 'Support Team', description: 'Tier 1 support'),
        ],
        canFilterAgents: true,
      ),
    );
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
  }) async => const Right([]);

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
  Future<Either<Failure, List<Message>>> getMessages(int conversationId, {int? beforeId, int? afterId}) async => const Right([]);

  @override
  void clearCache() {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeAuthRepository implements IAuthRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeStorageService implements SecureStorageService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeActionCableClient implements ActionCableClient {
  @override
  Stream<RealtimeEvent> get events => const Stream<RealtimeEvent>.empty();

  @override
  Stream<void> get onReconnected => const Stream<void>.empty();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late ConversationCubit conversationCubit;
  late AuthCubit authCubit;

  setUp(() {
    final mockRepo = MockConversationRepository();
    final fakeWs = FakeActionCableClient();
    final fakeAuthRepo = FakeAuthRepository();
    final fakeStorage = FakeStorageService();

    conversationCubit = ConversationCubit(repo: mockRepo, ws: fakeWs);
    authCubit = AuthCubit(authRepo: fakeAuthRepo, storage: fakeStorage, ws: fakeWs);
  });

  tearDown(() {
    conversationCubit.close();
    authCubit.close();
  });

  Widget createWidgetUnderTest() {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (context, child) => MultiBlocProvider(
        providers: [
          BlocProvider<ConversationCubit>.value(value: conversationCubit),
          BlocProvider<AuthCubit>.value(value: authCubit),
        ],
        child: const MaterialApp(
          locale: Locale('ar'),
          localizationsDelegates: [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: [
            Locale('ar'),
            Locale('en'),
          ],
          home: Scaffold(
            body: InboxFilterDrawer(),
          ),
        ),
      ),
    );
  }

  testWidgets('InboxFilterDrawer removes Conversations and Status sections, shows collapsible channels, ai, employees, and teams', (tester) async {
    // Load filter options into cubit state
    await conversationCubit.loadFilterOptions();

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    // 1. Verify "المحادثات" and "حالة المحادثة" are REMOVED
    expect(find.text('المحادثات'), findsNothing);
    expect(find.text('جميع المحادثات'), findsNothing);
    expect(find.text('محادثاتي (خاصتي)'), findsNothing);
    expect(find.text('حالة المحادثة'), findsNothing);
    expect(find.text('مفتوحة'), findsNothing);
    expect(find.text('مكتملة'), findsNothing);

    // 2. Verify Collapsible sections are present
    expect(find.text('القنوات'), findsOneWidget);
    expect(find.text('وكلاء الذكاء الاصطناعي'), findsOneWidget);
    expect(find.text('الموظفين'), findsOneWidget);
    expect(find.text('فرق العمل'), findsOneWidget);

    // 3. Verify items inside sections are visible
    expect(find.text('WhatsApp Support'), findsOneWidget);
    expect(find.text('Facebook Sales'), findsOneWidget);
    expect(find.text('Support Bot'), findsOneWidget);
    expect(find.text('Ahmed Ali'), findsOneWidget);
    expect(find.text('Support Team'), findsOneWidget);

    // 4. Verify AI badge is present
    expect(find.text('AI'), findsOneWidget);

    // 5. Test collapsible interaction: tap on "القنوات" header to toggle collapse/expand
    await tester.tap(find.text('القنوات'));
    await tester.pumpAndSettle();

    // Tap again to re-expand
    await tester.tap(find.text('القنوات'));
    await tester.pumpAndSettle();
    expect(find.text('WhatsApp Support'), findsOneWidget);
  });
}
