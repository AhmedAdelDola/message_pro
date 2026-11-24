import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../../core/config/app_config.dart';
import '../../../../../data/models/message.dart';
import 'bubble_helpers.dart';

class BubbleAdReferralCard extends StatelessWidget {
  final MessageReferral referral;
  final String? messageContent;
  final bool isDark;
  final bool isArabic;

  const BubbleAdReferralCard({
    super.key,
    required this.referral,
    this.messageContent,
    required this.isDark,
    required this.isArabic,
  });

  @override
  Widget build(BuildContext context) {
    final headline = (referral.headline != null && referral.headline!.trim().isNotEmpty)
        ? referral.headline!.trim()
        : (isArabic ? 'إعلان فيسبوك / واتساب' : 'Sponsored Meta Ad');
    final body = referral.body?.trim();
    final sourceUrl = referral.sourceUrl;
    final videoUrl = referral.videoUrl;
    final targetUrl = (sourceUrl != null && sourceUrl.isNotEmpty) ? sourceUrl : videoUrl;
    final isVideo = referral.mediaType == 'video' || (videoUrl != null && videoUrl.isNotEmpty);

    String? imageUrl = referral.imageUrl?.trim();
    if (imageUrl != null && imageUrl.isNotEmpty && imageUrl.startsWith('/')) {
      imageUrl = '${AppConfig.defaultBaseUrl}$imageUrl';
    }

    final platformName = referral.platform?.toLowerCase() == 'facebook'
        ? (isArabic ? 'إعلان فيسبوك (واتساب)' : 'Facebook Ad (CTWA)')
        : (isArabic ? 'إعلان فيسبوك / واتساب' : 'Meta Ad');

    final dividerColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 220, maxWidth: 280),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (imageUrl != null && imageUrl.isNotEmpty)
            GestureDetector(
              onTap: () {
                if (targetUrl != null && targetUrl.isNotEmpty) {
                  final uri = Uri.tryParse(targetUrl);
                  if (uri != null) {
                    launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                }
              },
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CachedNetworkImage(
                      imageUrl: imageUrl,
                      height: 140,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        height: 140,
                        color: isDark ? const Color(0xFF262C36) : const Color(0xFFE2E8F0),
                        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                      ),
                      errorWidget: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  if (isVideo)
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 34,
                      ),
                    ),
                ],
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 6, 4, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    isVideo ? Icons.play_circle_outline_rounded : Icons.campaign_rounded,
                    size: 13,
                    color: const Color(0xFF1877F2),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    platformName,
                    style: const TextStyle(
                      color: Color(0xFF1877F2),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  if (targetUrl != null && targetUrl.isNotEmpty)
                    InkWell(
                      onTap: () {
                        final uri = Uri.tryParse(targetUrl);
                        if (uri != null) {
                          launchUrl(uri, mode: LaunchMode.externalApplication);
                        }
                      },
                      child: Row(
                        children: [
                          Text(
                            isArabic ? 'عرض الإعلان' : 'View Ad',
                            style: const TextStyle(
                              color: Color(0xFF2563EB),
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 2),
                          const Icon(Icons.open_in_new_rounded, size: 11, color: Color(0xFF2563EB)),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Builder(
                builder: (context) {
                  final isHeadAr = BubbleHelpers.isArabicText(headline);
                  return Align(
                    alignment: isHeadAr ? Alignment.centerRight : Alignment.centerLeft,
                    child: Text(
                      headline,
                      textDirection: isHeadAr ? TextDirection.rtl : TextDirection.ltr,
                      textAlign: isHeadAr ? TextAlign.right : TextAlign.left,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  );
                },
              ),
              if (body != null && body.isNotEmpty && body != messageContent) ...[
                const SizedBox(height: 3),
                Builder(
                  builder: (context) {
                    final isBodyAr = BubbleHelpers.isArabicText(body);
                    return Align(
                      alignment: isBodyAr ? Alignment.centerRight : Alignment.centerLeft,
                      child: Text(
                        body,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textDirection: isBodyAr ? TextDirection.rtl : TextDirection.ltr,
                        textAlign: isBodyAr ? TextAlign.right : TextAlign.left,
                        style: TextStyle(
                          fontSize: 11,
                          height: 1.3,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                    );
                  },
                ),
              ],
              Padding(
                padding: const EdgeInsets.only(top: 6, bottom: 2),
                child: Divider(
                  height: 1,
                  thickness: 0.8,
                  color: dividerColor,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
  }
}
