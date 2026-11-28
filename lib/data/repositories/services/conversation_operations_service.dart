import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../core/error/failures.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/performance_service.dart';
import '../../../core/storage/local_cache_service.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../../../core/utils/background_json_parser.dart';
import '../../models/conversation.dart';
import '../../models/workflow.dart';
import '../interfaces/i_conversation_operations.dart';

class ConversationOperationsService implements IConversationOperations {
  final ApiClient _api;
  final SecureStorageService _storage = SecureStorageService();

  ConversationOperationsService({ApiClient? api}) : _api = api ?? ApiClient();

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
  }) async {
    return PerformanceService.traceAsync<Either<Failure, List<Conversation>>>(
      'server_fetch_conversations',
      () async {
        try {
          final params = <String, dynamic>{
            'status': status,
            'page': page,
            'sort_by': 'last_activity_at_desc',
          };

          if (assigneeType.isNotEmpty && assigneeType != 'all') {
            params['assignee_type'] = assigneeType;
          }

          if (inboxId != null) params['inbox_id'] = inboxId;
          if (teamId != null) params['team_id'] = teamId;
          if (label != null) params['labels[]'] = label;
          if (assigneeId != null) params['assignee_id'] = assigneeId;
          if (assigneeAgentBotId != null) {
            params['assignee_agent_bot_id'] = assigneeAgentBotId;
          }
          if (lifecycleStageId != null) {
            params['lifecycle_stage_id'] = lifecycleStageId;
          }

          final response = await _api.get(
            'conversations',
            queryParameters: params,
          );
          final data = response.data;

          List list = [];
          if (data is Map &&
              data['data'] != null &&
              data['data']['payload'] != null) {
            list = data['data']['payload'];
          } else if (data is Map && data['payload'] != null) {
            list = data['payload'];
          } else if (data is Map && data['data'] is List) {
            list = data['data'];
          } else if (data is List) {
            list = data;
          }

          final activeAccId = await _storage.getActiveAccountId();

          if (page == 1 &&
              status == 'all' &&
              assigneeType == 'all' &&
              inboxId == null &&
              teamId == null &&
              label == null &&
              assigneeId == null &&
              assigneeAgentBotId == null &&
              lifecycleStageId == null &&
              activeAccId != null &&
              activeAccId > 0 &&
              list.isNotEmpty) {
            LocalCacheService().saveRawConversations(activeAccId, list);
          }

          final parsedConversations =
              await BackgroundJsonParser.parseConversations(list);
          final conversations = <Conversation>[];
          for (var conv in parsedConversations) {
            if (activeAccId != null &&
                activeAccId > 0 &&
                conv.accountId > 0 &&
                conv.accountId != activeAccId) {
              continue;
            }
            conversations.add(conv);
          }

          return Right(conversations);
        } on DioException catch (e) {
          return Left(ServerFailure(e.message ?? 'فشل في تحميل المحادثات'));
        } catch (e) {
          return Left(ServerFailure(e.toString()));
        }
      },
      attributes: {'page': page.toString(), 'status': status},
      onResult: (trace, either) {
        either.fold(
          (_) {},
          (convs) => trace.setMetric('items_received', convs.length),
        );
      },
    );
  }

  @override
  Future<Either<Failure, List<Conversation>>> searchConversations(
    String query, {
    int page = 1,
  }) async {
    try {
      // In Chatwoot / Message-Pro backend, search is performed via `GET /conversations?q=...`
      // or fall back if `conversations/search` is not supported (500).
      Response response;
      try {
        response = await _api.get(
          'conversations',
          queryParameters: {'q': query, 'status': 'all', 'page': page},
        );
      } on DioException catch (dioErr) {
        // Fallback to conversations/search if conversations with q is rejected
        if (dioErr.response?.statusCode == 404) {
          response = await _api.get(
            'conversations/search',
            queryParameters: {'q': query, 'page': page},
          );
        } else {
          rethrow;
        }
      }

      final data = response.data;

      List list = [];
      if (data is Map &&
          data['data'] != null &&
          data['data']['payload'] != null) {
        list = data['data']['payload'];
      } else if (data is Map && data['payload'] != null) {
        list = data['payload'];
      } else if (data is Map && data['data'] is List) {
        list = data['data'];
      } else if (data is List) {
        list = data;
      }

      final conversations = <Conversation>[];
      for (final item in list) {
        if (item is Map) {
          try {
            final conv = Conversation.fromJson(Map<String, dynamic>.from(item));
            if (conv.id > 0) {
              conversations.add(conv);
            }
          } catch (_) {}
        }
      }
      return Right(conversations);
    } on DioException catch (e) {
      return Left(ServerFailure(e.message ?? 'فشل في البحث عن المحادثات'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Conversation>> getConversation(
    int conversationId,
  ) async {
    try {
      final response = await _api.get('conversations/$conversationId');
      final data = response.data;
      Map<String, dynamic>? item;
      if (data is Map &&
          data['data'] != null &&
          data['data']['payload'] != null) {
        item = Map<String, dynamic>.from(data['data']['payload']);
      } else if (data is Map && data['payload'] != null) {
        item = Map<String, dynamic>.from(data['payload']);
      } else if (data is Map && data['data'] is Map) {
        item = Map<String, dynamic>.from(data['data']);
      } else if (data is Map) {
        item = Map<String, dynamic>.from(data);
      }
      if (item != null) {
        return Right(Conversation.fromJson(item));
      }
      return const Left(ServerFailure('المحادثة غير موجودة'));
    } on DioException catch (e) {
      return Left(ServerFailure(e.message ?? 'فشل في تحميل المحادثة'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Conversation>> startDirectChat({
    required String phoneNumber,
    required int inboxId,
    required String sourceId,
    String? contactName,
  }) async {
    try {
      var cleanPhone = phoneNumber.trim();
      if (!cleanPhone.startsWith('+')) {
        if (cleanPhone.startsWith('01') && cleanPhone.length == 11) {
          cleanPhone = '+2$cleanPhone';
        } else if (cleanPhone.startsWith('201') && cleanPhone.length == 12) {
          cleanPhone = '+$cleanPhone';
        } else {
          cleanPhone = '+$cleanPhone';
        }
      }

      int? contactId;
      try {
        final searchRes = await _api.get(
          'contacts/search',
          queryParameters: {'q': cleanPhone},
        );
        final sData = searchRes.data;
        List cList = [];
        if (sData is Map && sData['payload'] is List) {
          cList = sData['payload'];
        } else if (sData is List) {
          cList = sData;
        }

        if (cList.isNotEmpty) {
          final first = cList.first;
          contactId = first['id'] is int
              ? first['id']
              : int.tryParse(first['id']?.toString() ?? '');
        }
      } catch (_) {}

      if (contactId == null || contactId <= 0) {
        final createRes = await _api.post(
          'contacts',
          data: {
            'name': (contactName != null && contactName.trim().isNotEmpty)
                ? contactName.trim()
                : cleanPhone,
            'phone_number': cleanPhone,
          },
        );
        final cData = createRes.data;
        final cObj = (cData is Map && cData['payload']?['contact'] != null)
            ? cData['payload']['contact']
            : (cData is Map && cData['contact'] != null
                  ? cData['contact']
                  : cData);
        contactId = cObj is Map
            ? (cObj['id'] is int
                  ? cObj['id']
                  : int.tryParse(cObj['id']?.toString() ?? ''))
            : null;
      }

      if (contactId == null || contactId <= 0) {
        return Left(
          ServerFailure('تعذر تحديد أو إنشاء جهة الاتصال للرقم $cleanPhone'),
        );
      }

      try {
        await _api.post(
          'contacts/$contactId/contact_inboxes',
          data: {'inbox_id': inboxId, 'source_id': sourceId},
        );
      } catch (_) {}

      final convRes = await _api.post(
        'conversations',
        data: {
          'contact_id': contactId,
          'inbox_id': inboxId,
          'source_id': sourceId,
        },
      );

      final convData = convRes.data;
      final rawConv = convData is Map
          ? (convData['payload'] ?? convData['data'] ?? convData)
          : null;
      if (rawConv is Map) {
        return Right(Conversation.fromJson(Map<String, dynamic>.from(rawConv)));
      }
      return Left(ServerFailure('استجابة غير صالحة من السيرفر'));
    } on DioException catch (e) {
      String errMsg = 'فشل في بدء المحادثة';
      if (e.response?.data is Map) {
        final d = e.response!.data as Map;
        errMsg = d['message']?.toString() ?? d['error']?.toString() ?? errMsg;
      } else if (e.message != null) {
        errMsg = e.message!;
      }
      return Left(ServerFailure(errMsg));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Conversation>> startNewConversation({
    required int contactId,
    required int inboxId,
    required String sourceId,
    String? message,
  }) async {
    try {
      String cleanSource = sourceId.trim();
      if (cleanSource.startsWith('01') && cleanSource.length == 11) {
        cleanSource = '+2$cleanSource';
      } else if (cleanSource.startsWith('201') && cleanSource.length == 12) {
        cleanSource = '+$cleanSource';
      }

      try {
        await _api.post(
          'contacts/$contactId/contact_inboxes',
          data: {'inbox_id': inboxId, 'source_id': cleanSource},
        );
      } catch (_) {}

      final payload = <String, dynamic>{
        'contact_id': contactId,
        'inbox_id': inboxId,
        'source_id': cleanSource,
      };
      if (message != null && message.trim().isNotEmpty) {
        payload['message'] = {
          'content': message.trim(),
          'message_type': 'outgoing',
          'private': false,
        };
      }
      final response = await _api.post('conversations', data: payload);
      final data = response.data;
      final rawConv = data is Map
          ? (data['payload'] ?? data['data'] ?? data)
          : null;
      if (rawConv is Map) {
        return Right(Conversation.fromJson(Map<String, dynamic>.from(rawConv)));
      }
      return Left(ServerFailure('فشل بدء المحادثة'));
    } on DioException catch (e) {
      String errMsg = 'فشل إنشاء المحادثة';
      if (e.response?.data is Map) {
        final d = e.response!.data as Map;
        errMsg =
            d['message']?.toString() ??
            d['error']?.toString() ??
            (d['errors'] is List ? (d['errors'] as List).join(', ') : null) ??
            e.message ??
            'فشل إنشاء المحادثة';
      } else if (e.message != null && e.message!.isNotEmpty) {
        errMsg = e.message!;
      }
      return Left(ServerFailure(errMsg));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> toggleStatus(
    int conversationId,
    String status, {
    String? snoozedUntil,
  }) async {
    try {
      final payload = <String, dynamic>{};
      if (status == 'snoozed') {
        payload['status'] = 'snoozed';
        if (snoozedUntil != null && snoozedUntil.isNotEmpty) {
          payload['snoozed_until'] = snoozedUntil;
        }
      } else if (status == 'open') {
        payload['status'] = 'open';
      } else if (status == 'bot') {
        payload['status'] = 'bot';
      } else if (status == 'pending') {
        payload['status'] = 'pending';
      }

      final response = await _api.post(
        'conversations/$conversationId/toggle_status',
        data: payload,
      );

      final currentStatus =
          response.data is Map && response.data['payload'] is Map
          ? response.data['payload']['current_status']?.toString()
          : null;

      if (status == 'resolved' &&
          currentStatus != null &&
          currentStatus != 'resolved') {
        await _api.post(
          'conversations/$conversationId/toggle_status',
          data: <String, dynamic>{},
        );
      }

      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> assignAgent(
    int conversationId,
    int? agentId, {
    String? assigneeType,
  }) async {
    try {
      final Map<String, dynamic> data;
      if (agentId == null || agentId < 0) {
        data = {'assignee_id': null};
      } else {
        data = {'assignee_id': agentId};
        if (assigneeType != null) {
          data['assignee_type'] = assigneeType;
        }
      }

      await _api.post('conversations/$conversationId/assignments', data: data);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<int>>> fetchPinnedConversationIds() async {
    try {
      final response = await _api.get('conversation_pins');
      final data = response.data;
      final ids = <int>[];
      if (data is List) {
        for (final item in data) {
          if (item is Map) {
            final rawId = item['conversation_id'] ?? item['id'];
            final id = rawId is int
                ? rawId
                : int.tryParse(rawId?.toString() ?? '');
            if (id != null && id > 0) {
              ids.add(id);
            }
          }
        }
      }
      return Right(ids);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> pinConversation(int conversationId) async {
    try {
      await _api.post(
        'conversation_pins',
        data: {'conversation_id': conversationId},
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> unpinConversation(int conversationId) async {
    try {
      await _api.delete('conversation_pins/$conversationId');
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> assignTeam(
    int conversationId,
    int? teamId,
  ) async {
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
  Future<Either<Failure, void>> updateLabels(
    int conversationId,
    List<String> labels,
  ) async {
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
  Future<Either<Failure, void>> updateLifecycleStage(
    int conversationId,
    int stageId,
  ) async {
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
  Future<Either<Failure, void>> updateConversationCustomAttributes(
    int conversationId,
    Map<String, dynamic> customAttributes,
  ) async {
    try {
      await _api.post(
        'conversations/$conversationId/custom_attributes',
        data: {'custom_attributes': customAttributes},
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> muteConversation(int conversationId) async {
    try {
      await _api.post('conversations/$conversationId/mute');
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> unmuteConversation(int conversationId) async {
    try {
      await _api.post('conversations/$conversationId/unmute');
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<List<Conversation>> getCachedConversations(int accountId) async {
    return await LocalCacheService().getCachedConversations(accountId);
  }

  @override
  Future<Either<Failure, void>> markAsRead(int conversationId) async {
    if (conversationId <= 0) {
      return const Right(null);
    }
    try {
      await _api.post('conversations/$conversationId/update_last_seen');
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<WorkflowShortcut>>> getAvailableWorkflows(
    int conversationId,
  ) async {
    try {
      final response = await _api.get(
        'conversations/$conversationId/workflow_runs/available',
      );
      final data = response.data;
      final list = <WorkflowShortcut>[];
      if (data is List) {
        for (final item in data) {
          if (item is Map) {
            list.add(WorkflowShortcut.fromJson(Map<String, dynamic>.from(item)));
          }
        }
      }
      return Right(list);
    } catch (e) {
      return Left(ServerFailure(_extractErrorMessage(e)));
    }
  }

  @override
  Future<Either<Failure, List<WorkflowRun>>> getWorkflowRuns(
    int conversationId,
  ) async {
    try {
      final response = await _api.get(
        'conversations/$conversationId/workflow_runs',
      );
      final data = response.data;
      final list = <WorkflowRun>[];
      if (data is List) {
        for (final item in data) {
          if (item is Map) {
            list.add(WorkflowRun.fromJson(Map<String, dynamic>.from(item)));
          }
        }
      }
      return Right(list);
    } catch (e) {
      return Left(ServerFailure(_extractErrorMessage(e)));
    }
  }

  @override
  Future<Either<Failure, void>> startWorkflow(
    int conversationId,
    int workflowId, {
    Map<String, dynamic> variables = const {},
  }) async {
    try {
      await _api.post(
        'conversations/$conversationId/workflow_runs/$workflowId/start',
        data: {'variables': variables},
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(_extractErrorMessage(e)));
    }
  }

  @override
  Future<Either<Failure, void>> stopWorkflowRun(
    int conversationId,
    int workflowRunId,
  ) async {
    try {
      await _api.post(
        'conversations/$conversationId/workflow_runs/$workflowRunId/stop',
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(_extractErrorMessage(e)));
    }
  }

  String _extractErrorMessage(Object e) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map && data['error'] != null) {
        return data['error'].toString();
      }
    }
    return e.toString();
  }
}
