import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../../data/models/user.dart';

class ComposerSuggestionsPopup extends StatelessWidget {
  final String? suggestionTrigger;
  final String suggestionQuery;
  final List<Map<String, String>> cannedResponses;
  final List<User> agents;
  final bool isDark;
  final bool isArabic;
  final Color textPrimary;
  final Color textSecondary;
  final ValueChanged<Map<String, String>> onSelectCannedResponse;
  final ValueChanged<User> onSelectAgentMention;

  const ComposerSuggestionsPopup({
    super.key,
    required this.suggestionTrigger,
    required this.suggestionQuery,
    required this.cannedResponses,
    required this.agents,
    required this.isDark,
    required this.isArabic,
    required this.textPrimary,
    required this.textSecondary,
    required this.onSelectCannedResponse,
    required this.onSelectAgentMention,
  });

  @override
  Widget build(BuildContext context) {
    if (suggestionTrigger == null) return const SizedBox.shrink();

    final isSlash = suggestionTrigger == '/';

    if (isSlash) {
      final filtered = cannedResponses.where((c) {
        if (suggestionQuery.isEmpty) return true;
        final code = (c['short_code'] ?? '').toLowerCase();
        final content = (c['content'] ?? '').toLowerCase();
        return code.contains(suggestionQuery) || content.contains(suggestionQuery);
      }).toList();

      if (filtered.isEmpty) return const SizedBox.shrink();

      return Container(
        constraints: const BoxConstraints(maxHeight: 220),
        margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E2128) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? const Color(0xFF2E333D) : const Color(0xFFE2E8F0),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF282C35) : const Color(0xFFF8FAFC),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.bolt_rounded, size: 16, color: Color(0xFF4162E3)),
                  const SizedBox(width: 6),
                  Text(
                    isArabic ? 'الردود الجاهزة (${filtered.length})' : 'Canned Responses (${filtered.length})',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    isArabic ? 'اضغط للإدراج' : 'Tap to insert',
                    style: TextStyle(fontSize: 10.5, color: textSecondary),
                  ),
                ],
              ),
            ),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: filtered.length,
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  color: isDark ? const Color(0xFF2E333D) : const Color(0xFFF1F5F9),
                ),
                itemBuilder: (context, index) {
                  final item = filtered[index];
                  final code = item['short_code'] ?? '';
                  final content = item['content'] ?? '';
                  final rawFiles = item['files'] ?? '';
                  final imageUrl = item['image_url'];
                  final hasImage = (imageUrl != null && imageUrl.isNotEmpty) || rawFiles.isNotEmpty;

                  return InkWell(
                    onTap: () => onSelectCannedResponse(item),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF4162E3).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '/$code',
                              style: const TextStyle(
                                color: Color(0xFF4162E3),
                                fontWeight: FontWeight.bold,
                                fontSize: 11.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              content,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                color: textPrimary,
                              ),
                            ),
                          ),
                          if (hasImage) ...[
                            const SizedBox(width: 8),
                            const Icon(Icons.image_outlined, size: 16, color: Color(0xFF4162E3)),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      );
    } else {
      // Agent Mentions (@)
      final filtered = agents.where((a) {
        if (suggestionQuery.isEmpty) return true;
        final name = a.name.toLowerCase();
        final email = a.email.toLowerCase();
        return name.contains(suggestionQuery) || email.contains(suggestionQuery);
      }).toList();

      if (filtered.isEmpty) return const SizedBox.shrink();

      return Container(
        constraints: const BoxConstraints(maxHeight: 220),
        margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E2128) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? const Color(0xFF2E333D) : const Color(0xFFE2E8F0),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF282C35) : const Color(0xFFF8FAFC),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.alternate_email_rounded, size: 16, color: Color(0xFF10B981)),
                  const SizedBox(width: 6),
                  Text(
                    isArabic ? 'منشن أعضاء الفريق (${filtered.length})' : 'Mention Team Member (${filtered.length})',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: filtered.length,
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  color: isDark ? const Color(0xFF2E333D) : const Color(0xFFF1F5F9),
                ),
                itemBuilder: (context, index) {
                  final agent = filtered[index];
                  return InkWell(
                    onTap: () => onSelectAgentMention(agent),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: const Color(0xFF4162E3).withValues(alpha: 0.15),
                            backgroundImage: agent.avatarUrl != null && agent.avatarUrl!.isNotEmpty
                                ? CachedNetworkImageProvider(agent.avatarUrl!)
                                : null,
                            child: agent.avatarUrl == null || agent.avatarUrl!.isEmpty
                                ? Text(
                                    agent.name.isNotEmpty ? agent.name[0].toUpperCase() : '?',
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF4162E3)),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  agent.name,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: textPrimary,
                                  ),
                                ),
                                if (agent.email.isNotEmpty)
                                  Text(
                                    agent.email,
                                    style: TextStyle(fontSize: 11, color: textSecondary),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      );
    }
  }
}
