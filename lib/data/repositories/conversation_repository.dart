import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../core/network/api_client.dart';
import '../models/conversation.dart';
import '../models/message.dart';
import '../models/contact.dart';
import '../models/user.dart';
import '../models/message_template.dart';
import '../models/conversation_filter_options.dart';
import '../models/workflow.dart';
import 'interfaces/i_conversation_operations.dart';
import 'interfaces/i_message_operations.dart';
import 'interfaces/i_metadata_operations.dart';
import 'interfaces/i_collaborator_operations.dart';
import 'services/conversation_operations_service.dart';
import 'services/message_operations_service.dart';
import 'services/metadata_operations_service.dart';
import 'services/collaborator_operations_service.dart';

export 'interfaces/i_conversation_operations.dart';
export 'interfaces/i_message_operations.dart';
export 'interfaces/i_metadata_operations.dart';
export 'interfaces/i_collaborator_operations.dart';

/// Unified interface implementing segregated operations for ISP (Interface Segregation Principle) compliance.
abstract class IConversationRepository implements
    IConversationOperations,
    IMessageOperations,
    IMetadataOperations,
    ICollaboratorOperations {}

/// Composite repository adhering to Composition Over Inheritance.
/// Delegates operations to focused, single-responsibility services.
class ConversationRepository implements IConversationRepository {
  final IConversationOperations _conversationOps;
  final IMessageOperations _messageOps;
  final IMetadataOperations _metadataOps;
  final ICollaboratorOperations _collaboratorOps;

  ConversationRepository({
    ApiClient? api,
    IConversationOperations? conversationOps,
    IMessageOperations? messageOps,
    IMetadataOperations? metadataOps,
    ICollaboratorOperations? collaboratorOps,
  })  : _conversationOps = conversationOps ?? ConversationOperationsService(api: api),
        _messageOps = messageOps ?? MessageOperationsService(api: api),
        _metadataOps = metadataOps ?? MetadataOperationsService(api: api),
        _collaboratorOps = collaboratorOps ?? CollaboratorOperationsService(api: api);

  // ---------------------------------------------------------------------------
  // Message Operations Delegation
  // ---------------------------------------------------------------------------
  @override
  void clearCache() => _messageOps.clearCache();

  @override
  List<Message>? getCachedMessages(int conversationId) => _messageOps.getCachedMessages(conversationId);

  @override
  Future<List<Message>> getLocalCachedMessages(int conversationId) => _messageOps.getLocalCachedMessages(conversationId);

  @override
  Future<List<Conversation>> getCachedConversations(int accountId) => _conversationOps.getCachedConversations(accountId);

  @override
  Future<Either<Failure, List<Message>>> getMessages(
    int conversationId, {
    int? beforeId,
    int? afterId,
  }) =>
      _messageOps.getMessages(conversationId, beforeId: beforeId, afterId: afterId);

  @override
  Future<Either<Failure, Message>> sendMessage({
    required int conversationId,
    required String content,
    bool isPrivate = false,
    List<String>? attachmentPaths,
    int? inReplyToId,
    String? echoId,
  }) =>
      _messageOps.sendMessage(
        conversationId: conversationId,
        content: content,
        isPrivate: isPrivate,
        attachmentPaths: attachmentPaths,
        inReplyToId: inReplyToId,
        echoId: echoId,
      );

  @override
  Future<Either<Failure, Message>> sendTemplateMessage({
    required int conversationId,
    required String templateName,
    required String category,
    required String language,
    required String content,
    Map<String, dynamic>? processedParams,
  }) =>
      _messageOps.sendTemplateMessage(
        conversationId: conversationId,
        templateName: templateName,
        category: category,
        language: language,
        content: content,
        processedParams: processedParams,
      );

  @override
  Future<Either<Failure, Message>> editMessage({
    required int conversationId,
    required int messageId,
    required String content,
  }) =>
      _messageOps.editMessage(
        conversationId: conversationId,
        messageId: messageId,
        content: content,
      );

