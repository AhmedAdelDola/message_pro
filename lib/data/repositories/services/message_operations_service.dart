import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../core/error/failures.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/performance_service.dart';
import '../../../core/storage/local_cache_service.dart';
import '../../../core/utils/background_json_parser.dart';
import '../../models/message.dart';
import '../../models/message_template.dart';
import '../../models/message_template_registry.dart';
import '../interfaces/i_message_operations.dart';

class MessageOperationsService implements IMessageOperations {
  final ApiClient _api;
  final Map<int, List<Message>> _cachedMessages = {};

  MessageOperationsService({ApiClient? api}) : _api = api ?? ApiClient();

  @override
  void clearCache() {
    _cachedMessages.clear();
  }

  @override
  List<Message>? getCachedMessages(int conversationId) => _cachedMessages[conversationId];

  @override
  Future<List<Message>> getLocalCachedMessages(int conversationId) async {
    final inMem = _cachedMessages[conversationId];
    if (inMem != null && inMem.isNotEmpty) return inMem;
    final disk = await LocalCacheService().getCachedMessages(conversationId);
    if (disk.isNotEmpty) {
      _cachedMessages[conversationId] = disk;
    }
    return disk;
  }

  @override
  Future<Either<Failure, List<Message>>> getMessages(
    int conversationId, {
    int? beforeId,
    int? afterId,
  }) async {
    if (conversationId <= 0) {
      return const Right([]);
    }
    return PerformanceService.traceAsync<Either<Failure, List<Message>>>(
      'server_fetch_messages',
      () async {
        try {
          final params = <String, dynamic>{};
          if (beforeId != null) {
            params['before'] = beforeId;
          }
          if (afterId != null) {
            params['after'] = afterId;
          }

          final response = await _api.get(
            'conversations/$conversationId/messages',
            queryParameters: params.isNotEmpty ? params : null,
          );
          final data = response.data;

          List list = [];
          if (data is Map && data['data'] != null && data['data']['payload'] != null) {
            list = data['data']['payload'];
          } else if (data is Map && data['payload'] != null) {
            list = data['payload'];
          } else if (data is Map && data['data'] is List) {
            list = data['data'];
          } else if (data is List) {
            list = data;
          }

          final messages = await BackgroundJsonParser.parseMessages(list);

          if (beforeId == null && afterId == null && messages.isNotEmpty) {
            _cachedMessages[conversationId] = List.from(messages);
            LocalCacheService().saveRawMessages(conversationId, list);
          }

          return Right(messages);
        } on DioException catch (e) {
          return Left(ServerFailure(e.message ?? 'فشل في تحميل الرسائل'));
        } catch (e) {
          return Left(ServerFailure(e.toString()));
        }
      },
      attributes: {
        'conversation_id': conversationId.toString(),
      },
      onResult: (trace, either) {
        either.fold(
          (_) {},
          (msgs) => trace.setMetric('messages_received', msgs.length),
        );
      },
    );
  }

