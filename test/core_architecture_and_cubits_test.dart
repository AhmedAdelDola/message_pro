import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:message_pro/data/models/contact.dart';
import 'package:message_pro/data/models/conversation.dart';
import 'package:message_pro/logic/conversation/services/conversation_filter_helper.dart';
import 'package:message_pro/ui/widgets/channel_logo_widget.dart';

void main() {
  group('Contact Model & OOP Tests', () {
    test('displayNameOrPhone falls back gracefully for generic names', () {
      final contact = Contact.fromJson({
        'id': 1,
        'name': 'New Visitor',
        'phone_number': '+201001234567',
      });
      expect(contact.displayNameOrPhone, equals('+201001234567'));

      final namedContact = Contact.fromJson({
        'id': 2,
        'name': 'Ahmed Ali',
        'phone_number': '+201001234567',
      });
      expect(namedContact.displayNameOrPhone, equals('Ahmed Ali'));
    });
  });

  group('ConversationFilterHelper Tests', () {
    test('sorts pinned conversations to top in all tab', () {
      final c1 = Conversation.fromJson({'id': 1, 'account_id': 10, 'inbox_id': 1, 'status': 'open', 'isPinned': false});
      final c2 = Conversation.fromJson({'id': 2, 'account_id': 10, 'inbox_id': 1, 'status': 'open', 'isPinned': true});
      final sorted = ConversationFilterHelper.applyFiltersAndSorting([c1, c2], isAllTab: true);
      expect(sorted.first.id, equals(2));
      expect(sorted.last.id, equals(1));
    });

    test('matchesStatusFilter respects all vs specific status', () {
      final openConv = Conversation.fromJson({'id': 1, 'account_id': 10, 'inbox_id': 1, 'status': 'open'});
      expect(ConversationFilterHelper.matchesStatusFilter(openConv, 'all'), isTrue);
      expect(ConversationFilterHelper.matchesStatusFilter(openConv, 'open'), isTrue);
      expect(ConversationFilterHelper.matchesStatusFilter(openConv, 'resolved'), isFalse);
    });
  });

  group('ChannelLogoWidget Tests', () {
    testWidgets('renders authentic Instagram CustomPaint and all channels without error', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Row(
              children: [
                ChannelLogoWidget(channelType: 'Channel::Whatsapp', size: 20),
                ChannelLogoWidget(channelType: 'Channel::FacebookPage', size: 20),
                ChannelLogoWidget(channelType: 'Channel::Instagram', size: 20),
                ChannelLogoWidget(channelType: 'Channel::Telegram', size: 20),
                ChannelLogoWidget(channelType: 'Channel::Email', size: 20),
                ChannelLogoWidget(channelType: 'Channel::WebWidget', size: 20),
              ],
            ),
          ),
        ),
      );
      expect(find.byType(ChannelLogoWidget), findsNWidgets(6));
      expect(find.byType(CustomPaint), findsWidgets);
    });
  });
}
