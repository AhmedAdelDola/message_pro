import 'package:flutter/foundation.dart';
import '../../data/models/conversation.dart';
import '../../data/models/message.dart';

/// Top-level isolate worker for parsing conversations list in the background.
List<Conversation> parseConversationsInIsolate(List<dynamic> rawList) {
  final result = <Conversation>[];
  for (final item in rawList) {
    if (item is Map) {
      try {
        final conv = Conversation.fromJson(Map<String, dynamic>.from(item));
        if (conv.id > 0) {
          result.add(conv);
        }
      } catch (_) {}
    }
  }
  return result;
}

/// Top-level isolate worker for parsing messages list in the background.
List<Message> parseMessagesInIsolate(List<dynamic> rawList) {
  final result = <Message>[];
  for (final item in rawList) {
    if (item is Map) {
      try {
        result.add(Message.fromJson(Map<String, dynamic>.from(item)));
      } catch (_) {}
    }
  }
  return result;
}

/// Helper to execute heavy JSON parsing operations in a background isolate,
/// completely freeing the main UI thread to achieve consistent 60-120fps.
class BackgroundJsonParser {
  static Future<List<Conversation>> parseConversations(List<dynamic> rawList) async {
    if (rawList.isEmpty) return const [];
    if (kIsWeb || rawList.length < 5) {
      return parseConversationsInIsolate(rawList);
    }
    return compute(parseConversationsInIsolate, rawList);
  }

  static Future<List<Message>> parseMessages(List<dynamic> rawList) async {
    if (rawList.isEmpty) return const [];
    if (kIsWeb || rawList.length < 5) {
      return parseMessagesInIsolate(rawList);
    }
    return compute(parseMessagesInIsolate, rawList);
  }
}
