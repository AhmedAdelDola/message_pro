import 'contact.dart';
import 'user.dart';

class AiAgentItem {
  final int? id;
  final int agentBotId;
  final String name;
  final String? description;
  final String? avatarUrl;

  const AiAgentItem({
    this.id,
    required this.agentBotId,
    required this.name,
    this.description,
    this.avatarUrl,
  });

  factory AiAgentItem.fromJson(Map<String, dynamic> json) {
    final rawBotId = json['agent_bot_id'] ?? json['id'] ?? 0;
    final botId = rawBotId is int ? rawBotId : (int.tryParse(rawBotId.toString()) ?? 0);

    return AiAgentItem(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? ''),
      agentBotId: botId,
      name: json['name']?.toString() ?? 'AI Agent',
      description: json['description']?.toString(),
      avatarUrl: (json['avatar_url'] ?? json['thumbnail'])?.toString(),
    );
  }
}

class ConversationFilterOptions {
  final List<Inbox> inboxes;
  final List<User> agents;
  final List<AiAgentItem> aiAgents;
  final List<Team> teams;
  final bool canFilterAgents;

  const ConversationFilterOptions({
    this.inboxes = const [],
    this.agents = const [],
    this.aiAgents = const [],
    this.teams = const [],
    this.canFilterAgents = false,
  });

  factory ConversationFilterOptions.fromJson(Map<String, dynamic> json) {
    final inboxesList = <Inbox>[];
    if (json['inboxes'] is List) {
      for (final item in json['inboxes']) {
        if (item is Map) {
          try {
            inboxesList.add(Inbox.fromJson(Map<String, dynamic>.from(item)));
          } catch (_) {}
        }
      }
    }

    final agentsList = <User>[];
    if (json['agents'] is List) {
      for (final item in json['agents']) {
        if (item is Map) {
          try {
            agentsList.add(User.fromJson(Map<String, dynamic>.from(item)));
          } catch (_) {}
        }
      }
    }

    final aiAgentsList = <AiAgentItem>[];
    if (json['ai_agents'] is List) {
      for (final item in json['ai_agents']) {
        if (item is Map) {
          try {
            aiAgentsList.add(AiAgentItem.fromJson(Map<String, dynamic>.from(item)));
          } catch (_) {}
        }
      }
    }

    final teamsList = <Team>[];
    if (json['teams'] is List) {
      for (final item in json['teams']) {
        if (item is Map) {
          try {
            teamsList.add(Team.fromJson(Map<String, dynamic>.from(item)));
          } catch (_) {}
        }
      }
    }

    final canFilterRaw = json['can_filter_agents'];
    final canFilter = canFilterRaw == true || canFilterRaw.toString().toLowerCase() == 'true' || canFilterRaw == 1;

    return ConversationFilterOptions(
      inboxes: inboxesList,
      agents: agentsList,
      aiAgents: aiAgentsList,
      teams: teamsList,
      canFilterAgents: canFilter,
    );
  }
}
