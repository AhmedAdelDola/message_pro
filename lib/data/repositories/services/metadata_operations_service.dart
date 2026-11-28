import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../core/config/app_config.dart';
import '../../../core/error/failures.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/performance_service.dart';
import '../../../core/storage/local_cache_service.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../../models/contact.dart';
import '../../models/conversation_filter_options.dart';
import '../../models/user.dart';
import '../interfaces/i_metadata_operations.dart';

class MetadataOperationsService implements IMetadataOperations {
  final ApiClient _api;
  final SecureStorageService _storage = SecureStorageService();

  List<Inbox>? _cachedInboxes;
  DateTime? _cachedInboxesTime;

  List<Label>? _cachedLabels;
  DateTime? _cachedLabelsTime;

  List<LifecycleStage>? _cachedStages;
  DateTime? _cachedStagesTime;

  List<Team>? _cachedTeams;
  DateTime? _cachedTeamsTime;

  List<Map<String, String>>? _cachedCannedResponses;
  DateTime? _cachedCannedResponsesTime;

  ConversationFilterOptions? _cachedFilterOptions;
  DateTime? _cachedFilterOptionsTime;

  MetadataOperationsService({ApiClient? api}) : _api = api ?? ApiClient();

  @override
  void clearCache() {
    _cachedInboxes = null;
    _cachedInboxesTime = null;
    _cachedLabels = null;
    _cachedLabelsTime = null;
    _cachedStages = null;
    _cachedStagesTime = null;
    _cachedTeams = null;
    _cachedTeamsTime = null;
    _cachedCannedResponses = null;
    _cachedCannedResponsesTime = null;
    _cachedFilterOptions = null;
    _cachedFilterOptionsTime = null;
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
  Future<Either<Failure, List<Inbox>>> fetchInboxes() async {
    if (_cachedInboxes != null && _cachedInboxesTime != null) {
      if (DateTime.now().difference(_cachedInboxesTime!).inMinutes < 5) {
        return Right(_cachedInboxes!);
      }
    }
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
      final parsed = list
          .whereType<Map>()
          .map((i) => Inbox.fromJson(Map<String, dynamic>.from(i)))
          .toList();
      _cachedInboxes = parsed;
      _cachedInboxesTime = DateTime.now();
      return Right(parsed);
    } catch (_) {
      if (_cachedInboxes != null) return Right(_cachedInboxes!);
      return const Right([]);
    }
  }

