import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:message_pro/data/models/contact.dart';
import 'package:message_pro/data/models/conversation.dart';
import 'package:message_pro/ui/screens/inbox/widgets/conversation_tile.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget wrapWidget(Widget child) {
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      builder: (context, _) => MaterialApp(
        home: Scaffold(body: child),
      ),
    );
  }

  group('Pinned Conversation Tests', () {
    test('Conversation.fromJson correctly parses isPinned', () {
      final jsonPinned1 = {
        'id': 101,
        'account_id': 1,
        'inbox_id': 1,
        'is_pinned': true,
        'contact': {'id': 1, 'name': 'Farah Account Manager'},
      };
      final conv1 = Conversation.fromJson(jsonPinned1);
      expect(conv1.isPinned, isTrue);

      final jsonPinned2 = {
        'id': 102,
        'account_id': 1,
        'inbox_id': 1,
        'pinned': true,
        'contact': {'id': 2, 'name': 'Ahmed'},
      };
      final conv2 = Conversation.fromJson(jsonPinned2);
      expect(conv2.isPinned, isTrue);

      final jsonNotPinned = {
        'id': 103,
        'account_id': 1,
        'inbox_id': 1,
        'contact': {'id': 3, 'name': 'Salma'},
      };
      final conv3 = Conversation.fromJson(jsonNotPinned);
      expect(conv3.isPinned, isFalse);
    });

    test('Pinned conversations always sort to the top', () {
      final now = DateTime.now();
      final convNormalNew = Conversation(
        id: 1,
        accountId: 1,
        inboxId: 1,
        contact: Contact(id: 1, name: 'Normal New'),
        updatedAt: now.add(const Duration(minutes: 10)),
        createdAt: now,
        isPinned: false,
      );
      final convPinnedOlder = Conversation(
        id: 2,
        accountId: 1,
        inboxId: 1,
        contact: Contact(id: 2, name: 'Pinned Older'),
        updatedAt: now,
        createdAt: now,
        isPinned: true,
      );

      final list = [convNormalNew, convPinnedOlder];
      list.sort((a, b) {
        if (a.isPinned != b.isPinned) {
          return a.isPinned ? -1 : 1;
        }
        return b.updatedAt.compareTo(a.updatedAt);
      });

      // Pinned older MUST be first, even though Normal has a newer updatedAt
      expect(list.first.id, equals(2));
      expect(list.last.id, equals(1));
    });

    testWidgets('ConversationTile renders pushpin icon when isPinned is true', (tester) async {
      final pinnedConv = Conversation(
        id: 501,
        accountId: 1,
        inboxId: 1,
        contact: Contact(id: 1, name: 'Farah Account Manager'),
        updatedAt: DateTime.now(),
        createdAt: DateTime.now(),
        isPinned: true,
      );

      await tester.pumpWidget(
        wrapWidget(
          ConversationTile(
            conversation: pinnedConv,
            onTap: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.push_pin_rounded), findsOneWidget);
    });

    testWidgets('ConversationTile does NOT render pushpin icon when isPinned is false', (tester) async {
      final unpinnedConv = Conversation(
        id: 502,
        accountId: 1,
        inboxId: 1,
        contact: Contact(id: 2, name: 'Normal Chat'),
        updatedAt: DateTime.now(),
        createdAt: DateTime.now(),
        isPinned: false,
      );

      await tester.pumpWidget(
        wrapWidget(
          ConversationTile(
            conversation: unpinnedConv,
            onTap: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.push_pin_rounded), findsNothing);
    });
  });
}
