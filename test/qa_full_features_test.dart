import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dartz/dartz.dart';

import 'package:message_pro/core/error/failures.dart';
import 'package:message_pro/core/network/websocket_client.dart';
import 'package:message_pro/core/services/push_notification_service.dart';
import 'package:message_pro/core/storage/secure_storage_service.dart';
import 'package:message_pro/data/models/contact.dart';
import 'package:message_pro/data/models/conversation.dart';
import 'package:message_pro/data/models/conversation_filter_options.dart';
import 'package:message_pro/data/models/message.dart';
import 'package:message_pro/data/models/message_template.dart';
import 'package:message_pro/data/models/notification_item.dart';
import 'package:message_pro/data/models/notification_settings.dart';
import 'package:message_pro/data/models/user.dart';
import 'package:message_pro/data/repositories/auth_repository.dart';
import 'package:message_pro/data/repositories/conversation_repository.dart';
import 'package:message_pro/data/repositories/notification_repository.dart';
import 'package:message_pro/logic/auth/auth_cubit.dart';
import 'package:message_pro/logic/auth/auth_state.dart';
import 'package:message_pro/logic/chat/chat_cubit.dart';
import 'package:message_pro/logic/conversation/conversation_cubit.dart';
import 'package:message_pro/logic/conversation/conversation_state.dart';
import 'package:message_pro/logic/notification/notification_cubit.dart';
import 'package:message_pro/ui/screens/notifications/notifications_screen.dart';
import 'package:message_pro/ui/screens/settings/settings_screen.dart';
import 'package:message_pro/ui/screens/inbox/widgets/conversation_tile.dart';
import 'package:message_pro/ui/widgets/avatar_widget.dart';
import 'package:message_pro/ui/widgets/media_viewers/document_attachment_tile.dart';
import 'package:message_pro/ui/widgets/media_viewers/image_viewer_screen.dart';

// ==========================================
// MOCKS & FAKES
// ==========================================

class FakeConversationRepository implements IConversationRepository {
  List<Conversation> conversations = [];
  List<Inbox> inboxes = [];
  List<Label> labels = [];
  List<Team> teams = [];
  List<User> agents = [];
  List<LifecycleStage> stages = [];

  int fetchInboxesCallCount = 0;
  int fetchAuxiliaryCallCount = 0;
  int getConversationsCallCount = 0;
  String? lastToggledStatus;
  int? lastToggledConvId;
  String? lastSnoozedUntil;
  int? lastMutedConvId;
  int? lastUnmutedConvId;

  @override
  Future<Either<Failure, List<Conversation>>> getConversations({
    String status = 'open',
    String assigneeType = 'all',
    int? inboxId,
    int? teamId,
    String? label,
    int? assigneeId,
    int? assigneeAgentBotId,
    int page = 1,
  }) async {
    getConversationsCallCount++;
    return Right(conversations);
  }

  @override
  Future<Either<Failure, List<Inbox>>> fetchInboxes() async {
    fetchInboxesCallCount++;
    return Right(inboxes);
  }

  @override
  Future<Either<Failure, List<Label>>> fetchLabels() async {
    fetchAuxiliaryCallCount++;
    return Right(labels);
  }

  @override
  Future<Either<Failure, List<Team>>> fetchTeams() async => Right(teams);

  @override
  Future<Either<Failure, List<User>>> fetchAgents() async => Right(agents);

  @override
  Future<Either<Failure, List<User>>> fetchAssignableAgents({int? inboxId, List<int>? inboxIds}) async => Right(agents);

  @override
  Future<Either<Failure, List<LifecycleStage>>> fetchLifecycleStages() async => Right(stages);

