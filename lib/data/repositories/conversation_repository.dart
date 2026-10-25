import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../core/error/failures.dart';
import '../../core/network/api_client.dart';
import '../models/conversation.dart';
import '../models/message.dart';
import '../models/contact.dart';
import '../models/user.dart';

abstract class IConversationRepository {
  Future<Either<Failure, List<Conversation>>> getConversations({
    String status = 'open',
    String assigneeType = 'all',
    int? inboxId,
    int? teamId,
    String? label,
    int page = 1,
  });
  Future<Either<Failure, List<Message>>> getMessages(int conversationId);
  Future<Either<Failure, Message>> sendMessage({
    required int conversationId,
    required String content,
    bool isPrivate = false,
    List<String>? attachmentPaths,
  });
  Future<Either<Failure, void>> toggleStatus(int conversationId, String status);
  Future<Either<Failure, void>> assignAgent(int conversationId, int? agentId);
  Future<Either<Failure, void>> assignTeam(int conversationId, int? teamId);
  Future<Either<Failure, void>> updateLabels(int conversationId, List<String> labels);
  Future<Either<Failure, void>> updateLifecycleStage(int conversationId, int stageId);
  Future<Either<Failure, void>> markAsRead(int conversationId);
  Future<Either<Failure, List<Inbox>>> fetchInboxes();
  Future<Either<Failure, List<Label>>> fetchLabels();
  Future<Either<Failure, List<LifecycleStage>>> fetchLifecycleStages();
  Future<Either<Failure, List<Team>>> fetchTeams();
  Future<Either<Failure, List<User>>> fetchAgents();
  Future<Either<Failure, List<Map<String, String>>>> fetchCannedResponses();
}

class ConversationRepository implements IConversationRepository {
  final ApiClient _api;

  ConversationRepository({ApiClient? api}) : _api = api ?? ApiClient();

