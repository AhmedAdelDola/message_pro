import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/services/link_preview_service.dart';
import '../../../../data/models/link_preview_metadata.dart';

class LinkPreviewCard extends StatefulWidget {
  final String url;
  final bool isOutgoing;
  final bool isDark;
  final LinkPreviewMetadata? initialMetadata;

  const LinkPreviewCard({
    super.key,
    required this.url,
    required this.isOutgoing,
    required this.isDark,
    this.initialMetadata,
  });

  @override
  State<LinkPreviewCard> createState() => _LinkPreviewCardState();
}

class _LinkPreviewCardState extends State<LinkPreviewCard> {
  LinkPreviewMetadata? _metadata;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _metadata = widget.initialMetadata ?? LinkPreviewService().getCached(widget.url);
    if (_metadata == null) {
      _loadMetadata();
    }
  }

  @override
  void didUpdateWidget(covariant LinkPreviewCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _metadata = widget.initialMetadata ?? LinkPreviewService().getCached(widget.url);
      if (_metadata == null) {
        _loadMetadata();
      }
    }
  }

  Future<void> _loadMetadata() async {
    if (_isLoading) return;
    _isLoading = true;
    final meta = await LinkPreviewService().fetchMetadata(widget.url);
    if (mounted) {
      setState(() {
        _metadata = meta;
        _isLoading = false;
      });
    }
  }

  Future<void> _openUrl() async {
    final rawUrl = _metadata?.url ?? widget.url;
    var u = rawUrl.trim();
    if (u.toLowerCase().startsWith('www.')) {
      u = 'https://$u';
    }
    final uri = Uri.tryParse(u);
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final meta = _metadata;
    // If no metadata or has no title/description/image, don't show an empty broken card
    if (meta == null || !meta.hasContent) {
      return const SizedBox.shrink();
    }

    final cardBg = widget.isOutgoing
        ? Colors.black.withValues(alpha: 0.18)
        : (widget.isDark ? const Color(0xFF1E2026) : const Color(0xFFF1F3F6));

    final borderColor = widget.isOutgoing
        ? Colors.white.withValues(alpha: 0.22)
        : (widget.isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFE2E4E8));

    final textPrimary = widget.isOutgoing
        ? Colors.white
        : (widget.isDark ? Colors.white : const Color(0xFF111827));

    final textSecondary = widget.isOutgoing
        ? Colors.white.withValues(alpha: 0.8)
        : (widget.isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280));

    final domainColor = widget.isOutgoing
        ? Colors.white.withValues(alpha: 0.9)
        : const Color(0xFF3B82F6);

    return Container(
      margin: const EdgeInsets.only(top: 4, bottom: 6),
      constraints: const BoxConstraints(maxWidth: 320),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: _openUrl,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Preview Image Banner
            if (meta.imageUrl != null && meta.imageUrl!.isNotEmpty)
              CachedNetworkImage(
                imageUrl: meta.imageUrl!,
                height: 140,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  height: 140,
                  color: widget.isOutgoing
                      ? Colors.white10
                      : (widget.isDark ? const Color(0xFF282A30) : const Color(0xFFE5E7EB)),
                  child: const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => const SizedBox.shrink(),
              ),

            // Card Text Details
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Domain / Source
                  if (meta.domain.isNotEmpty)
                    Row(
                      children: [
                        Icon(
                          Icons.link_rounded,
                          size: 13,
                          color: domainColor,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            meta.domain,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: domainColor,
                              letterSpacing: 0.4,
                              fontFamily: 'Gontserrat',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),

                  if (meta.domain.isNotEmpty && meta.title != null)
                    const SizedBox(height: 3),

                  // Title
                  if (meta.title != null && meta.title!.isNotEmpty)
                    Text(
                      meta.title!,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                        height: 1.25,
                        fontFamily: 'Gontserrat',
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                  // Description
                  if (meta.description != null && meta.description!.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      meta.description!,
                      style: TextStyle(
                        fontSize: 11,
                        color: textSecondary,
                        height: 1.3,
                        fontFamily: 'Gontserrat',
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