  @override
  Future<Either<Failure, Message>> sendMessage({
    required int conversationId,
    required String content,
    bool isPrivate = false,
    List<String>? attachmentPaths,
    int? inReplyToId,
    String? echoId,
  }) async {
    try {
      dynamic postData;
      if (attachmentPaths != null && attachmentPaths.isNotEmpty) {
        final formData = FormData();
        formData.fields.add(MapEntry('content', content));
        formData.fields.add(const MapEntry('message_type', 'outgoing'));
        formData.fields.add(MapEntry('private', isPrivate.toString()));
        if (echoId != null) {
          formData.fields.add(MapEntry('echo_id', echoId));
        }
        if (inReplyToId != null) {
          formData.fields.add(MapEntry('content_attributes[in_reply_to]', inReplyToId.toString()));
        }
        final pathsToSend = attachmentPaths.take(5);
        for (final path in pathsToSend) {
          final fileName = path.split(RegExp(r'[\\/]')).last;
          formData.files.add(MapEntry(
            'attachments[]',
            await MultipartFile.fromFile(path, filename: fileName),
          ));
        }
        postData = formData;
      } else {
        postData = {
          'content': content,
          'message_type': 'outgoing',
          'private': isPrivate,
          if (echoId != null) 'echo_id': echoId,
          if (inReplyToId != null)
            'content_attributes': {
              'in_reply_to': inReplyToId,
            },
        };
      }

      final response = await _api.post(
        'conversations/$conversationId/messages',
        data: postData,
      );

      final resData = response.data;
      final msgMap = (resData is Map && resData['data'] is Map)
          ? resData['data']
          : (resData is Map ? resData : <String, dynamic>{});
      final message = Message.fromJson(Map<String, dynamic>.from(msgMap));
      return Right(message);
    } on DioException catch (e) {
      return Left(ServerFailure(e.message ?? 'فشل في إرسال الرسالة'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Message>> sendTemplateMessage({
    required int conversationId,
    required String templateName,
    required String category,
    required String language,
    required String content,
    Map<String, dynamic>? processedParams,
  }) async {
    try {
      final postData = {
        'content': content,
        'message_type': 'outgoing',
        'private': false,
        'echo_id': 'flutter-template-${DateTime.now().millisecondsSinceEpoch}',
        'template_params': {
          'name': templateName,
          'category': category,
          'language': language,
          'processed_params': processedParams ?? {},
        },
      };

      final response = await _api.post(
        'conversations/$conversationId/messages',
        data: postData,
      );

      final resData = response.data;
      final msgMap = (resData is Map && resData['data'] is Map)
          ? resData['data']
          : (resData is Map ? resData : <String, dynamic>{});
      final message = Message.fromJson(Map<String, dynamic>.from(msgMap));
      return Right(message);
    } on DioException catch (e) {
      return Left(ServerFailure(e.message ?? 'فشل في إرسال رسالة القالب'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Message>> editMessage({
    required int conversationId,
    required int messageId,
    required String content,
  }) async {
    try {
      final response = await _api.patch(
        'conversations/$conversationId/messages/$messageId',
        data: {'content': content},
      );
      final resData = response.data;
      final msgMap = (resData is Map && resData['data'] is Map)
          ? resData['data']
          : (resData is Map ? resData : <String, dynamic>{});
      final message = Message.fromJson(Map<String, dynamic>.from(msgMap));
      return Right(message);
    } on DioException catch (e) {
      final res = e.response?.data;
      final serverMsg = res is Map
          ? (res['message'] ?? res['error'])?.toString()
          : null;
      return Left(ServerFailure(serverMsg ?? e.message ?? 'فشل في تعديل الرسالة'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Message>> deleteMessage({
    required int conversationId,
    required int messageId,
    bool everyone = true,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (everyone) {
        queryParams['scope'] = 'everyone';
      }
      final response = await _api.delete(
        'conversations/$conversationId/messages/$messageId',
        queryParameters: queryParams,
      );
      final resData = response.data;
      final msgMap = (resData is Map && resData['payload'] is Map)
          ? resData['payload']
          : ((resData is Map && resData['data'] is Map)
              ? resData['data']
              : (resData is Map ? resData : <String, dynamic>{}));
      final message = Message.fromJson(Map<String, dynamic>.from(msgMap));
      return Right(message);
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) {
        return const Left(ServerFailure('غير مصرح لك بحذف هذه الرسالة'));
      }
      if (e.response?.statusCode == 422) {
        final res = e.response?.data;
        final serverMsg = res is Map
            ? (res['message'] ?? res['error'])?.toString()
            : null;
        return Left(ServerFailure(serverMsg ?? 'تعذر حذف الرسالة'));
      }
      final res = e.response?.data;
      final serverMsg = res is Map
          ? (res['message'] ?? res['error'])?.toString()
          : null;
      return Left(ServerFailure(serverMsg ?? e.message ?? 'فشل في حذف الرسالة'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Message>> sendReaction({
    required int conversationId,
    required int messageId,
    required String emoji,
  }) async {
    try {
      final response = await _api.put(
        'conversations/$conversationId/messages/$messageId/reaction',
        data: {'emoji': emoji},
      );
      final resData = response.data;
      final msgMap = (resData is Map && resData['data'] is Map)
          ? resData['data']
          : (resData is Map ? resData : <String, dynamic>{});
      final message = Message.fromJson(Map<String, dynamic>.from(msgMap));
      return Right(message);
    } on DioException catch (e) {
      final res = e.response?.data;
      final serverMsg = res is Map
          ? (res['message'] ?? res['error'])?.toString()
          : null;
      return Left(ServerFailure(serverMsg ?? e.message ?? 'فشل في إضافة التفاعل'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ReactionParticipant>>> getReactions({
    required int conversationId,
    required int messageId,
    Map<String, dynamic>? contentAttributes,
  }) async {
    try {
      final response = await _api.get(
        'conversations/$conversationId/messages/$messageId/reactions',
      );
      final data = response.data;
      final rawParticipants = data is Map ? (data['participants'] ?? data['data']) : data;

      final actorToEmoji = <String, String>{};
      final rawReactions = contentAttributes?['reactions'] ?? (data is Map ? data['reactions'] : null);
      if (rawReactions is List) {
        for (final r in rawReactions) {
          if (r is Map) {
            final emoji = r['emoji']?.toString() ?? '';
            final actor = r['actor']?.toString();
            if (actor != null && emoji.isNotEmpty) {
              actorToEmoji[actor] = emoji;
            }
          }
        }
      }

      final list = <ReactionParticipant>[];
      if (rawParticipants is List) {
        for (final p in rawParticipants) {
          if (p is Map) {
            final pMap = Map<String, dynamic>.from(p);
            final actorKey = pMap['actor']?.toString() ??
                (pMap['type'] != null && pMap['id'] != null ? '${pMap['type']}:${pMap['id']}' : null);
            final emoji = actorToEmoji[actorKey] ?? pMap['emoji']?.toString();
            list.add(ReactionParticipant.fromJson(pMap, emoji: emoji));
          }
        }
      }
      return Right(list);
    } on DioException catch (e) {
      final res = e.response?.data;
      final serverMsg = res is Map
          ? (res['message'] ?? res['error'])?.toString()
          : null;
      return Left(ServerFailure(serverMsg ?? e.message ?? 'فشل في عرض تفاصيل التفاعلات'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<MessageTemplate>>> fetchInboxTemplates(int inboxId) async {
    try {
      final response = await _api.get('inboxes/$inboxId/message_templates');
      final data = response.data;

      dynamic rawTemplates;
      if (data is Map) {
        rawTemplates = data['payload'] ??
            data['message_templates'] ??
            data['data']?['payload'] ??
            data['data'];
      } else if (data is List) {
        rawTemplates = data;
      }

      final list = <MessageTemplate>[];
      if (rawTemplates is List && rawTemplates.isNotEmpty) {
        for (final t in rawTemplates) {
          if (t is Map) {
            try {
              final tpl = MessageTemplate.fromJson(Map<String, dynamic>.from(t));
              if (tpl.name.isNotEmpty) {
                list.add(tpl);
              }
            } catch (_) {}
          }
        }
      }

      if (list.isEmpty) {
        try {
          final resFallback = await _api.get('inboxes/$inboxId');
          final dataFb = resFallback.data;
          final rawFb = dataFb is Map ? (dataFb['message_templates'] ?? dataFb['payload']?['message_templates']) : null;
          if (rawFb is List) {
            for (final t in rawFb) {
              if (t is Map) {
                try {
                  final tpl = MessageTemplate.fromJson(Map<String, dynamic>.from(t));
                  if (tpl.name.isNotEmpty) list.add(tpl);
                } catch (_) {}
              }
            }
          }
        } catch (_) {}
      }

      if (list.isNotEmpty) {
        MessageTemplateRegistry.registerAll(list);
        return Right(list);
      }

      return Right(_getDefaultApprovedTemplates());
    } catch (_) {
      return Right(_getDefaultApprovedTemplates());
    }
  }

  @override
  Future<Either<Failure, List<MessageTemplate>>> fetchConversationTemplates(int conversationId) async {
    try {
      final response = await _api.get('conversations/$conversationId/message_templates');
      final data = response.data;
      final rawTemplates = data is Map ? (data['payload'] ?? data['data']) : (data is List ? data : null);

      final list = <MessageTemplate>[];
      if (rawTemplates is List) {
        for (final t in rawTemplates) {
          if (t is Map) {
            try {
              final tpl = MessageTemplate.fromJson(Map<String, dynamic>.from(t));
              if (tpl.name.isNotEmpty) list.add(tpl);
            } catch (_) {}
          }
        }
      }

      if (list.isNotEmpty) {
        MessageTemplateRegistry.registerAll(list);
        return Right(list);
      }
      return Right(_getDefaultApprovedTemplates());
    } catch (_) {
      return Right(_getDefaultApprovedTemplates());
    }
  }

  @override
  Future<Either<Failure, Message>> sendBrowserWhatsAppList({
    required int conversationId,
    required String templateId,
    required Map<String, dynamic> variables,
  }) async {
    try {
      final response = await _api.post(
        'conversations/$conversationId/messages/send_browser_whatsapp_list',
        data: {
          'template_id': templateId,
          'variables': variables,
        },
      );
      final resData = response.data;
      final msgMap = (resData is Map && resData['payload'] is Map)
          ? resData['payload']
          : (resData is Map ? resData : <String, dynamic>{});
      final message = Message.fromJson(Map<String, dynamic>.from(msgMap));
      return Right(message);
    } on DioException catch (e) {
      return Left(ServerFailure(e.message ?? 'فشل إرسال قائمة واتساب'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  static List<MessageTemplate> _getDefaultApprovedTemplates() {
    return [
      MessageTemplate(
        id: 100,
        name: 'first_subscription_25_nov2026',
        category: 'MARKETING',
        language: 'ar_EG',
        status: 'APPROVED',
        header: 'خصم 25% لفترة محدودة',
        body: 'أهلًا 👋\nلسه بتفكّر تبدأ مع *Message Pro*؟\nابدأ دلوقتي ووفر *ربع قيمة أول اشتراك* 🎉\n\nاختار الاشتراك *الشهري أو النصف سنوي (6 شهور)* واستفيد بخصم *25% على أول اشتراك فقط*.\n\n⏳ اشترك لحد *1 نوفمبر* للاستفادة بالعرض.\n\nشوف الأسعار بعد الخصم، واختار الباقة المناسبة لشغلك 👇',
        buttons: ['شوف الأسعار بعد الخصم', 'ساعدني أختار باقة', 'إيقاف العروض'],
        labels: ['marketing', 'offers'],
      ),
      MessageTemplate(
        id: 99,
        name: 'messagepro_connection_check_20261027',
        category: 'UTILITY',
        language: 'ar_EG',
        status: 'APPROVED',
        body: 'هذه رسالة اختبار ربط واتساب التي طلبتها من Message Pro.\nمرجع الاختبار: MP-20261027.\nلا يلزم اتخاذ أي إجراء.',
        buttons: [],
        labels: ['system', 'test'],
      ),
      MessageTemplate(
        id: 84,
        name: 'messagepro_requested_callback_utility_v1',
        category: 'UTILITY',
        language: 'ar_EG',
        status: 'APPROVED',
        body: 'أهلًا يا فندم، حاولنا نكلم حضرتك بخصوص المكالمة اللي طلبتها عن مسج برو. لو الوقت مش مناسب، ابعتلنا الوقت اللي يناسبك وهنكلمك 📞',
        buttons: [],
        labels: ['callbacks', 'support'],
      ),
      MessageTemplate(
        id: 69,
        name: 'messagepro_first_channel_offer_v1',
        category: 'MARKETING',
        language: 'ar_EG',
        status: 'APPROVED',
        header: 'عرض خاص ليك',
        body: 'مبروك ربط أول قناة 🎉\n\nتقدر تحصل على خصم *٢٠٪* على أول اشتراك في مسج برو لو اشتركت خلال *٧٢ ساعة* من دلوقتي. العرض متاح لغاية *٣٠ سبتمبر ٢٠٢٦ الساعة ١:٣٠ ظهرًا بتوقيت القاهرة*.\n\nحابب تستفيد من العرض؟ اضغط على «اطلب العرض» وهنساعدك تكمل.',
        footer: 'لإيقاف رسائل العروض، رد «إيقاف».',
        buttons: ['شوف الباقات', 'اطلب العرض'],
        labels: ['marketing', 'offers'],
      ),
    ];
  }
}