  @override
  Future<Either<Failure, List<Conversation>>> getConversations({
    String status = 'open',
    String assigneeType = 'all',
    int? inboxId,
    int? teamId,
    String? label,
    int page = 1,
  }) async {
    try {
      final params = <String, dynamic>{
        'status': status,
        'assignee_type': assigneeType,
        'page': page,
      };

      if (inboxId != null) params['inbox_id'] = inboxId;
      if (teamId != null) params['team_id'] = teamId;
      if (label != null) params['labels'] = [label];

      final response = await _api.get('conversations', queryParameters: params);
      final data = response.data;

      List list = [];
      if (data is Map && data['data'] != null && data['data']['payload'] != null) {
        list = data['data']['payload'];
      } else if (data is Map && data['payload'] != null) {
        list = data['payload'];
      } else if (data is List) {
        list = data;
      }

      final conversations = list.map((c) => Conversation.fromJson(c as Map<String, dynamic>)).toList();
      return Right(conversations);
    } on DioException catch (e) {
      return Left(ServerFailure(e.message ?? 'فشل في تحميل المحادثات'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Message>>> getMessages(int conversationId) async {
    try {
      final response = await _api.get('conversations/$conversationId/messages');
      final data = response.data;

      List list = [];
      if (data is Map && data['payload'] != null) {
        list = data['payload'];
      } else if (data is List) {
        list = data;
      }

      final messages = list.map((m) => Message.fromJson(m as Map<String, dynamic>)).toList();
      return Right(messages);
    } on DioException catch (e) {
      return Left(ServerFailure(e.message ?? 'فشل في تحميل الرسائل'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Message>> sendMessage({
    required int conversationId,
    required String content,
    bool isPrivate = false,
    List<String>? attachmentPaths,
  }) async {
    try {
      dynamic postData;
      if (attachmentPaths != null && attachmentPaths.isNotEmpty) {
        final formData = FormData();
        formData.fields.add(MapEntry('content', content));
        formData.fields.add(MapEntry('private', isPrivate.toString()));
        for (final path in attachmentPaths) {
          formData.files.add(MapEntry(
            'attachments[]',
            await MultipartFile.fromFile(path),
          ));
        }
        postData = formData;
      } else {
        postData = {
          'content': content,
          'private': isPrivate,
        };
      }

      final response = await _api.post(
        'conversations/$conversationId/messages',
        data: postData,
      );

      final message = Message.fromJson(response.data as Map<String, dynamic>);
      return Right(message);
    } on DioException catch (e) {
      return Left(ServerFailure(e.message ?? 'فشل في إرسال الرسالة'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> toggleStatus(int conversationId, String status) async {
    try {
      await _api.post(
        'conversations/$conversationId/toggle_status',
        data: {'status': status},
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> assignAgent(int conversationId, int? agentId) async {
    try {
      await _api.post(
        'conversations/$conversationId/assignments',
        data: {'assignee_id': agentId},
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> assignTeam(int conversationId, int? teamId) async {
    try {
      await _api.post(
        'conversations/$conversationId/assignments',
        data: {'team_id': teamId},
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateLabels(int conversationId, List<String> labels) async {
    try {
      await _api.post(
        'conversations/$conversationId/labels',
        data: {'labels': labels},
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateLifecycleStage(int conversationId, int stageId) async {
    try {
      await _api.patch(
        'conversations/$conversationId/lifecycle',
        data: {'lifecycle_stage_id': stageId},
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> markAsRead(int conversationId) async {
    try {
      await _api.post('conversations/$conversationId/update_last_seen');
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Inbox>>> fetchInboxes() async {
    try {
      final response = await _api.get('inboxes');
      final data = response.data;
      List list = data is Map && data['payload'] != null ? data['payload'] : (data is List ? data : []);
      return Right(list.map((i) => Inbox.fromJson(i as Map<String, dynamic>)).toList());
    } catch (_) {
      return const Right([]);
    }
  }

  @override
  Future<Either<Failure, List<Label>>> fetchLabels() async {
    try {
      final response = await _api.get('labels');
      final data = response.data;
      List list = data is Map && data['payload'] != null ? data['payload'] : (data is List ? data : []);
      return Right(list.map((l) => Label.fromJson(l as Map<String, dynamic>)).toList());
    } catch (_) {
      return const Right([]);
    }
  }

  @override
  Future<Either<Failure, List<LifecycleStage>>> fetchLifecycleStages() async {
    try {
      final response = await _api.get('lifecycle_stages');
      final data = response.data;
      List list = data is Map && data['payload'] != null ? data['payload'] : (data is List ? data : []);
      return Right(list.map((s) => LifecycleStage.fromJson(s as Map<String, dynamic>)).toList());
    } catch (_) {
      return Right([
        LifecycleStage(id: 1, name: 'New Lead', color: '#3B82F6', icon: '🌱'),
        LifecycleStage(id: 2, name: 'Qualified', color: '#10B981', icon: '⭐'),
        LifecycleStage(id: 3, name: 'In Progress', color: '#F59E0B', icon: '⏳'),
        LifecycleStage(id: 4, name: 'Customer', color: '#6366F1', icon: '💎'),
      ]);
    }
  }

  @override
  Future<Either<Failure, List<Team>>> fetchTeams() async {
    try {
      final response = await _api.get('teams');
      final data = response.data;
      List list = data is Map && data['payload'] != null ? data['payload'] : (data is List ? data : []);
      return Right(list.map((t) => Team.fromJson(t as Map<String, dynamic>)).toList());
    } catch (_) {
      return const Right([]);
    }
  }

  @override
  Future<Either<Failure, List<User>>> fetchAgents() async {
    try {
      final response = await _api.get('agents');
      final data = response.data;
      List list = data is Map && data['payload'] != null ? data['payload'] : (data is List ? data : []);
      return Right(list.map((a) => User.fromJson(a as Map<String, dynamic>)).toList());
    } catch (_) {
      return const Right([]);
    }
  }

  @override
  Future<Either<Failure, List<Map<String, String>>>> fetchCannedResponses() async {
    try {
      final response = await _api.get('canned_responses');
      final data = response.data;
      List list = data is Map && data['payload'] != null ? data['payload'] : (data is List ? data : []);
      return Right(list.map<Map<String, String>>((c) => {
        'short_code': c['short_code']?.toString() ?? '',
        'content': c['content']?.toString() ?? '',
      }).toList());
    } catch (_) {
      return const Right([
        {'short_code': 'hello', 'content': 'أهلاً بك! كيف يمكنني مساعدتك اليوم؟'},
        {'short_code': 'thanks', 'content': 'شكراً لتواصلك مع Message Pro!'},
        {'short_code': 'wait', 'content': 'يرجى الانتظار لحظات للتحقق من طلبك.'},
      ]);
    }
  }
}