  @override
  Future<Either<Failure, List<Label>>> fetchLabels() async {
    if (_cachedLabels != null && _cachedLabelsTime != null) {
      if (DateTime.now().difference(_cachedLabelsTime!).inMinutes < 5) {
        return Right(_cachedLabels!);
      }
    }
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
      final parsed = list
          .whereType<Map>()
          .map((l) => Label.fromJson(Map<String, dynamic>.from(l)))
          .toList();
      _cachedLabels = parsed;
      _cachedLabelsTime = DateTime.now();
      return Right(parsed);
    } catch (_) {
      if (_cachedLabels != null) return Right(_cachedLabels!);
      return const Right([]);
    }
  }

  @override
  Future<Either<Failure, List<LifecycleStage>>> fetchLifecycleStages() async {
    if (_cachedStages != null && _cachedStagesTime != null) {
      if (DateTime.now().difference(_cachedStagesTime!).inMinutes < 5) {
        return Right(_cachedStages!);
      }
    }
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
      if (list.isNotEmpty) {
        final parsed = list
            .whereType<Map>()
            .map((s) => LifecycleStage.fromJson(Map<String, dynamic>.from(s)))
            .toList();
        _cachedStages = parsed;
        _cachedStagesTime = DateTime.now();
        return Right(parsed);
      }
    } catch (_) {}

    try {
      final response = await _api.get('custom_attribute_definitions');
      final data = response.data;
      List list = data is Map && data['payload'] != null
          ? data['payload']
          : (data is Map && data['data'] != null && data['data']['payload'] != null
              ? data['data']['payload']
              : (data is Map && data['data'] is List
                  ? data['data']
                  : (data is List ? data : [])));

      for (final item in list) {
        if (item is Map) {
          final key = item['attribute_key']?.toString().toLowerCase();
          if (key == 'lifecycle_stage' || key == 'lead_status' || key == 'stage') {
            final rawValues = item['attribute_values'];
            if (rawValues is List && rawValues.isNotEmpty) {
              final stages = <LifecycleStage>[];
              for (int i = 0; i < rawValues.length; i++) {
                final v = rawValues[i];
                if (v is Map) {
                  stages.add(LifecycleStage.fromJson(Map<String, dynamic>.from(v)));
                } else if (v is String && v.trim().isNotEmpty) {
                  final parsed = LifecycleStage.fromString(v);
                  stages.add(LifecycleStage(
                    id: i + 1,
                    name: parsed.name,
                    color: parsed.color,
                    icon: parsed.icon,
                  ));
                }
              }
              if (stages.isNotEmpty) {
                _cachedStages = stages;
                _cachedStagesTime = DateTime.now();
                return Right(stages);
              }
            }
          }
        }
      }
    } catch (_) {}

    if (_cachedStages != null) return Right(_cachedStages!);
    return const Right([]);
  }

  @override
  Future<Either<Failure, List<Team>>> fetchTeams() async {
    if (_cachedTeams != null && _cachedTeamsTime != null) {
      if (DateTime.now().difference(_cachedTeamsTime!).inMinutes < 5) {
        return Right(_cachedTeams!);
      }
    }
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
      final parsed = list
          .whereType<Map>()
          .map((t) => Team.fromJson(Map<String, dynamic>.from(t)))
          .toList();
      _cachedTeams = parsed;
      _cachedTeamsTime = DateTime.now();
      return Right(parsed);
    } catch (_) {
      if (_cachedTeams != null) return Right(_cachedTeams!);
      return const Right([]);
    }
  }

  @override
  Future<Either<Failure, List<User>>> fetchAgents() async {
    final activeAccId = await _storage.getActiveAccountId();
    if (activeAccId != null && activeAccId > 0) {
      final local = LocalCacheService().getCachedAgents(activeAccId);
      if (local.isNotEmpty) {
        // Fetch in background to update cache
        _api.get('agents').then((response) {
          final data = response.data;
          List list = data is Map && data['payload'] != null
              ? data['payload']
              : (data is Map && data['data'] != null && data['data']['payload'] != null
                  ? data['data']['payload']
                  : (data is Map && data['data'] is List ? data['data'] : (data is List ? data : [])));
          if (list.isNotEmpty) {
            LocalCacheService().saveAgents(activeAccId, list);
          }
        }).catchError((_) {});
        return Right(local);
      }
    }

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
      if (activeAccId != null && activeAccId > 0 && list.isNotEmpty) {
        LocalCacheService().saveAgents(activeAccId, list);
      }
      return Right(list
          .whereType<Map>()
          .map((a) => User.fromJson(Map<String, dynamic>.from(a)))
          .toList());
    } catch (_) {
      if (activeAccId != null && activeAccId > 0) {
        final local = LocalCacheService().getCachedAgents(activeAccId);
        if (local.isNotEmpty) return Right(local);
      }
      return const Right([]);
    }
  }

  final Map<String, DateTime> _lastAgentsFetchTime = {};

  @override
  Future<Either<Failure, List<User>>> fetchAssignableAgents({int? inboxId, List<int>? inboxIds}) async {
    final activeAccId = await _storage.getActiveAccountId();
    final cacheKey = 'acc_${activeAccId}_inbox_$inboxId';

    if (activeAccId != null && activeAccId > 0) {
      final local = LocalCacheService().getCachedAgents(activeAccId, inboxId: inboxId);
      if (local.isNotEmpty) {
        // Only trigger background revalidate if more than 3 minutes passed
        final lastFetch = _lastAgentsFetchTime[cacheKey];
        if (lastFetch == null || DateTime.now().difference(lastFetch).inMinutes >= 3) {
          _lastAgentsFetchTime[cacheKey] = DateTime.now();
          _backgroundFetchAssignableAgents(inboxId: inboxId, inboxIds: inboxIds, activeAccId: activeAccId);
        }
        return Right(local);
      }
    }

    _lastAgentsFetchTime[cacheKey] = DateTime.now();

    try {
      final List<int> ids = [];
      if (inboxId != null && inboxId > 0) {
        ids.add(inboxId);
      } else if (inboxIds != null && inboxIds.isNotEmpty) {
        ids.addAll(inboxIds);
      } else {
        final inboxesRes = await fetchInboxes();
        inboxesRes.fold((_) {}, (inboxes) => ids.addAll(inboxes.map((i) => i.id)));
      }

      String path = 'assignable_agents';
      if (ids.isNotEmpty) {
        final queryParams = ids.map((id) => 'inbox_ids[]=$id').join('&');
        path = '$path?$queryParams';
      }

      final response = await _api.get(path);
      final data = response.data;
      final List listData;
      if (data is List) {
        listData = data;
      } else if (data is Map && data['payload'] is List) {
        listData = data['payload'];
      } else if (data is Map && data['data'] is List) {
        listData = data['data'];
      } else {
        listData = [];
      }
      if (activeAccId != null && activeAccId > 0 && listData.isNotEmpty) {
        LocalCacheService().saveAgents(activeAccId, listData, inboxId: inboxId);
      }
      final agents = listData
          .whereType<Map>()
          .map((item) => User.fromJson(Map<String, dynamic>.from(item)))
          .toList();
      return Right(agents);
    } catch (_) {
      return fetchAgents();
    }
  }

  void _backgroundFetchAssignableAgents({int? inboxId, List<int>? inboxIds, required int activeAccId}) async {
    try {
      final List<int> ids = [];
      if (inboxId != null && inboxId > 0) {
        ids.add(inboxId);
      } else if (inboxIds != null && inboxIds.isNotEmpty) {
        ids.addAll(inboxIds);
      }
      String path = 'assignable_agents';
      if (ids.isNotEmpty) {
        final queryParams = ids.map((id) => 'inbox_ids[]=$id').join('&');
        path = '$path?$queryParams';
      }
      final response = await _api.get(path);
      final data = response.data;
      final List listData = data is List ? data : (data is Map && data['payload'] is List ? data['payload'] : []);
      if (listData.isNotEmpty) {
        LocalCacheService().saveAgents(activeAccId, listData, inboxId: inboxId);
      }
    } catch (_) {}
  }

  @override
  Future<Either<Failure, List<Map<String, String>>>> fetchCannedResponses() async {
    if (_cachedCannedResponses != null && _cachedCannedResponsesTime != null) {
      if (DateTime.now().difference(_cachedCannedResponsesTime!).inMinutes < 10) {
        return Right(_cachedCannedResponses!);
      }
    }
    try {
      final response = await _api.get('canned_responses');
      final data = response.data;
      List list = data is Map && data['payload'] != null ? data['payload'] : (data is List ? data : []);

      final base = await _storage.getBaseUrl();
      final uri = Uri.tryParse(base.isNotEmpty ? base : AppConfig.defaultBaseUrl);
      final domainRoot = uri != null ? '${uri.scheme}://${uri.host}${uri.hasPort ? ':${uri.port}' : ''}' : AppConfig.defaultBaseUrl;

      final result = list.whereType<Map>().map<Map<String, String>>((c) {
        final List<String> extractedUrls = [];

        void addUrl(dynamic u) {
          if (u == null) return;
          var str = u.toString().trim();
          if (str.isEmpty) return;
          if (str.startsWith('/')) {
            str = '$domainRoot$str';
          }
          if (!extractedUrls.contains(str)) {
            extractedUrls.add(str);
          }
        }

        void processAttachmentEntry(dynamic a) {
          if (a is Map) {
            addUrl(a['data_url'] ?? a['file_url'] ?? a['thumb_url'] ?? a['url'] ?? a['blob_url'] ?? a['download_url']);
          } else if (a is String) {
            addUrl(a);
          }
        }

        final possibleAttachmentKeys = [
          'media_attachments',
          'media_attachment',
          'attachments',
          'files',
          'attached_files',
          'media'
        ];

        for (final key in possibleAttachmentKeys) {
          final val = c[key];
          if (val is List) {
            for (final item in val) {
              processAttachmentEntry(item);
            }
          } else if (val != null) {
            processAttachmentEntry(val);
          }
        }

        addUrl(c['image_url']);
        addUrl(c['file_url']);
        addUrl(c['media_url']);
        addUrl(c['attachment_url']);
        addUrl(c['document_url']);

        final rawContent = c['content']?.toString() ?? '';
        final mdImgRegex = RegExp(r'!\[.*?\]\((https?://[^\s\)]+|/[^\s\)]+)\)');
        for (final m in mdImgRegex.allMatches(rawContent)) {
          addUrl(m.group(1));
        }

        final htmlImgRegex = RegExp(r'''<img[^>]+src=["'](https?://[^"']+|/[^"']+)["']''');
        for (final m in htmlImgRegex.allMatches(rawContent)) {
          addUrl(m.group(1));
        }

        final fileLinkRegex = RegExp(r'\[.*?\]\((https?://[^\s\)]+|/[^\s\)]+)\)');
        for (final m in fileLinkRegex.allMatches(rawContent)) {
          final u = m.group(1);
          if (u != null && (u.contains('.') || u.contains('rails/active_storage') || u.contains('download'))) {
            addUrl(u);
          }
        }

        String cleanContent = rawContent.replaceAll(mdImgRegex, '').replaceAll(htmlImgRegex, '').trim();
        if (cleanContent.isEmpty) cleanContent = rawContent;

        final firstImageUrl = extractedUrls.where((u) {
          final lower = u.toLowerCase();
          return lower.contains('.png') || lower.contains('.jpg') || lower.contains('.jpeg') ||
              lower.contains('.webp') || lower.contains('.gif') || lower.contains('image');
        }).firstOrNull ?? (extractedUrls.isNotEmpty ? extractedUrls.first : '');

        return {
          'short_code': c['short_code']?.toString() ?? '',
          'content': cleanContent,
          'raw_content': rawContent,
          'image_url': firstImageUrl,
          'files': extractedUrls.join('|||'),
          'file_count': extractedUrls.length.toString(),
        };
      }).toList();
      _cachedCannedResponses = result;
      _cachedCannedResponsesTime = DateTime.now();
      return Right(result);
    } catch (_) {
      if (_cachedCannedResponses != null) return Right(_cachedCannedResponses!);
      return const Right([]);
    }
  }

  @override
  Future<Either<Failure, ConversationFilterOptions>> fetchFilterOptions() async {
    if (_cachedFilterOptions != null && _cachedFilterOptionsTime != null) {
      if (DateTime.now().difference(_cachedFilterOptionsTime!).inMinutes < 5) {
        return Right(_cachedFilterOptions!);
      }
    }
    return PerformanceService.traceAsync<Either<Failure, ConversationFilterOptions>>(
      'server_fetch_filter_options',
      () async {
        try {
          final response = await _api.get('conversations/filter_options');
          final data = response.data;
          Map<String, dynamic>? jsonMap;
          if (data is Map) {
            if (data['payload'] is Map) {
              jsonMap = Map<String, dynamic>.from(data['payload']);
            } else if (data['data'] is Map) {
              jsonMap = Map<String, dynamic>.from(data['data']);
            } else {
              jsonMap = Map<String, dynamic>.from(data);
            }
          }
          if (jsonMap != null) {
            final parsed = ConversationFilterOptions.fromJson(jsonMap);
            _cachedFilterOptions = parsed;
            _cachedFilterOptionsTime = DateTime.now();
            return Right(parsed);
          }
          return const Right(ConversationFilterOptions());
        } on DioException catch (e) {
          if (_cachedFilterOptions != null) return Right(_cachedFilterOptions!);
          return Left(ServerFailure(e.message ?? 'فشل في تحميل خيارات الفلاتر'));
        } catch (e) {
          if (_cachedFilterOptions != null) return Right(_cachedFilterOptions!);
          return Left(ServerFailure(e.toString()));
        }
      },
    );
  }
}
