import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class CannedResponsesSheet extends StatelessWidget {
  final List<Map<String, String>> responses;
  final Function(String content) onSelect;

  const CannedResponsesSheet({
    super.key,
    required this.responses,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.65,
      ),
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'الردود الجاهزة (Canned Responses)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(),
          if (responses.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: Text('لا توجد ردود جاهزة حالياً')),
            )
          else
            Expanded(
              child: ListView.separated(
                itemCount: responses.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final item = responses[index];
                  final code = item['short_code'] ?? '';
                  final content = item['content'] ?? '';

                  return ListTile(
                    leading: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '/$code',
                        style: const TextStyle(
                          color: AppColors.primaryLight,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    title: Text(
                      content,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      onSelect(content);
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
