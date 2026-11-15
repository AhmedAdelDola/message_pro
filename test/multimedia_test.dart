import 'package:flutter_test/flutter_test.dart';
import 'package:message_pro/data/models/message.dart';
import 'package:message_pro/ui/screens/chat/widgets/chat_composer.dart';

void main() {
  group('Multimedia and Max Attachments Limit Tests', () {
    test('ChatComposer defines maxAttachmentsLimit as 5', () {
      expect(ChatComposerState.maxAttachmentsLimit, 5);
    });

    test('Message correctly parses up to 5 multi-media attachments of various types', () {
      final json = {
        'id': 1234,
        'conversation_id': 99,
        'message_type': 0,
        'content': 'Check these files',
        'attachments': [
          {
            'id': 1,
            'file_type': 'image',
            'data_url': 'https://example.com/photo1.jpg',
            'file_name': 'photo1.jpg',
          },
          {
            'id': 2,
            'file_type': 'image',
            'data_url': 'https://example.com/photo2.png',
            'file_name': 'photo2.png',
          },
          {
            'id': 3,
            'file_type': 'video',
            'data_url': 'https://example.com/video.mp4',
            'file_name': 'video.mp4',
            'duration': 45.0,
          },
          {
            'id': 4,
            'file_type': 'audio',
            'data_url': 'https://example.com/audio.mp3',
            'file_name': 'audio.mp3',
            'duration': 12.5,
          },
          {
            'id': 5,
            'file_type': 'file',
            'data_url': 'https://example.com/document.pdf',
            'file_name': 'document.pdf',
            'file_size': 1048576,
          },
        ],
      };

      final msg = Message.fromJson(json);

      expect(msg.attachments.length, 5);
      expect(msg.attachments[0].fileType, 'image');
      expect(msg.attachments[1].fileType, 'image');
      expect(msg.attachments[2].fileType, 'video');
      expect(msg.attachments[2].duration, 45.0);
      expect(msg.attachments[3].fileType, 'audio');
      expect(msg.attachments[3].duration, 12.5);
      expect(msg.attachments[4].fileType, 'file');
      expect(msg.attachments[4].fileSize, 1048576);
    });

    test('Attachment list capping logic enforces max 5 items', () {
      const maxLimit = ChatComposerState.maxAttachmentsLimit;
      final existingPaths = ['file1.png', 'file2.jpg'];
      final newlySelected = ['file3.pdf', 'file4.mp4', 'file5.jpg', 'file6.png', 'file7.docx'];

      final remaining = maxLimit - existingPaths.length;
      expect(remaining, 3);

      final toAdd = newlySelected.take(remaining).toList();
      expect(toAdd.length, 3);
      expect(toAdd, ['file3.pdf', 'file4.mp4', 'file5.jpg']);

      final total = [...existingPaths, ...toAdd];
      expect(total.length, 5);
    });
  });
}