  @override
  Future<Either<Failure, Message>> deleteMessage({
    required int conversationId,
    required int messageId,
    bool everyone = true,
  }) =>
      _messageOps.deleteMessage(
        conversationId: conversationId,
        messageId: messageId,
        everyone: everyone,
      );

  @override
  Future<Either<Failure, Message>> sendReaction({
    required int conversationId,
    required int messageId,
    required String emoji,
  }) =>
      _messageOps.sendReaction(
        conversationId: conversationId,
        messageId: messageId,
        emoji: emoji,
      );

  @override
  Future<Either<Failure, List<ReactionParticipant>>> getReactions({
    required int conversationId,
    required int messageId,
    Map<String, dynamic>? contentAttributes,
  }) =>
      _messageOps.getReactions(
        conversationId: conversationId,
        messageId: messageId,
        contentAttributes: contentAttributes,
      );

  @override
  Future<Either<Failure, List<MessageTemplate>>> fetchInboxTemplates(int inboxId) =>
      _messageOps.fetchInboxTemplates(inboxId);

  @override
  Future<Either<Failure, List<MessageTemplate>>> fetchConversationTemplates(int conversationId) =>
      _messageOps.fetchConversationTemplates(conversationId);

  @override
  Future<Either<Failure, Message>> sendBrowserWhatsAppList({
    required int conversationId,
    required String templateId,
    required Map<String, dynamic> variables,
  }) =>
      _messageOps.sendBrowserWhatsAppList(
        conversationId: conversationId,
        templateId: templateId,
        variables: variables,
      );

