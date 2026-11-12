import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/constants/app_colors.dart';

class CannedResponsesSheet extends StatelessWidget {
  final List<Map<String, String>> responses;
  final Function(String content) onSelect;
  final void Function(String content, String? imageUrl)? onSelectResponse;

  const CannedResponsesSheet({
    super.key,
    required this.responses,
    required this.onSelect,
    this.onSelectResponse,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: 0.65.sh,
      ),
      padding: EdgeInsets.symmetric(vertical: 16.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'الردود الجاهزة (Canned Responses)',
                  style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: Icon(Icons.close, size: 22.r),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(),
          if (responses.isEmpty)
            Padding(
              padding: EdgeInsets.all(32.r),
              child: Center(child: Text('لا توجد ردود جاهزة حالياً', style: TextStyle(fontSize: 14.sp))),
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
                  final imageUrl = item['image_url'];
                  final hasImage = imageUrl != null && imageUrl.isNotEmpty;

                  return ListTile(
                    leading: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Text(
                        '/$code',
                        style: TextStyle(
                          color: AppColors.primaryLight,
                          fontWeight: FontWeight.bold,
                          fontSize: 12.sp,
                        ),
                      ),
                    ),
                    title: Text(
                      content,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 14.sp),
                    ),
                    trailing: hasImage
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(6.r),
                            child: CachedNetworkImage(
                              imageUrl: imageUrl,
                              width: 44.r,
                              height: 44.r,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => Container(
                                width: 44.r,
                                height: 44.r,
                                color: Colors.grey.withValues(alpha: 0.2),
                                child: const Center(child: SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 1.5))),
                              ),
                              errorWidget: (_, __, ___) => const Icon(Icons.image_not_supported_rounded, size: 20),
                            ),
                          )
                        : null,
                    onTap: () {
                      Navigator.pop(context);
                      if (onSelectResponse != null) {
                        onSelectResponse!(content, imageUrl);
                      } else {
                        onSelect(content);
                      }
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
