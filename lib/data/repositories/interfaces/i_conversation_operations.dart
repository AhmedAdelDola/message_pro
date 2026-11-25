import 'package:dartz/dartz.dart';
import '../../../core/error/failures.dart';
import '../../models/conversation.dart';

abstract class IConversationOperations {
  Future<Either<Failure, List<Conversation>>> getConversations({
    String status = 'open',
    String assigneeType = 'me',
    int? inboxId,
    int? teamId,
    String? label,
    int? assigneeId,
    int? assigneeAgentBotId,
    int? lifecycleStageId,
    int page = 1,
  });

  Future<Either<Failure, List<Conversation>>> searchConversations(String query, {int page = 1});
  Future<Either<Failure, Conversation>> getConversation(int conversationId);

  Future<Either<Failure, Conversation>> startNewConversation({
    required int contactId,
    required int inboxId,
    required String sourceId,
    String? message,
  });

  Future<Either<Failure, Conversation>> startDirectChat({
    required String phoneNumber,
    required int inboxId,
    required String sourceId,
    String? contactName,
  });

  Future<Either<Failure, void>> toggleStatus(int conversationId, String status, {String? snoozedUntil});
  Future<Either<Failure, void>> assignAgent(int conversationId, int? agentId, {String? assigneeType});
  Future<Either<Failure, List<int>>> fetchPinnedConversationIds();
  Future<Either<Failure, void>> pinConversation(int conversationId);
  Future<Either<Failure, void>> unpinConversation(int conversationId);
  Future<Either<Failure, void>> assignTeam(int conversationId, int? teamId);
  Future<Either<Failure, void>> updateLabels(int conversationId, List<String> labels);
  Future<Either<Failure, void>> updateLifecycleStage(int conversationId, int stageId);
  Future<Either<Failure, void>> updateConversationCustomAttributes(int conversationId, Map<String, dynamic> customAttributes);
  Future<Either<Failure, void>> muteConversation(int conversationId);
  Future<Either<Failure, void>> unmuteConversation(int conversationId);
  Future<Either<Failure, void>> markAsRead(int conversationId);
  Future<List<Conversation>> getCachedConversations(int accountId) async => const [];
}
