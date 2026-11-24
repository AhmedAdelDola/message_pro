import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../utils/background_json_parser.dart';
import '../../data/models/contact.dart';
import '../../data/models/conversation.dart';
import '../../data/models/message.dart';
import '../../data/models/user.dart';

/// Embedded NoSQL high-performance cache service using Hive.
/// Provides sub-millisecond local reads and persistent offline support
/// following Stale-While-Revalidate caching patterns.
class LocalCacheService {
  static final LocalCacheService _instance = LocalCacheService._internal();
  factory LocalCacheService() => _instance;
  LocalCacheService._internal();

  static const String _conversationsBoxName = 'mp_conversations_cache';
  static const String _messagesBoxName = 'mp_messages_cache';
  static const String _metadataBoxName = 'mp_metadata_cache';
  static const String _contactsBoxName = 'mp_contacts_cache';
  static const String _agentsBoxName = 'mp_agents_cache';

  Box<dynamic>? _conversationsBox;
  Box<dynamic>? _messagesBox;
  Box<dynamic>? _metadataBox;
  Box<dynamic>? _contactsBox;
  Box<dynamic>? _agentsBox;
  bool _isInitialized = false;

  /// Initialize Hive and open essential cache boxes.
  static Future<void> init() async {
    if (_instance._isInitialized) return;
    try {
      await Hive.initFlutter();
      _instance._conversationsBox = await Hive.openBox<dynamic>(_conversationsBoxName);
      _instance._messagesBox = await Hive.openBox<dynamic>(_messagesBoxName);
      _instance._metadataBox = await Hive.openBox<dynamic>(_metadataBoxName);
      _instance._contactsBox = await Hive.openBox<dynamic>(_contactsBoxName);
      _instance._agentsBox = await Hive.openBox<dynamic>(_agentsBoxName);
      _instance._isInitialized = true;
      debugPrint('📦 [LocalCacheService] Hive initialized successfully with all boxes.');
    } catch (e) {
      debugPrint('⚠️ [LocalCacheService] Hive initialization error: $e');
    }
  }

  // --- Conversations Cache ---

  /// Save raw conversation maps to Hive box for instant offline retrieval.
  Future<void> saveRawConversations(int accountId, List<dynamic> rawList) async {
    if (accountId <= 0 || _conversationsBox == null) return;
    try {
      final sanitized = rawList
          .whereType<Map>()
          .map((m) => Map<String, dynamic>.from(m))
          .take(60) // Keep top 60 recent conversations for fast startup
          .toList();
      await _conversationsBox!.put('acc_$accountId', sanitized);
    } catch (e) {
      debugPrint('⚠️ [LocalCacheService] Error saving conversations: $e');
    }
  }

  /// Get cached conversations parsed in background isolate for 0ms startup.
  Future<List<Conversation>> getCachedConversations(int accountId) async {
    if (accountId <= 0 || _conversationsBox == null) return const [];
    try {
      final raw = _conversationsBox!.get('acc_$accountId');
      if (raw is List && raw.isNotEmpty) {
        return await BackgroundJsonParser.parseConversations(raw);
      }
    } catch (e) {
      debugPrint('⚠️ [LocalCacheService] Error reading cached conversations: $e');
    }
    return const [];
  }

  // --- Messages Cache ---

  /// Save raw messages for a conversation to Hive box.
  Future<void> saveRawMessages(int conversationId, List<dynamic> rawList) async {
    if (conversationId <= 0 || _messagesBox == null) return;
    try {
      final sanitized = rawList
          .whereType<Map>()
          .map((m) => Map<String, dynamic>.from(m))
          .take(100) // Keep top 100 recent messages
          .toList();
      await _messagesBox!.put('conv_$conversationId', sanitized);
    } catch (e) {
      debugPrint('⚠️ [LocalCacheService] Error saving messages: $e');
    }
  }

  /// Get cached messages parsed in background isolate for instant chat rendering.
  Future<List<Message>> getCachedMessages(int conversationId) async {
    if (conversationId <= 0 || _messagesBox == null) return const [];
    try {
      final raw = _messagesBox!.get('conv_$conversationId');
      if (raw is List && raw.isNotEmpty) {
        return await BackgroundJsonParser.parseMessages(raw);
      }
    } catch (e) {
      debugPrint('⚠️ [LocalCacheService] Error reading cached messages: $e');
    }
    return const [];
  }

  // --- Metadata & Filter Options Cache ---

  Future<void> saveMetadata(String key, dynamic rawData) async {
    if (_metadataBox == null) return;
    try {
      await _metadataBox!.put(key, rawData);
    } catch (_) {}
  }

  dynamic getMetadata(String key) {
    if (_metadataBox == null) return null;
    try {
      return _metadataBox!.get(key);
    } catch (_) {
      return null;
    }
  }

  // --- Agents & Users Cache ---

  Future<void> saveAgents(int accountId, List<dynamic> rawList, {int? inboxId}) async {
    if (accountId <= 0 || _agentsBox == null) return;
    try {
      final key = inboxId != null ? 'agents_acc_${accountId}_inbox_$inboxId' : 'agents_acc_$accountId';
      final sanitized = rawList
          .whereType<Map>()
          .map((m) => Map<String, dynamic>.from(m))
          .toList();
      await _agentsBox!.put(key, sanitized);
    } catch (_) {}
  }

  List<User> getCachedAgents(int accountId, {int? inboxId}) {
    if (accountId <= 0 || _agentsBox == null) return const [];
    try {
      final key = inboxId != null ? 'agents_acc_${accountId}_inbox_$inboxId' : 'agents_acc_$accountId';
      var raw = _agentsBox!.get(key);
      if (raw == null && inboxId != null) {
        // Fallback to all workspace agents
        raw = _agentsBox!.get('agents_acc_$accountId');
      }
      if (raw is List) {
        return raw
            .whereType<Map>()
            .map((item) => User.fromJson(Map<String, dynamic>.from(item)))
            .toList();
      }
    } catch (_) {}
    return const [];
  }

  // --- Contacts Cache ---

  Future<void> saveContacts(int accountId, List<dynamic> rawList) async {
    if (accountId <= 0 || _contactsBox == null) return;
    try {
      final sanitized = rawList
          .whereType<Map>()
          .map((m) => Map<String, dynamic>.from(m))
          .take(150)
          .toList();
      await _contactsBox!.put('contacts_acc_$accountId', sanitized);
    } catch (_) {}
  }

  List<Contact> getCachedContacts(int accountId) {
    if (accountId <= 0 || _contactsBox == null) return const [];
    try {
      final raw = _contactsBox!.get('contacts_acc_$accountId');
      if (raw is List) {
        return raw
            .whereType<Map>()
            .map((item) => Contact.fromJson(Map<String, dynamic>.from(item)))
            .toList();
      }
    } catch (_) {}
    return const [];
  }

  // --- Cleanup ---

  Future<void> clearConversationCache(int conversationId) async {
    try {
      await _messagesBox?.delete('conv_$conversationId');
    } catch (_) {}
  }

  Future<void> clearAccountCache(int accountId) async {
    try {
      await _conversationsBox?.delete('acc_$accountId');
    } catch (_) {}
  }

  Future<void> clearAll() async {
    try {
      await _conversationsBox?.clear();
      await _messagesBox?.clear();
    } catch (_) {}
  }
}