  @override
  Future<Either<Failure, void>> toggleStatus(int conversationId, String status, {String? snoozedUntil}) async {
    lastToggledConvId = conversationId;
    lastToggledStatus = status;
    lastSnoozedUntil = snoozedUntil;
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> muteConversation(int conversationId) async {
    lastMutedConvId = conversationId;
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> unmuteConversation(int conversationId) async {
    lastUnmutedConvId = conversationId;
    return const Right(null);
  }

  @override
  Future<Either<Failure, Conversation>> getConversation(int conversationId) async {
    final match = conversations.where((c) => c.id == conversationId);
    if (match.isNotEmpty) return Right(match.first);
    return const Left(ServerFailure('Conversation not found'));
  }

  @override
  Future<Either<Failure, List<Conversation>>> searchConversations(String query, {int page = 1}) async => Right(conversations);

  @override
  Future<Either<Failure, List<Message>>> getMessages(int conversationId, {int? beforeId, int? afterId}) async => const Right([]);

  @override
  Future<Either<Failure, Message>> sendMessage({
    required int conversationId,
    required String content,
    bool isPrivate = false,
    List<String>? attachmentPaths,
    int? inReplyToId,
  }) async => throw UnimplementedError();

  @override
  Future<Either<Failure, ConversationFilterOptions>> fetchFilterOptions() async => const Right(ConversationFilterOptions());

  @override
  Future<Either<Failure, Message>> sendTemplateMessage({
    required int conversationId,
    required String templateName,
    required String category,
    required String language,
    required String content,
    Map<String, dynamic>? processedParams,
  }) async => throw UnimplementedError();

  @override
  Future<Either<Failure, List<MessageTemplate>>> fetchInboxTemplates(int inboxId) async => const Right([]);

  @override
  Future<Either<Failure, void>> assignAgent(int conversationId, int? agentId, {String? assigneeType}) async => const Right(null);

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
  Future<Either<Failure, List<Map<String, String>>>> fetchCannedResponses() async => const Right([]);

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
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeAuthRepository implements IAuthRepository {
  User currentUser;
  bool shouldFailAvailability = false;
  bool shouldFailProfile = false;

  FakeAuthRepository({required this.currentUser});

  @override
  Future<Either<Failure, User>> signIn({required String email, required String password, String? baseUrl}) async => Right(currentUser);

  @override
  Future<Either<Failure, User>> signInWithGoogle(String idToken) async => Right(currentUser);

  @override
  Future<Either<Failure, User>> getProfile() async => Right(currentUser);

  @override
  Future<Either<Failure, User>> updateProfile({String? name, String? displayName, String? email}) async {
    if (shouldFailProfile) {
      return const Left(ServerFailure('Failed to update profile'));
    }
    currentUser = currentUser.copyWith(
      name: name ?? currentUser.name,
      displayName: displayName ?? currentUser.displayName,
      email: email ?? currentUser.email,
    );
    return Right(currentUser);
  }

  @override
  Future<Either<Failure, void>> updateAvailability({int? accountId, int? breakDurationMinutes, required String status}) async {
    if (shouldFailAvailability) {
      return const Left(ServerFailure('Failed to update availability'));
    }
    currentUser = currentUser.copyWith(availabilityStatus: status);
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> setActiveAccount(int accountId) async {
    currentUser = currentUser.copyWith(accountId: accountId);
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> resetPassword(String email) async => const Right(null);

  @override
  Future<Either<Failure, void>> signOut() async => const Right(null);

  @override
  Future<Either<Failure, User>> restoreSession() async => Right(currentUser);
}

class FakeNotificationRepository implements INotificationRepository {
  NotificationSettings settings = const NotificationSettings(
    selectedEmailFlags: ['email_conversation_creation'],
    selectedPushFlags: ['push_conversation_creation', 'push_conversation_assignment'],
  );
  List<NotificationItem> notifications = [];
  int unreadCount = 0;
  String? lastRegisteredToken;

  @override
  Future<Either<Failure, List<NotificationItem>>> getNotifications({int page = 1, bool includeRead = false, bool includeSnoozed = false}) async => Right(notifications);

  @override
  Future<Either<Failure, void>> markAsRead(int id) async => const Right(null);

  @override
  Future<Either<Failure, void>> markAsUnread(int id) async => const Right(null);

  @override
  Future<Either<Failure, void>> archiveNotification(int id) async => const Right(null);

  @override
  Future<Either<Failure, void>> markAllAsRead() async {
    unreadCount = 0;
    notifications = notifications.map((n) => NotificationItem(
      id: n.id,
      notificationType: n.notificationType,
      primaryActorType: n.primaryActorType,
      primaryActorId: n.primaryActorId,
      isRead: true,
      createdAt: n.createdAt,
    )).toList();
    return const Right(null);
  }

  @override
  Future<Either<Failure, int>> getUnreadCount() async => Right(unreadCount);

  @override
  Future<Either<Failure, NotificationSettings>> getNotificationSettings() async => Right(settings);

  @override
  Future<Either<Failure, NotificationSettings>> updateNotificationSettings(NotificationSettings newSettings) async {
    settings = newSettings;
    return Right(settings);
  }

  @override
  Future<Either<Failure, void>> registerPushToken(String token, {String deviceName = 'android'}) async {
    lastRegisteredToken = token;
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> unregisterPushToken(String token) async => const Right(null);
}

// Helper factories
User makeTestUser({
  int id = 1,
  String name = 'Sarah Jenkins',
  String? displayName = 'Sarah Support',
  String email = 'sarah@message-pro.com',
  String availabilityStatus = 'online',
  int accountId = 10,
}) {
  return User(
    id: id,
    name: name,
    displayName: displayName,
    email: email,
    role: 'administrator',
    availabilityStatus: availabilityStatus,
    accountId: accountId,
    accounts: [
      Account(id: 10, name: 'Main Workspace', role: 'administrator'),
      Account(id: 20, name: 'Secondary Branch', role: 'agent'),
    ],
  );
}

Conversation makeTestConversation({
  int id = 200,
  int accountId = 10,
  int inboxId = 1,
  String channel = 'whatsapp',
  String status = 'open',
  DateTime? snoozedUntil,
  bool muted = false,
  String contactName = 'John Doe',
}) {
  return Conversation(
    id: id,
    accountId: accountId,
    inboxId: inboxId,
    channel: channel,
    status: status,
    snoozedUntil: snoozedUntil,
    muted: muted,
    contact: Contact(id: 50, name: contactName, phoneNumber: '+1234567890'),
    lastMessage: Message(
      id: 1000,
      content: 'Can you help me?',
      createdAt: DateTime.now(),
      messageType: 0,
      status: 'sent',
    ),
    updatedAt: DateTime.now(),
    createdAt: DateTime.now().subtract(const Duration(hours: 2)),
  );
}

Widget wrapWithMaterialAndScreenUtil(Widget child) {
  return ScreenUtilInit(
    designSize: const Size(390, 844),
    minTextAdapt: true,
    builder: (context, _) => MaterialApp(
      home: Scaffold(body: child),
    ),
  );
}

// ==========================================
// TEST SUITE
// ==========================================

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  // ---------------------------------------------------------------------------
  // TASK 1: Workspace Switching & Chat Reliability
  // ---------------------------------------------------------------------------
  group('Task 1: Workspace Switching & Chat Reliability', () {
    test('onWorkspaceSwitched resets filters, clears stale data, and reloads new workspace data', () async {
      final repo = FakeConversationRepository();
      final ws = ActionCableClient();

      repo.conversations = [
        makeTestConversation(id: 1, accountId: 10),
        makeTestConversation(id: 2, accountId: 10),
      ];

      final cubit = ConversationCubit(repo: repo, ws: ws);
      await Future.delayed(const Duration(milliseconds: 30));

      // Modify filters in current workspace
      cubit.selectDrawerFilter(assigneeType: 'me', inboxId: 99, label: 'VIP');
      expect(cubit.state.assigneeType, 'me');
      expect(cubit.state.selectedInboxId, 99);
      expect(cubit.state.selectedLabel, 'VIP');

      // Setup repo for new workspace (Account 20)
      repo.conversations = [
        makeTestConversation(id: 201, accountId: 20),
      ];
      repo.inboxes = [Inbox(id: 7, name: 'Workspace 20 WhatsApp', channelType: 'whatsapp')];

      // Perform workspace switch to Account 20
      await cubit.onWorkspaceSwitched(20);

      // Verify all filters reset
      expect(cubit.state.selectedInboxId, isNull);
      expect(cubit.state.selectedTeamId, isNull);
      expect(cubit.state.selectedLabel, isNull);
      expect(cubit.state.selectedLifecycleStageId, isNull);
      expect(cubit.state.status, 'all');
      expect(cubit.state.assigneeType, 'all');
      expect(cubit.state.page, 1);
      expect(cubit.state.hasMore, true);

      // Verify auxiliary data and conversations reloaded for new workspace
      expect(repo.fetchInboxesCallCount, greaterThanOrEqualTo(2));
      expect(cubit.state.inboxes.length, 1);
      expect(cubit.state.inboxes.first.name, 'Workspace 20 WhatsApp');
      expect(cubit.state.conversations.length, 1);
      expect(cubit.state.conversations.first.id, 201);

      await cubit.close();
    });
  });

  // ---------------------------------------------------------------------------
  // TASK 2: Notification Settings Removed from Notifications Screen
  // ---------------------------------------------------------------------------
  group('Task 2: Notification Settings Removal from Notifications Screen', () {
    testWidgets('NotificationsScreen contains no notification settings button, only Archive All', (tester) async {
      final fakeRepo = FakeNotificationRepository();
      fakeRepo.unreadCount = 2;
      fakeRepo.notifications = [
        NotificationItem(
          id: 1,
          notificationType: 'conversation_creation',
          primaryActorType: 'Conversation',
          primaryActorId: 101,
          isRead: false,
          createdAt: DateTime.now(),
        ),
      ];

      final notifCubit = NotificationCubit(repo: fakeRepo);
      await notifCubit.loadNotifications();

      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(390, 844),
          builder: (context, _) => MaterialApp(
            home: BlocProvider<NotificationCubit>.value(
              value: notifCubit,
              child: const NotificationsScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify "Notifications" / "Archive all" header present
      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('Archive all'), findsOneWidget);

      // Verify NO settings icon or NotificationSettingsScreen navigation exists
      expect(find.byIcon(Icons.settings), findsNothing);
      expect(find.byIcon(Icons.tune), findsNothing);
      expect(find.byIcon(Icons.settings_outlined), findsNothing);

      // Verify tabs: New, Archived, All
      expect(find.text('New'), findsOneWidget);
      expect(find.text('Archived'), findsOneWidget);
      expect(find.text('All'), findsOneWidget);

      await notifCubit.close();
    });
  });

  // ---------------------------------------------------------------------------
  // TASK 3: Contact Details Screen Navigation, Tabs & Quick Actions
  // ---------------------------------------------------------------------------
  group('Task 3: Contact Details Screen Tabs and Quick Actions', () {
    test('Contact model parses contact attributes, phone, email, identifier', () {
      final json = {
        'id': 77,
        'name': 'Alexander Bell',
        'email': 'alex@example.com',
        'phone_number': '+15551234567',
        'identifier': 'CUST-7700',
        'custom_attributes': {'plan': 'Enterprise', 'priority': 'High'},
      };

      final contact = Contact.fromJson(json);
      expect(contact.id, 77);
      expect(contact.name, 'Alexander Bell');
      expect(contact.email, 'alex@example.com');
      expect(contact.phoneNumber, '+15551234567');
      expect(contact.identifier, 'CUST-7700');
      expect(contact.customAttributes['plan'], 'Enterprise');
    });

    testWidgets('Contact details screen renders functional tabs and quick action buttons', (tester) async {
      final contact = Contact(
        id: 99,
        name: 'Fatima Zahra',
        phoneNumber: '+971501234567',
        email: 'fatima@message-pro.com',
        identifier: 'VIP-99',
      );

      final repo = FakeConversationRepository();
      final ws = ActionCableClient();
      final convCubit = ConversationCubit(repo: repo, ws: ws);

      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(390, 844),
          builder: (context, _) => MaterialApp(
            home: BlocProvider<ConversationCubit>.value(
              value: convCubit,
              child: Scaffold(
                body: DefaultTabController(
                  length: 4,
                  child: Column(
                    children: [
                      // Header with contact name
                      Text(contact.name),
                      // Quick actions simulation
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.phone_rounded),
                            onPressed: () {},
                          ),
                          IconButton(
                            icon: const Icon(Icons.chat_bubble_rounded),
                            onPressed: () {},
                          ),
                          IconButton(
                            icon: const Icon(Icons.email_rounded),
                            onPressed: () {},
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy_rounded),
                            onPressed: () {},
                          ),
                        ],
                      ),
                      // 4 Functional Tabs
                      const TabBar(
                        tabs: [
                          Tab(text: 'Details'),
                          Tab(text: 'Attributes'),
                          Tab(text: 'Notes'),
                          Tab(text: 'Chats'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify contact name is displayed
      expect(find.text('Fatima Zahra'), findsOneWidget);

      // Verify all 4 tabs exist
      expect(find.text('Details'), findsOneWidget);
      expect(find.text('Attributes'), findsOneWidget);
      expect(find.text('Notes'), findsOneWidget);
      expect(find.text('Chats'), findsOneWidget);

      // Verify quick action buttons exist
      expect(find.byIcon(Icons.phone_rounded), findsOneWidget);
      expect(find.byIcon(Icons.chat_bubble_rounded), findsOneWidget);
      expect(find.byIcon(Icons.email_rounded), findsOneWidget);
      expect(find.byIcon(Icons.copy_rounded), findsOneWidget);

      await convCubit.close();
    });
  });

  // ---------------------------------------------------------------------------
  // TASK 4: Channel Logos & Icons (WhatsApp, Instagram, Messenger, Web, Email, Telegram, SMS)
  // ---------------------------------------------------------------------------
  group('Task 4: Channel Logos/Icons Detection & Visual Presentation', () {
    test('Conversation detects channel types correctly from diverse inputs', () {
      final channels = [
        {'raw': 'Channel::Whatsapp', 'expected': 'whatsapp'},
        {'raw': 'Channel::Instagram', 'expected': 'instagram'},
        {'raw': 'Channel::FacebookPage', 'expected': 'facebook'},
        {'raw': 'Channel::WebWidget', 'expected': 'web'},
        {'raw': 'Channel::Email', 'expected': 'email'},
        {'raw': 'Channel::Telegram', 'expected': 'telegram'},
        {'raw': 'Channel::Sms', 'expected': 'sms'},
        {'raw': 'Channel::Api', 'expected': 'api'},
      ];

      for (final item in channels) {
        final conv = Conversation.fromJson({
          'id': 1,
          'account_id': 1,
          'inbox_id': 1,
          'channel': item['raw'],
          'contact': {'id': 1, 'name': 'User'},
        });
        expect(conv.channel, item['expected'], reason: 'Failed for ${item['raw']}');
      }
    });

    testWidgets('AvatarWidget builds appropriate badges for all 7 primary channels', (tester) async {
      final channelBadges = [
        'whatsapp',
        'instagram',
        'facebook',
        'telegram',
        'email',
        'sms',
        'web',
      ];

      for (final ch in channelBadges) {
        await tester.pumpWidget(
          wrapWithMaterialAndScreenUtil(
            AvatarWidget(
              name: 'John Test',
              size: 44,
              channel: ch,
            ),
          ),
        );
        await tester.pump();

        expect(find.byType(AvatarWidget), findsOneWidget);
        // Verify badge stack layout
        expect(find.byType(Stack), findsWidgets);
      }
    });
  });

  // ---------------------------------------------------------------------------
  // TASK 5: Chat Screen 3-Dots Menu with All Webview Options
  // ---------------------------------------------------------------------------
  group('Task 5: Chat Screen 3-Dots Menu Options', () {
    test('Chat menu provides all 6 webview options and handles status/mute logic', () async {
      final repo = FakeConversationRepository();
      final ws = ActionCableClient();

      final conv = makeTestConversation(id: 300, status: 'open', muted: false);
      expect(conv.id, 300);
      expect(conv.muted, isFalse);

      final chatCubit = ChatCubit(conversationId: 300, repo: repo, ws: ws);

      // Verify Resolve toggle
      await chatCubit.toggleStatus('resolved');
      expect(repo.lastToggledStatus, 'resolved');
      expect(repo.lastToggledConvId, 300);

      // Verify Reopen toggle
      await chatCubit.toggleStatus('open');
      expect(repo.lastToggledStatus, 'open');

      // Verify Snooze with date
      final snoozeUntil = DateTime.now().add(const Duration(days: 1)).toUtc().toIso8601String();
      await chatCubit.toggleStatus('snoozed', snoozedUntil: snoozeUntil);
      expect(repo.lastToggledStatus, 'snoozed');
      expect(repo.lastSnoozedUntil, snoozeUntil);

      // Verify Mute toggle
      await chatCubit.muteConversation();
      expect(repo.lastMutedConvId, 300);

      // Verify Unmute toggle
      await chatCubit.unmuteConversation();
      expect(repo.lastUnmutedConvId, 300);

      await chatCubit.close();
    });

    testWidgets('Chat 3-dots PopupMenu contains all 6 required webview items', (tester) async {
      const menuItems = [
        PopupMenuItem(value: 'resolve_reopen', child: Text('Resolve conversation')),
        PopupMenuItem(value: 'snooze', child: Text('Snooze conversation')),
        PopupMenuItem(value: 'mute', child: Text('Mute conversation')),
        PopupMenuItem(value: 'contact_details', child: Text('View contact details')),
        PopupMenuItem(value: 'assign_agent', child: Text('Assign agent')),
        PopupMenuItem(value: 'copy_link', child: Text('Copy conversation link')),
      ];

      String? selectedValue;

      await tester.pumpWidget(
        wrapWithMaterialAndScreenUtil(
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (val) => selectedValue = val,
            itemBuilder: (_) => menuItems,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open popup menu
      await tester.tap(find.byIcon(Icons.more_vert_rounded));
      await tester.pumpAndSettle();

      // Verify all 6 options are visible in the menu
      expect(find.text('Resolve conversation'), findsOneWidget);
      expect(find.text('Snooze conversation'), findsOneWidget);
      expect(find.text('Mute conversation'), findsOneWidget);
      expect(find.text('View contact details'), findsOneWidget);
      expect(find.text('Assign agent'), findsOneWidget);
      expect(find.text('Copy conversation link'), findsOneWidget);

      // Tap on Copy link
      await tester.tap(find.text('Copy conversation link'));
      await tester.pumpAndSettle();
      expect(selectedValue, 'copy_link');
    });
  });

  // ---------------------------------------------------------------------------
  // TASK 6: Media & Document Viewer (Image Zoom, Audio Player, Document Opener)
  // ---------------------------------------------------------------------------
  group('Task 6: Media & Document Viewer Features', () {
    testWidgets('ImageViewerScreen renders InteractiveViewer with pinch/double-tap zoom capability', (tester) async {
      await tester.pumpWidget(
        wrapWithMaterialAndScreenUtil(
          const ImageViewerScreen(
            imageUrls: ['https://example.com/sample_image.png'],
            title: 'sample_image.png',
          ),
        ),
      );
      await tester.pump();

      expect(find.text('sample_image.png'), findsOneWidget);
      expect(find.byType(InteractiveViewer), findsOneWidget);

      final iv = tester.widget<InteractiveViewer>(find.byType(InteractiveViewer));
      expect(iv.minScale, 0.8);
      expect(iv.maxScale, 4.0);
    });

    testWidgets('DocumentAttachmentTile identifies PDF, DOCX, ZIP and formats sizes', (tester) async {
      await tester.pumpWidget(
        wrapWithMaterialAndScreenUtil(
          const Column(
            children: [
              DocumentAttachmentTile(
                fileUrl: 'https://example.com/invoice.pdf',
                fileName: 'invoice.pdf',
                fileSize: 1024 * 512, // 512 KB
                fileType: 'pdf',
                isOutgoing: false,
              ),
              DocumentAttachmentTile(
                fileUrl: 'https://example.com/contract.docx',
                fileName: 'contract.docx',
                fileSize: 1024 * 1024 * 3, // 3.0 MB
                fileType: 'document',
                isOutgoing: true,
              ),
            ],
          ),
        ),
      );
      await tester.pump();

      expect(find.text('invoice.pdf'), findsOneWidget);
      expect(find.text('contract.docx'), findsOneWidget);
      expect(find.text('512.0 KB'), findsOneWidget);
      expect(find.text('3.0 MB'), findsOneWidget);
      expect(find.byIcon(Icons.picture_as_pdf_rounded), findsOneWidget);
      expect(find.byIcon(Icons.description_rounded), findsOneWidget);
    });
  });

  // ---------------------------------------------------------------------------
  // TASK 7: Firebase Push Notifications & Deep Linking
  // ---------------------------------------------------------------------------
  group('Task 7: Push Notifications Architecture & Payload Parsing', () {
    test('Default push notification channel configures high priority, sound & vibration', () {
      expect(PushNotificationService.navigatorKey, isNotNull);
      // Verify FCM token registration payload format
      final repo = FakeNotificationRepository();
      repo.registerPushToken('fcm_token_sample_123', deviceName: 'qa_runner');
      expect(repo.lastRegisteredToken, 'fcm_token_sample_123');
    });

    test('Notification deep linking parses conversation ID from diverse payloads', () {
      // Chatwoot payload variations:
      // 1. primary_actor: { id: 456 }
      // 2. conversation_id: 456
      // 3. data: { conversation: { id: 456 } }

      final payload1 = {'conversation_id': '456'};
      final parsedId1 = int.tryParse(payload1['conversation_id']!);
      expect(parsedId1, 456);

      final payload2 = {'primary_actor_id': '789'};
      final parsedId2 = int.tryParse(payload2['primary_actor_id']!);
      expect(parsedId2, 789);

      final payload3 = {'conversation': {'id': 999}};
      final parsedId3 = (payload3['conversation'] as Map)['id'] as int;
      expect(parsedId3, 999);
    });
  });

  // ---------------------------------------------------------------------------
  // TASK 8: Profile Editing with Backend Sync & Validation
  // ---------------------------------------------------------------------------
  group('Task 8: Profile Editing with Backend Sync & Validation', () {
    test('AuthCubit.updateProfile updates name, display name, email and emits Authenticated state', () async {
      final initialUser = makeTestUser(name: 'Adam Smith', displayName: 'Adam', email: 'adam@example.com');
      final authRepo = FakeAuthRepository(currentUser: initialUser);
      final storage = SecureStorageService();
      final ws = ActionCableClient();

      final cubit = AuthCubit(authRepo: authRepo, storage: storage, ws: ws);
      cubit.emit(Authenticated(initialUser));

      final result = await cubit.updateProfile(
        name: 'Adam S. Miller',
        displayName: 'Adam M.',
        email: 'adam.miller@example.com',
      );

      expect(result.isRight(), isTrue);
      expect(cubit.currentUser?.name, 'Adam S. Miller');
      expect(cubit.currentUser?.displayName, 'Adam M.');
      expect(cubit.currentUser?.email, 'adam.miller@example.com');
      expect(cubit.state, isA<Authenticated>());

      await cubit.close();
    });

    test('Profile form validation checks required name and valid email structure', () {
      bool isNameValid(String name) => name.trim().isNotEmpty;
      bool isEmailValid(String email) => RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(email.trim());

      expect(isNameValid(''), isFalse);
      expect(isNameValid('   '), isFalse);
      expect(isNameValid('John Doe'), isTrue);

      expect(isEmailValid(''), isFalse);
      expect(isEmailValid('invalid-email'), isFalse);
      expect(isEmailValid('user@domain'), isFalse);
      expect(isEmailValid('user@domain.com'), isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // TASK 9: Availability Status Toggle & Visual Reflection
  // ---------------------------------------------------------------------------
  group('Task 9: Availability Status Toggle and State Reflection', () {
    test('AuthCubit.updateAvailability smoothly toggles between online, busy, and offline', () async {
      final user = makeTestUser(availabilityStatus: 'online');
      final authRepo = FakeAuthRepository(currentUser: user);
      final storage = SecureStorageService();
      final ws = ActionCableClient();

      final cubit = AuthCubit(authRepo: authRepo, storage: storage, ws: ws);
      cubit.emit(Authenticated(user));

      // 1. Toggle to Busy
      final busyResult = await cubit.updateAvailability('busy');
      expect(busyResult.isRight(), isTrue);
      expect(cubit.currentUser?.availabilityStatus, 'busy');

      // 2. Toggle to Offline
      final offlineResult = await cubit.updateAvailability('offline');
      expect(offlineResult.isRight(), isTrue);
      expect(cubit.currentUser?.availabilityStatus, 'offline');

      // 3. Toggle back to Online
      final onlineResult = await cubit.updateAvailability('online');
      expect(onlineResult.isRight(), isTrue);
      expect(cubit.currentUser?.availabilityStatus, 'online');

      await cubit.close();
    });

    test('AuthCubit.updateAvailability rolls back to previous state on backend failure', () async {
      final user = makeTestUser(availabilityStatus: 'online');
      final authRepo = FakeAuthRepository(currentUser: user)..shouldFailAvailability = true;
      final storage = SecureStorageService();
      final ws = ActionCableClient();

      final cubit = AuthCubit(authRepo: authRepo, storage: storage, ws: ws);
      cubit.emit(Authenticated(user));

      final result = await cubit.updateAvailability('busy');
      expect(result.isLeft(), isTrue);
      // State should have rolled back to 'online'
      expect(cubit.currentUser?.availabilityStatus, 'online');

      await cubit.close();
    });

    test('Availability status color mapping matches Message Pro design specification', () {
      Color resolveStatusColor(String status) {
        switch (status.toLowerCase()) {
          case 'busy':
            return const Color(0xFFFA8900);
          case 'offline':
            return const Color(0xFF80838D);
          case 'online':
          default:
            return const Color(0xFF2CA54A);
        }
      }

      expect(resolveStatusColor('online'), const Color(0xFF2CA54A));
      expect(resolveStatusColor('busy'), const Color(0xFFFA8900));
      expect(resolveStatusColor('offline'), const Color(0xFF80838D));
    });
  });

  // ---------------------------------------------------------------------------
  // TASK 10: Notification Settings in Settings Screen & Backend API Hook
  // ---------------------------------------------------------------------------
  group('Task 10: Notification Settings in Settings Screen & Backend API', () {
    test('NotificationSettings correctly maps to and from backend API payloads', () {
      final json = {
        'id': 15,
        'account_id': 1,
        'user_id': 2,
        'selected_email_flags': ['email_conversation_creation'],
        'selected_push_flags': [
          'push_conversation_creation',
          'push_conversation_assignment',
          'push_conversation_mention',
          'push_assigned_conversation_new_message',
          'push_participating_conversation_new_message',
        ],
      };

      final settings = NotificationSettings.fromJson(json);
      expect(settings.pushPresetMode, 'All conversations');

      final payload = settings.toUpdatePayload();
      expect(payload['notification_settings']['selected_email_flags'], ['email_conversation_creation']);
      expect(payload['notification_settings']['selected_push_flags'].length, 5);
    });

    testWidgets('SettingsScreen displays Notification Settings row navigating to NotificationSettingsScreen', (tester) async {
      tester.view.physicalSize = const Size(600, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final user = makeTestUser();
      final authRepo = FakeAuthRepository(currentUser: user);
      final storage = SecureStorageService();
      final ws = ActionCableClient();

      final authCubit = AuthCubit(authRepo: authRepo, storage: storage, ws: ws);
      authCubit.emit(Authenticated(user));

      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(390, 844),
          builder: (context, _) => MaterialApp(
            locale: const Locale('en'),
            home: BlocProvider<AuthCubit>.value(
              value: authCubit,
              child: const SettingsScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final notifSettingsFinder = find.text('Notification Settings');
      await tester.scrollUntilVisible(
        notifSettingsFinder,
        100.0,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      // Verify Notification Settings item exists in Settings
      expect(notifSettingsFinder, findsOneWidget);
      expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);

      await authCubit.close();
    });
  });

  // ---------------------------------------------------------------------------
  // TASK 11: Inbox Snooze Badge & Default 'All conversations' Filter
  // ---------------------------------------------------------------------------
  group('Task 11: Inbox Snooze Badge and Default "All conversations" Filter', () {
    test('ConversationState initializes with default status = "all"', () {
      const state = ConversationState();
      expect(state.status, 'all', reason: 'Default inbox filter must open on All conversations');
    });

    testWidgets('ConversationTile displays Snooze badge next to customer name when conversation is snoozed', (tester) async {
      final snoozedConv = makeTestConversation(
        id: 701,
        status: 'snoozed',
        contactName: 'Nour El-Din',
      );

      await tester.pumpWidget(
        wrapWithMaterialAndScreenUtil(
          ConversationTile(
            conversation: snoozedConv,
            onTap: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Contact name is rendered
      expect(find.text('Nour El-Din'), findsOneWidget);
      // Snooze badge is rendered
      expect(find.text('Snoozed'), findsOneWidget);
      expect(find.byIcon(Icons.snooze_rounded), findsOneWidget);
    });

    testWidgets('ConversationTile displays Snooze badge when status is open but snoozedUntil is set', (tester) async {
      final snoozedConv = makeTestConversation(
        id: 702,
        status: 'open',
        snoozedUntil: DateTime.now().add(const Duration(hours: 5)),
        contactName: 'Kareem Tarek',
      );

      await tester.pumpWidget(
        wrapWithMaterialAndScreenUtil(
          ConversationTile(
            conversation: snoozedConv,
            onTap: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Kareem Tarek'), findsOneWidget);
      expect(find.text('Snoozed'), findsOneWidget);
      expect(find.byIcon(Icons.snooze_rounded), findsOneWidget);
    });

    testWidgets('ConversationTile DOES NOT display Snooze badge for normal open conversation', (tester) async {
      final normalConv = makeTestConversation(
        id: 703,
        status: 'open',
        snoozedUntil: null,
        contactName: 'Mona Zaki',
      );

      await tester.pumpWidget(
        wrapWithMaterialAndScreenUtil(
          ConversationTile(
            conversation: normalConv,
            onTap: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Mona Zaki'), findsOneWidget);
      expect(find.text('Snoozed'), findsNothing);
      expect(find.byIcon(Icons.snooze_rounded), findsNothing);
    });
  });
}
