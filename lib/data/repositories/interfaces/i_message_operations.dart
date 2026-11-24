import 'package:dartz/dartz.dart';
import '../../../core/error/failures.dart';
import '../../models/message.dart';
import '../../models/message_template.dart';

abstract class IMessageOperations {
  Future<Either<Failure, List<Message>>> getMessages(int conversationId, {int? beforeId, int? afterId});

  Future<Either<Failure, Message>> sendMessage({
    required int conversationId,
    required String content,
    bool isPrivate = false,
    List<String>? attachmentPaths,
    int? inReplyToId,
    String? echoId,
  });

  Future<Either<Failure, Message>> editMessage({
    required int conversationId,
    required int messageId,
    required String content,
  });

  Future<Either<Failure, Message>> deleteMessage({
    required int conversationId,
    required int messageId,
    bool everyone = true,
  });

  Future<Either<Failure, Message>> sendReaction({
    required int conversationId,
    required int messageId,
    required String emoji,
  });

  Future<Either<Failure, List<ReactionParticipant>>> getReactions({
    required int conversationId,
    required int messageId,
    Map<String, dynamic>? contentAttributes,
  });

  Future<Either<Failure, Message>> sendTemplateMessage({
    required int conversationId,
    required String templateName,
    required String category,
    required String language,
    required String content,
    Map<String, dynamic>? processedParams,
  });

  Future<Either<Failure, List<MessageTemplate>>> fetchInboxTemplates(int inboxId);
  Future<Either<Failure, List<MessageTemplate>>> fetchConversationTemplates(int conversationId);

  Future<Either<Failure, Message>> sendBrowserWhatsAppList({
    required int conversationId,
    required String templateId,
    required Map<String, dynamic> variables,
  });

  List<Message>? getCachedMessages(int conversationId) => null;
  Future<List<Message>> getLocalCachedMessages(int conversationId) async => const [];
  void clearCache() {}
}