  // ---------------------------------------------------------------------------
  // Conversation Operations Delegation
  // ---------------------------------------------------------------------------
  @override
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
  }) =>
      _conversationOps.getConversations(
        status: status,
        assigneeType: assigneeType,
        inboxId: inboxId,
        teamId: teamId,
        label: label,
        assigneeId: assigneeId,
        assigneeAgentBotId: assigneeAgentBotId,
        lifecycleStageId: lifecycleStageId,
        page: page,
      );

  @override
  Future<Either<Failure, List<Conversation>>> searchConversations(String query, {int page = 1}) =>
      _conversationOps.searchConversations(query, page: page);

  @override
  Future<Either<Failure, Conversation>> getConversation(int conversationId) =>
      _conversationOps.getConversation(conversationId);

  @override
  Future<Either<Failure, Conversation>> startDirectChat({
    required String phoneNumber,
    required int inboxId,
    required String sourceId,
    String? contactName,
  }) =>
      _conversationOps.startDirectChat(
        phoneNumber: phoneNumber,
        inboxId: inboxId,
        sourceId: sourceId,
        contactName: contactName,
      );

  @override
  Future<Either<Failure, Conversation>> startNewConversation({
    required int contactId,
    required int inboxId,
    required String sourceId,
    String? message,
  }) =>
      _conversationOps.startNewConversation(
        contactId: contactId,
        inboxId: inboxId,
        sourceId: sourceId,
        message: message,
      );

  @override
  Future<Either<Failure, void>> toggleStatus(int conversationId, String status, {String? snoozedUntil}) =>
      _conversationOps.toggleStatus(conversationId, status, snoozedUntil: snoozedUntil);

  @override
  Future<Either<Failure, void>> assignAgent(int conversationId, int? agentId, {String? assigneeType}) =>
      _conversationOps.assignAgent(conversationId, agentId, assigneeType: assigneeType);

  @override
  Future<Either<Failure, List<int>>> fetchPinnedConversationIds() =>
      _conversationOps.fetchPinnedConversationIds();

  @override
  Future<Either<Failure, void>> pinConversation(int conversationId) =>
      _conversationOps.pinConversation(conversationId);

  @override
  Future<Either<Failure, void>> unpinConversation(int conversationId) =>
      _conversationOps.unpinConversation(conversationId);

  @override
  Future<Either<Failure, void>> assignTeam(int conversationId, int? teamId) =>
      _conversationOps.assignTeam(conversationId, teamId);

  @override
  Future<Either<Failure, void>> updateLabels(int conversationId, List<String> labels) =>
      _conversationOps.updateLabels(conversationId, labels);

  @override
  Future<Either<Failure, void>> updateLifecycleStage(int conversationId, int stageId) =>
      _conversationOps.updateLifecycleStage(conversationId, stageId);

  @override
  Future<Either<Failure, void>> updateConversationCustomAttributes(
    int conversationId,
    Map<String, dynamic> customAttributes,
  ) =>
      _conversationOps.updateConversationCustomAttributes(conversationId, customAttributes);

  @override
  Future<Either<Failure, void>> muteConversation(int conversationId) =>
      _conversationOps.muteConversation(conversationId);

  @override
  Future<Either<Failure, void>> unmuteConversation(int conversationId) =>
      _conversationOps.unmuteConversation(conversationId);

  @override
  Future<Either<Failure, void>> markAsRead(int conversationId) =>
      _conversationOps.markAsRead(conversationId);

  @override
  Future<Either<Failure, List<WorkflowShortcut>>> getAvailableWorkflows(int conversationId) =>
      _conversationOps.getAvailableWorkflows(conversationId);

  @override
  Future<Either<Failure, List<WorkflowRun>>> getWorkflowRuns(int conversationId) =>
      _conversationOps.getWorkflowRuns(conversationId);

  @override
  Future<Either<Failure, void>> startWorkflow(
    int conversationId,
    int workflowId, {
    Map<String, dynamic> variables = const {},
  }) =>
      _conversationOps.startWorkflow(conversationId, workflowId, variables: variables);

  @override
  Future<Either<Failure, void>> stopWorkflowRun(int conversationId, int workflowRunId) =>
      _conversationOps.stopWorkflowRun(conversationId, workflowRunId);

  // ---------------------------------------------------------------------------
  // Metadata Operations Delegation
  // ---------------------------------------------------------------------------
  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getContactableInboxes(int contactId) =>
      _metadataOps.getContactableInboxes(contactId);

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getPhoneDestinations({String? phoneNumber}) =>
      _metadataOps.getPhoneDestinations(phoneNumber: phoneNumber);

  @override
  Future<Either<Failure, List<Inbox>>> fetchInboxes() => _metadataOps.fetchInboxes();

  @override
  Future<Either<Failure, List<Label>>> fetchLabels() => _metadataOps.fetchLabels();

  @override
  Future<Either<Failure, List<LifecycleStage>>> fetchLifecycleStages() =>
      _metadataOps.fetchLifecycleStages();

  @override
  Future<Either<Failure, List<Team>>> fetchTeams() => _metadataOps.fetchTeams();

  @override
  Future<Either<Failure, List<User>>> fetchAgents() => _metadataOps.fetchAgents();

  @override
  Future<Either<Failure, List<User>>> fetchAssignableAgents({int? inboxId, List<int>? inboxIds}) =>
      _metadataOps.fetchAssignableAgents(inboxId: inboxId, inboxIds: inboxIds);

  @override
  Future<Either<Failure, List<Map<String, String>>>> fetchCannedResponses() =>
      _metadataOps.fetchCannedResponses();

  @override
  Future<Either<Failure, ConversationFilterOptions>> fetchFilterOptions() =>
      _metadataOps.fetchFilterOptions();

  // ---------------------------------------------------------------------------
  // Collaborator Operations Delegation
  // ---------------------------------------------------------------------------
  @override
  Future<Either<Failure, Contact>> getCollaborators(int conversationId) =>
      _collaboratorOps.getCollaborators(conversationId);

  @override
  Future<Either<Failure, Contact>> addCollaborator(int conversationId, int userId) =>
      _collaboratorOps.addCollaborator(conversationId, userId);

  @override
  Future<Either<Failure, Contact>> removeCollaborator(int conversationId, int userId) =>
      _collaboratorOps.removeCollaborator(conversationId, userId);
}
