import 'package:flutter/foundation.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../core/config/app_config.dart';
import '../../core/error/failures.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/secure_storage_service.dart';
import '../models/conversation.dart';
import '../models/message.dart';
import '../models/contact.dart';
import '../models/user.dart';
import '../models/message_template.dart';
import '../models/message_template_registry.dart';

abstract class IConversationRepository {
  Future<Either<Failure, List<Conversation>>> getConversations({
    String status = 'open',
    String assigneeType = 'me',
    int? inboxId,
    int? teamId,
    String? label,
    int page = 1,
  });
  Future<Either<Failure, List<Conversation>>> searchConversations(String query, {int page = 1});
  Future<Either<Failure, Conversation>> getConversation(int conversationId);
  Future<Either<Failure, List<Message>>> getMessages(int conversationId, {int? beforeId});
  Future<Either<Failure, Message>> sendMessage({
    required int conversationId,
    required String content,
    bool isPrivate = false,
    List<String>? attachmentPaths,
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
  Future<Either<Failure, Contact>> getCollaborators(int conversationId);
  Future<Either<Failure, Contact>> addCollaborator(int conversationId, int userId);
  Future<Either<Failure, Contact>> removeCollaborator(int conversationId, int userId);
  Future<Either<Failure, List<Map<String, dynamic>>>> getContactableInboxes(int contactId);
  Future<Either<Failure, List<Map<String, dynamic>>>> getPhoneDestinations({String? phoneNumber});
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
  Future<Either<Failure, void>> pinConversation(int conversationId);
  Future<Either<Failure, void>> unpinConversation(int conversationId);
  Future<Either<Failure, void>> assignTeam(int conversationId, int? teamId);
  Future<Either<Failure, void>> updateLabels(int conversationId, List<String> labels);
  Future<Either<Failure, void>> updateLifecycleStage(int conversationId, int stageId);
  Future<Either<Failure, void>> muteConversation(int conversationId);
  Future<Either<Failure, void>> unmuteConversation(int conversationId);
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
  final SecureStorageService _storage = SecureStorageService();

  ConversationRepository({ApiClient? api}) : _api = api ?? ApiClient();

  @override
  Future<Either<Failure, List<Conversation>>> getConversations({
    String status = 'open',
    String assigneeType = 'me',
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
        'sort_by': 'last_activity_at_desc',
      };

      if (inboxId != null) params['inbox_id'] = inboxId;
      if (teamId != null) params['team_id'] = teamId;
      if (label != null) params['labels[]'] = label;

      final response = await _api.get('conversations', queryParameters: params);
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

      final activeAccId = await _storage.getActiveAccountId();
      final conversations = <Conversation>[];
      for (final item in list) {
        if (item is Map) {
          try {
            final conv = Conversation.fromJson(Map<String, dynamic>.from(item));
            if (conv.id > 0) {
              if (activeAccId != null && activeAccId > 0 && conv.accountId > 0 && conv.accountId != activeAccId) {
                continue; // Skip conversation belonging to another workspace!
              }
              conversations.add(conv);
            }
          } catch (e, stack) {
            debugPrint('Error parsing conversation: $e\n$stack');
          }
        }
      }
      return Right(conversations);
    } on DioException catch (e) {
      return Left(ServerFailure(e.message ?? 'فشل في تحميل المحادثات'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Conversation>>> searchConversations(String query, {int page = 1}) async {
    try {
      final response = await _api.get('conversations/search', queryParameters: {
        'q': query,
        'page': page,
      });
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

      final conversations = <Conversation>[];
      for (final item in list) {
        if (item is Map) {
          try {
            final conv = Conversation.fromJson(Map<String, dynamic>.from(item));
            if (conv.id > 0) {
              conversations.add(conv);
            }
          } catch (_) {
            // Skip corrupted item
          }
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
  Future<Either<Failure, Conversation>> getConversation(int conversationId) async {
    try {
      final response = await _api.get('conversations/$conversationId');
      final data = response.data;
      Map<String, dynamic>? item;
      if (data is Map && data['data'] != null && data['data']['payload'] != null) {
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
  Future<Either<Failure, List<Message>>> getMessages(int conversationId, {int? beforeId}) async {
    try {
      final params = <String, dynamic>{};
      if (beforeId != null) {
        params['before'] = beforeId;
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

      final messages = <Message>[];
      for (final item in list) {
        if (item is Map) {
          try {
            messages.add(Message.fromJson(Map<String, dynamic>.from(item)));
          } catch (e) {
            // Skip corrupted message
          }
        }
      }
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
        formData.fields.add(const MapEntry('message_type', 'outgoing'));
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
          'message_type': 'outgoing',
          'private': isPrivate,
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
  Future<Either<Failure, List<MessageTemplate>>> fetchInboxTemplates(int inboxId) async {
    try {
      // Direct endpoint: GET /api/v1/accounts/:account_id/inboxes/:inbox_id/message_templates
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

      // If endpoint was empty or failed, also check inboxes/$inboxId fallback
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
      // Endpoint: GET /api/v1/accounts/:account_id/conversations/:conversation_id/message_templates
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

  @override
  Future<Either<Failure, Contact>> getCollaborators(int conversationId) async {
    try {
      final response = await _api.get('conversations/$conversationId/collaborators');
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return Right(Contact.fromJson(data));
      } else if (data is Map) {
        return Right(Contact.fromJson(Map<String, dynamic>.from(data)));
      }
      return Left(ServerFailure('Invalid response for collaborators'));
    } on DioException catch (e) {
      return Left(ServerFailure(e.message ?? 'فشل تحميل المتعاونين'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Contact>> addCollaborator(int conversationId, int userId) async {
    try {
      final response = await _api.post(
        'conversations/$conversationId/collaborators',
        data: {'user_id': userId},
      );
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return Right(Contact.fromJson(data));
      } else if (data is Map) {
        return Right(Contact.fromJson(Map<String, dynamic>.from(data)));
      }
      return Left(ServerFailure('Invalid response'));
    } on DioException catch (e) {
      return Left(ServerFailure(e.message ?? 'فشل إضافة المتعاون'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Contact>> removeCollaborator(int conversationId, int userId) async {
    try {
      final response = await _api.delete('conversations/$conversationId/collaborators/$userId');
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return Right(Contact.fromJson(data));
      } else if (data is Map) {
        return Right(Contact.fromJson(Map<String, dynamic>.from(data)));
      }
      return Left(ServerFailure('Invalid response'));
    } on DioException catch (e) {
      return Left(ServerFailure(e.message ?? 'فشل حذف المتعاون'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getContactableInboxes(int contactId) async {
    try {
      final response = await _api.get('contacts/$contactId/contactable_inboxes');
      final data = response.data;
      final raw = data is Map ? (data['payload'] ?? data['data']) : (data is List ? data : null);
      if (raw is List) {
        return Right(raw.map((item) => Map<String, dynamic>.from(item as Map)).toList());
      }
      return const Right([]);
    } on DioException catch (e) {
      return Left(ServerFailure(e.message ?? 'فشل جلب القنوات المتاحة للعميل'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getPhoneDestinations({String? phoneNumber}) async {
    try {
      final query = <String, dynamic>{};
      if (phoneNumber != null && phoneNumber.trim().isNotEmpty) {
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
        query['phone_number'] = cleanPhone;
      }

      final response = await _api.get(
        'inboxes/phone_destinations',
        queryParameters: query.isNotEmpty ? query : null,
      );

      final data = response.data;
      List rawList = [];
      if (data is List) {
        rawList = data;
      } else if (data is Map && data['payload'] is List) {
        rawList = data['payload'];
      } else if (data is Map && data['data'] is List) {
        rawList = data['data'];
      }

      final results = rawList.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      return Right(results);
    } on DioException catch (e) {
      return Left(ServerFailure(e.message ?? 'فشل في تحميل وجهات القنوات المتاحة'));
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

      // 1. Check if contact exists
      int? contactId;
      try {
        final searchRes = await _api.get('contacts/search', queryParameters: {'q': cleanPhone});
        final sData = searchRes.data;
        List cList = [];
        if (sData is Map && sData['payload'] is List) {
          cList = sData['payload'];
        } else if (sData is List) {
          cList = sData;
        }

        if (cList.isNotEmpty) {
          final first = cList.first;
          contactId = first['id'] is int ? first['id'] : int.tryParse(first['id']?.toString() ?? '');
        }
      } catch (_) {}

      // 2. If contact does not exist, create contact
      if (contactId == null || contactId <= 0) {
        final createRes = await _api.post('contacts', data: {
          'name': (contactName != null && contactName.trim().isNotEmpty) ? contactName.trim() : cleanPhone,
          'phone_number': cleanPhone,
        });
        final cData = createRes.data;
        final cObj = (cData is Map && cData['payload']?['contact'] != null)
            ? cData['payload']['contact']
            : (cData is Map && cData['contact'] != null ? cData['contact'] : cData);
        contactId = cObj is Map ? (cObj['id'] is int ? cObj['id'] : int.tryParse(cObj['id']?.toString() ?? '')) : null;
      }

      if (contactId == null || contactId <= 0) {
        return Left(ServerFailure('تعذر تحديد أو إنشاء جهة الاتصال للرقم $cleanPhone'));
      }

      // 3. Ensure contact_inbox is registered
      try {
        await _api.post('contacts/$contactId/contact_inboxes', data: {
          'inbox_id': inboxId,
          'source_id': sourceId,
        });
      } catch (_) {}

      // 4. POST /api/v1/accounts/:account_id/conversations without message parameter
      final convRes = await _api.post('conversations', data: {
        'contact_id': contactId,
        'inbox_id': inboxId,
        'source_id': sourceId,
      });

      final convData = convRes.data;
      final rawConv = convData is Map ? (convData['payload'] ?? convData['data'] ?? convData) : null;
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
      // 1. Normalize sourceId (clean phone number)
      String cleanSource = sourceId.trim();
      if (cleanSource.startsWith('01') && cleanSource.length == 11) {
        cleanSource = '+2$cleanSource';
      } else if (cleanSource.startsWith('201') && cleanSource.length == 12) {
        cleanSource = '+$cleanSource';
      }

      // 2. Ensure contact has a contact_inbox linked to this inbox
      try {
        await _api.post('contacts/$contactId/contact_inboxes', data: {
          'inbox_id': inboxId,
          'source_id': cleanSource,
        });
      } catch (_) {
        // If it already exists or returns 422, proceed to conversation creation
      }

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
      final rawConv = data is Map ? (data['payload'] ?? data['data'] ?? data) : null;
      if (rawConv is Map) {
        return Right(Conversation.fromJson(Map<String, dynamic>.from(rawConv)));
      }
      return Left(ServerFailure('فشل بدء المحادثة'));
    } on DioException catch (e) {
      String errMsg = 'فشل إنشاء المحادثة';
      if (e.response?.data is Map) {
        final d = e.response!.data as Map;
        errMsg = d['message']?.toString() ??
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

  List<MessageTemplate> _getDefaultApprovedTemplates() {
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
      MessageTemplate(
        id: 64,
        name: 'messagepro_growth_advanced_25_48h',
        category: 'MARKETING',
        language: 'ar_EG',
        status: 'APPROVED',
        body: '🔥 *لمدة ٤٨ ساعة: خصم ٢٥٪ على Growth وAdvanced من Message Pro*\n\nاجمع محادثات عملائك في مكان واحد، وخلّي فريقك يعرف مين مسؤول عن كل محادثة وإيه الخطوة الجاية. ومع الأتمتة والـAI، تقدر تنظم الردود والمتابعة حسب طريقة شغلك.\n\nاستخدم كود *SAMPLE25* قبل *29 سبتمبر 2026 الساعة 6 مساءً بتوقيت القاهرة*.\n\n*رد «ابدأ»* وهنساعدك تختار الباقة وتجهّز حسابك. ولو عندك سؤال قبل الاشتراك، ابعته هنا.',
        footer: 'لإيقاف رسائل العروض، رد «إيقاف».',
        buttons: [],
        labels: ['marketing'],
      ),
      MessageTemplate(
        id: 65,
        name: 'messagepro_growth_advanced_25_48h_v2',
        category: 'MARKETING',
        language: 'ar_EG',
        status: 'APPROVED',
        header: 'خصم ٢٥٪ لمدة ٤٨ ساعة',
        body: 'العرض على باقتي *Growth* و*Advanced* من Message Pro.\n\nاجمع محادثات عملائك في مكان واحد، وخلّي فريقك يعرف مين مسؤول عن كل محادثة وإيه الخطوة الجاية. ومع الأتمتة والـAI، تقدر تنظم الردود والمتابعة حسب طريقة شغلك.\n\nاستخدم كود *SAMPLE25* قبل *29 سبتمبر 2026 الساعة 6 مساءً بتوقيت القاهرة*.\n\n*رد «ابدأ»* وهنساعدك تختار الباقة وتجهّز حسابك. ولو عندك سؤال قبل الاشتراك، ابعته هنا.',
        footer: 'لإيقاف رسائل العروض، رد «إيقاف».',
        buttons: [],
        labels: ['marketing'],
      ),
      MessageTemplate(
        id: 66,
        name: 'messagepro_growth_advanced_25_48h_v3',
        category: 'MARKETING',
        language: 'ar_EG',
        status: 'APPROVED',
        header: 'خصم ٢٥٪ لمدة ٤٨ ساعة',
        body: 'عرض على باقتي *Growth* و*Advanced* من مسج برو.\n\nاجمع محادثات عملائك في مكان واحد، وخلّي فريقك عارف مين بيتابع كل عميل. سرّع الردود بالـAI والأتمتة، وابعت عروضك وتحديثاتك لعملائك بالرسائل الجماعية، وانقل البيزنس بتاعك لنقطة احترافية.\n\nاستخدم كود *MP25*\nقبل *٢٩ سبتمبر ٢٠٢٦ الساعة ٩ صباحًا بتوقيت القاهرة*.\n\nمستني إيه؟ ابدأ دلوقتي 👇',
        footer: 'لإيقاف رسائل العروض، رد «إيقاف».',
        buttons: ['سجّل الآن', 'طلب مكالمة', 'تفاصيل'],
        labels: ['marketing'],
      ),
      MessageTemplate(
        id: 82,
        name: 'messagepro_inquiry_received_utility_v1',
        category: 'MARKETING',
        language: 'ar_EG',
        status: 'APPROVED',
        body: 'أهلًا يا فندم 👋 بنأكد استلام استفسارك عن مسج برو. هنرد عليك هنا، ولو في تفاصيل تحب تضيفها ابعتها في الشات.',
        buttons: [],
        labels: ['inquiry'],
      ),
      MessageTemplate(
        id: 74,
        name: 'messagepro_lead_followup_callback_v1',
        category: 'MARKETING',
        language: 'ar_EG',
        status: 'APPROVED',
        body: 'أهلًا يا فندم، كنت بحاول أتواصل مع حضرتك بخصوص مسج برو. تحب أكلمك في وقت يناسبك تكون متاح فيه؟ 📞',
        buttons: [],
        labels: ['followup'],
      ),
      MessageTemplate(
        id: 73,
        name: 'messagepro_lead_followup_details_v1',
        category: 'MARKETING',
        language: 'ar_EG',
        status: 'APPROVED',
        body: 'أهلًا يا فندم، هل التفاصيل واضحة لحضرتك؟ لو في أي سؤال أو حابب ندخل ميتنج نشرح فيه النظام، ابعتلنا هنا 📅',
        buttons: [],
        labels: ['followup'],
      ),
      MessageTemplate(
        id: 72,
        name: 'messagepro_lead_followup_interest_v1',
        category: 'MARKETING',
        language: 'ar_EG',
        status: 'APPROVED',
        body: 'أهلًا يا فندم 👋 حبيت أتابع مع حضرتك بخصوص مسج برو. هل لسه مناسب ليك نكمل الكلام عن الخدمة؟ لو عندك أي سؤال، ابعته هنا وهنرد عليك.',
        buttons: [],
        labels: ['followup'],
      ),
      MessageTemplate(
        id: 67,
        name: 'messagepro_pharmacies_followup_v1',
        category: 'MARKETING',
        language: 'ar_EG',
        status: 'APPROVED',
        header: 'نظّم رسائل صيدليتك وفروعها',
        body: '💊 مع مسج برو، اجمع محادثات عملائك في مكان واحد، ووجّه كل محادثة للفرع أو الموظف المناسب. سواء فريقك بيرد من داخل الصيدلية أو من كول سنتر منفصل، تاريخ الكلام واضح والكل عارف مين بيتابع العميل، حتى لو الشفت اتغيّر.\n\nسرّع الردود بالـAI والأتمتة والردود الجاهزة، وابعت عروضك وتحديثاتك لعملائك بالرسائل الجماعية.\n\nحابب تشوف ده على شغل صيدليتك؟ اختار اللي يناسبك 👇',
        footer: 'لإيقاف رسائل العروض، رد «إيقاف».',
        buttons: ['تجربة مجانية', 'احجز ديمو', 'اطلب مكالمة', 'تفاصيل أكتر'],
        labels: ['pharmacies'],
      ),
      MessageTemplate(
        id: 83,
        name: 'messagepro_requested_details_utility_v1',
        category: 'UTILITY',
        language: 'ar_EG',
        status: 'APPROVED',
        body: 'أهلًا يا فندم، التفاصيل اللي طلبتها عن مسج برو بعتناها لحضرتك. لو في أي نقطة محتاجة توضيح، ابعتلنا هنا وهنوضحها.',
        buttons: [],
        labels: ['details'],
      ),
      MessageTemplate(
        id: 68,
        name: 'messagepro_signup_welcome_7d_v1',
        category: 'MARKETING',
        language: 'ar_EG',
        status: 'APPROVED',
        header: 'أهلًا بيك في مسج برو',
        body: 'حسابك اتسجّل بنجاح 🎉 ومعاك تجربة مجانية لمدة ٧ أيام.\n\nتقدر دلوقتي تربط أول قناة لاستقبال رسائل عملائك، تضيف فريقك، وتعمل أول AI Agent يساعدك في الرد.\n\nلو محتاج مساعدة في أي خطوة، ابعتلنا هنا وهنساعدك.',
        footer: 'فريق مسج برو',
        buttons: ['ابدأ إعداد حسابك', 'محتاج مساعدة'],
        labels: ['welcome'],
      ),
      MessageTemplate(
        id: 70,
        name: 'messagepro_trial_ending_hours_v1',
        category: 'MARKETING',
        language: 'ar_EG',
        status: 'APPROVED',
        header: 'تجربتك المجانية قربت تخلص',
        body: 'فاضل *٤٨ ساعة* على انتهاء تجربتك المجانية في مسج برو.\n\nلو محتاج مساعدة في ربط القنوات أو تجهيز الفريق والـAI Agent، ابعتلنا هنا. ولو جاهز تكمل استخدام مسج برو، تقدر تختار الباقة المناسبة ليك.',
        footer: 'فريق مسج برو',
        buttons: ['شوف الباقات', 'محتاج مساعدة'],
        labels: ['trial'],
      ),
      MessageTemplate(
        id: 71,
        name: 'messagepro_trial_expired_feedback_v1',
        category: 'MARKETING',
        language: 'ar_EG',
        status: 'APPROVED',
        header: 'تجربتك المجانية انتهت',
        body: 'تجربتك المجانية في مسج برو انتهت. شكرًا إنك جرّبتنا 🙏\n\nحابين نسمع رأيك: إيه أكتر حاجة فادتك خلال التجربة، وإيه اللي تحب يكون أفضل؟ رد علينا هنا، ورأيك هيساعدنا نقدملك تجربة أنسب.\n\nولو حابب تكمل، تقدر تختار الباقة المناسبة ليك.',
        footer: 'فريق مسج برو',
        buttons: ['شوف الباقات', 'شارك رأيك'],
        labels: ['feedback'],
      ),
    ];
  }

  @override
  Future<Either<Failure, void>> toggleStatus(int conversationId, String status, {String? snoozedUntil}) async {
    try {
      final payload = <String, dynamic>{};
      if (status == 'snoozed') {
        payload['status'] = 'snoozed';
        if (snoozedUntil != null && snoozedUntil.isNotEmpty) {
          payload['snoozed_until'] = snoozedUntil;
        }
      } else if (status == 'open') {
        payload['status'] = 'open';
      }
      // Note: Passing 'status': 'resolved' causes Chatwoot backend to throw 500 Internal Server Error.
      // Calling toggle_status with empty payload {} cleanly triggers Chatwoot's toggle_status
      // action, resolving an open conversation.

      final response = await _api.post(
        'conversations/$conversationId/toggle_status',
        data: payload,
      );

      final currentStatus = response.data is Map && response.data['payload'] is Map
          ? response.data['payload']['current_status']?.toString()
          : null;

      if (status == 'resolved' && currentStatus != null && currentStatus != 'resolved') {
        // If the conversation was previously snoozed, the first toggle moved it to 'open'.
        // Toggle once more to transition it into 'resolved'.
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
  Future<Either<Failure, void>> assignAgent(int conversationId, int? agentId, {String? assigneeType}) async {
    try {
      final Map<String, dynamic> data;
      if (agentId == null) {
        data = {'assignee_id': null};
      } else {
        final type = assigneeType ?? (agentId < 0 ? 'AgentBot' : 'User');
        data = {
          'assignee_id': agentId.abs(),
          'assignee_type': type,
        };
      }

      await _api.post(
        'conversations/$conversationId/assignments',
        data: data,
      );
      return const Right(null);
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
      List list = data is Map && data['payload'] != null
          ? data['payload']
          : (data is Map && data['data'] != null && data['data']['payload'] != null
              ? data['data']['payload']
              : (data is Map && data['data'] is List
                  ? data['data']
                  : (data is List ? data : [])));
      return Right(list
          .whereType<Map>()
          .map((i) => Inbox.fromJson(Map<String, dynamic>.from(i)))
          .toList());
    } catch (_) {
      return const Right([]);
    }
  }

  @override
  Future<Either<Failure, List<Label>>> fetchLabels() async {
    try {
      final response = await _api.get('labels');
      final data = response.data;
      List list = data is Map && data['payload'] != null
          ? data['payload']
          : (data is Map && data['data'] != null && data['data']['payload'] != null
              ? data['data']['payload']
              : (data is Map && data['data'] is List
                  ? data['data']
                  : (data is List ? data : [])));
      return Right(list
          .whereType<Map>()
          .map((l) => Label.fromJson(Map<String, dynamic>.from(l)))
          .toList());
    } catch (_) {
      return const Right([]);
    }
  }

  @override
  Future<Either<Failure, List<LifecycleStage>>> fetchLifecycleStages() async {
    try {
      final response = await _api.get('lifecycle_stages');
      final data = response.data;
      List list = data is Map && data['payload'] != null
          ? data['payload']
          : (data is Map && data['data'] != null && data['data']['payload'] != null
              ? data['data']['payload']
              : (data is Map && data['data'] is List
                  ? data['data']
                  : (data is List ? data : [])));
      return Right(list
          .whereType<Map>()
          .map((s) => LifecycleStage.fromJson(Map<String, dynamic>.from(s)))
          .toList());
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
      List list = data is Map && data['payload'] != null
          ? data['payload']
          : (data is Map && data['data'] != null && data['data']['payload'] != null
              ? data['data']['payload']
              : (data is Map && data['data'] is List
                  ? data['data']
                  : (data is List ? data : [])));
      return Right(list
          .whereType<Map>()
          .map((t) => Team.fromJson(Map<String, dynamic>.from(t)))
          .toList());
    } catch (_) {
      return const Right([]);
    }
  }

  @override
  Future<Either<Failure, List<User>>> fetchAgents() async {
    try {
      final response = await _api.get('agents');
      final data = response.data;
      List list = data is Map && data['payload'] != null
          ? data['payload']
          : (data is Map && data['data'] != null && data['data']['payload'] != null
              ? data['data']['payload']
              : (data is Map && data['data'] is List
                  ? data['data']
                  : (data is List ? data : [])));
      return Right(list
          .whereType<Map>()
          .map((a) => User.fromJson(Map<String, dynamic>.from(a)))
          .toList());
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
      return Right(list.map<Map<String, String>>((c) {
        String mediaUrl = '';
        if (c['attachments'] is List && (c['attachments'] as List).isNotEmpty) {
          final first = c['attachments'][0];
          if (first is Map) {
            mediaUrl = (first['data_url'] ?? first['thumb_url'] ?? first['file_url'] ?? first['url'])?.toString() ?? '';
          } else if (first is String) {
            mediaUrl = first;
          }
        } else if (c['files'] is List && (c['files'] as List).isNotEmpty) {
          final first = c['files'][0];
          mediaUrl = first is Map ? (first['file_url'] ?? first['url'])?.toString() ?? '' : first.toString();
        } else if (c['image_url'] != null && c['image_url'].toString().isNotEmpty) {
          mediaUrl = c['image_url'].toString();
        } else if (c['media_url'] != null && c['media_url'].toString().isNotEmpty) {
          mediaUrl = c['media_url'].toString();
        }

        if (mediaUrl.isNotEmpty && mediaUrl.startsWith('/')) {
          mediaUrl = '${AppConfig.defaultBaseUrl}$mediaUrl';
        }

        return {
          'short_code': c['short_code']?.toString() ?? '',
          'content': c['content']?.toString() ?? '',
          'image_url': mediaUrl,
        };
      }).toList());
    } catch (_) {
      return const Right([
        {'short_code': 'hello', 'content': 'أهلاً بك! كيف يمكنني مساعدتك اليوم؟', 'image_url': ''},
        {'short_code': 'thanks', 'content': 'شكراً لتواصلك مع Message Pro!', 'image_url': ''},
        {'short_code': 'wait', 'content': 'يرجى الانتظار لحظات للتحقق من طلبك.', 'image_url': ''},
      ]);
    }
  }
}
