import 'package:dartz/dartz.dart';
import '../../../core/error/failures.dart';
import '../../models/contact.dart';
import '../../models/conversation_filter_options.dart';
import '../../models/user.dart';

abstract class IMetadataOperations {
  Future<Either<Failure, List<Inbox>>> fetchInboxes();
  Future<Either<Failure, List<Label>>> fetchLabels();
  Future<Either<Failure, List<LifecycleStage>>> fetchLifecycleStages();
  Future<Either<Failure, List<Team>>> fetchTeams();
  Future<Either<Failure, List<User>>> fetchAgents();
  Future<Either<Failure, List<User>>> fetchAssignableAgents({int? inboxId, List<int>? inboxIds});
  Future<Either<Failure, List<Map<String, String>>>> fetchCannedResponses();
  Future<Either<Failure, ConversationFilterOptions>> fetchFilterOptions();
  Future<Either<Failure, List<Map<String, dynamic>>>> getContactableInboxes(int contactId);
  Future<Either<Failure, List<Map<String, dynamic>>>> getPhoneDestinations({String? phoneNumber});
  void clearCache() {}
}
