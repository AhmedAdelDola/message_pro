import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../models/conversation.dart';
import '../models/message.dart';
import '../models/contact.dart';
import '../models/user.dart';

class ConversationRepository {
  final ApiClient _api = ApiClient();

  Future<List<Conversation>> getConversations({
    String status = 'open',
    String assigneeType = 'all', // 'all', 'me', 'unassigned'
    int? inboxId,
    int? teamId,
    String? label,
    int page = 1,
  }) async {
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

    return list.map((c) => Conversation.fromJson(c as Map<String, dynamic>)).toList();
  }

  Future<List<Message>> getMessages(int conversationId) async {
    final response = await _api.get('conversations/$conversationId/messages');
    final data = response.data;

    List list = [];
    if (data is Map && data['payload'] != null) {
      list = data['payload'];
    } else if (data is List) {
      list = data;
    }

    return list.map((m) => Message.fromJson(m as Map<String, dynamic>)).toList();
  }

  Future<Message> sendMessage({
    required int conversationId,
    required String content,
    bool isPrivate = false,
    List<String>? attachmentPaths,
  }) async {
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

    return Message.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> toggleStatus(int conversationId, String status) async {
    await _api.post(
      'conversations/$conversationId/toggle_status',
      data: {'status': status},
    );
  }

  Future<void> assignAgent(int conversationId, int? agentId) async {
    await _api.post(
      'conversations/$conversationId/assignments',
      data: {'assignee_id': agentId},
    );
  }

  Future<void> assignTeam(int conversationId, int? teamId) async {
    await _api.post(
      'conversations/$conversationId/assignments',
      data: {'team_id': teamId},
    );
  }

  Future<void> updateLabels(int conversationId, List<String> labels) async {
    await _api.post(
      'conversations/$conversationId/labels',
      data: {'labels': labels},
    );
  }

  Future<void> updateLifecycleStage(int conversationId, int stageId) async {
    try {
      await _api.patch(
        'conversations/$conversationId/lifecycle',
        data: {'lifecycle_stage_id': stageId},
      );
    } catch (_) {}
  }

  Future<void> markAsRead(int conversationId) async {
    try {
      await _api.post('conversations/$conversationId/update_last_seen');
    } catch (_) {}
  }

  Future<List<Inbox>> fetchInboxes() async {
    try {
      final response = await _api.get('inboxes');
      final data = response.data;
      List list = data is Map && data['payload'] != null ? data['payload'] : (data is List ? data : []);
      return list.map((i) => Inbox.fromJson(i as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<Label>> fetchLabels() async {
    try {
      final response = await _api.get('labels');
      final data = response.data;
      List list = data is Map && data['payload'] != null ? data['payload'] : (data is List ? data : []);
      return list.map((l) => Label.fromJson(l as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<LifecycleStage>> fetchLifecycleStages() async {
    try {
      final response = await _api.get('lifecycle_stages');
      final data = response.data;
      List list = data is Map && data['payload'] != null ? data['payload'] : (data is List ? data : []);
      return list.map((s) => LifecycleStage.fromJson(s as Map<String, dynamic>)).toList();
    } catch (_) {
      return [
        LifecycleStage(id: 1, name: 'New Lead', color: '#3B82F6', icon: '🌱'),
        LifecycleStage(id: 2, name: 'Qualified', color: '#10B981', icon: '⭐'),
        LifecycleStage(id: 3, name: 'In Progress', color: '#F59E0B', icon: '⏳'),
        LifecycleStage(id: 4, name: 'Customer', color: '#6366F1', icon: '💎'),
      ];
    }
  }

  Future<List<Team>> fetchTeams() async {
    try {
      final response = await _api.get('teams');
      final data = response.data;
      List list = data is Map && data['payload'] != null ? data['payload'] : (data is List ? data : []);
      return list.map((t) => Team.fromJson(t as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<User>> fetchAgents() async {
    try {
      final response = await _api.get('agents');
      final data = response.data;
      List list = data is Map && data['payload'] != null ? data['payload'] : (data is List ? data : []);
      return list.map((a) => User.fromJson(a as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, String>>> fetchCannedResponses() async {
    try {
      final response = await _api.get('canned_responses');
      final data = response.data;
      List list = data is Map && data['payload'] != null ? data['payload'] : (data is List ? data : []);
      return list.map<Map<String, String>>((c) => {
        'short_code': c['short_code']?.toString() ?? '',
        'content': c['content']?.toString() ?? '',
      }).toList();
    } catch (_) {
      return [
        {'short_code': 'hello', 'content': 'Hello! How can I assist you today?'},
        {'short_code': 'thanks', 'content': 'Thank you for reaching out to Message Pro!'},
        {'short_code': 'wait', 'content': 'Please give me a moment while I check this for you.'},
      ];
    }
  }
}
