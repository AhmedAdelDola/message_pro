import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../../data/models/message.dart';
import '../../../../widgets/media_viewers/audio_player_bubble.dart';
import '../../../../widgets/media_viewers/document_attachment_tile.dart';
import '../../../../widgets/media_viewers/image_viewer_screen.dart';

class BubbleAttachmentsView extends StatelessWidget {
  final Message message;
  final bool isOutgoing;

  const BubbleAttachmentsView({
    super.key,
    required this.message,
    required this.isOutgoing,
  });

  static bool isImageAttachment(MessageAttachment att) {
    final lowerType = att.fileType.toLowerCase();
    final urlLower = att.dataUrl.toLowerCase();
    return lowerType == 'image' ||
        urlLower.endsWith('.png') ||
        urlLower.endsWith('.jpg') ||
        urlLower.endsWith('.jpeg') ||
        urlLower.endsWith('.gif') ||
        urlLower.endsWith('.webp');
  }

  static bool isVideoAttachment(MessageAttachment att) {
    final lowerType = att.fileType.toLowerCase();
    final urlLower = att.dataUrl.toLowerCase();
    return lowerType == 'video' ||
        urlLower.endsWith('.mp4') ||
        urlLower.endsWith('.mov') ||
        urlLower.endsWith('.avi') ||
        urlLower.endsWith('.mkv') ||
        urlLower.endsWith('.webm') ||
        urlLower.endsWith('.3gp');
  }

  static bool isAudioAttachment(MessageAttachment att) {
    final lowerType = att.fileType.toLowerCase();
    final urlLower = att.dataUrl.toLowerCase();
    return lowerType == 'audio' ||
        urlLower.endsWith('.mp3') ||
        urlLower.endsWith('.ogg') ||
        urlLower.endsWith('.wav') ||
        urlLower.endsWith('.m4a') ||
        urlLower.endsWith('.aac') ||
        urlLower.endsWith('.opus');
  }

  @override
  Widget build(BuildContext context) {
    final images = message.attachments.where(isImageAttachment).toList();
    final others = message.attachments.where((a) => !isImageAttachment(a)).toList();

    return Column(
      crossAxisAlignment: isOutgoing ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (images.length == 1)
          _buildSingleImage(context, images.first, [images.first.dataUrl], 0)
        else if (images.length > 1)
          _buildImageGrid(context, images),
        if (images.isNotEmpty && others.isNotEmpty)
          const SizedBox(height: 6),
        ...others.map((att) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: _buildAttachment(context, att, isOutgoing: isOutgoing),
            )),
      ],
    );
  }

  Widget _buildSingleImage(BuildContext context, MessageAttachment att, List<String> allUrls, int index) {
    return InkWell(
      onTap: () => ImageViewerScreen.openGallery(
        context,
        imageUrls: allUrls,
        initialIndex: index,
        title: att.fileName,
      ),
      borderRadius: BorderRadius.circular(8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          children: [
            CachedNetworkImage(
              imageUrl: att.dataUrl,
              fit: BoxFit.cover,
              placeholder: (ctx, url) => Container(
                height: 140,
                color: Colors.black12,
                child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),
              errorWidget: (ctx, url, error) => const Icon(Icons.broken_image_rounded, size: 36),
            ),
            Positioned(
              right: 6,
              bottom: 6,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(Icons.fullscreen_rounded, color: Colors.white, size: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageGrid(BuildContext context, List<MessageAttachment> images) {
    final urls = images.map((a) => a.dataUrl).toList();
    final count = images.length;

    Widget buildTile(int idx, {required double height}) {
      return _buildGridImageTile(context, images[idx], urls, idx, height: height);
    }

    if (count == 2) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Row(
          children: [
            Expanded(child: buildTile(0, height: 130)),
            const SizedBox(width: 4),
            Expanded(child: buildTile(1, height: 130)),
          ],
        ),
      );
    }

    if (count == 3) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            buildTile(0, height: 120),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(child: buildTile(1, height: 85)),
                const SizedBox(width: 4),
                Expanded(child: buildTile(2, height: 85)),
              ],
            ),
          ],
        ),
      );
    }

    if (count == 4) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(child: buildTile(0, height: 100)),
                const SizedBox(width: 4),
                Expanded(child: buildTile(1, height: 100)),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(child: buildTile(2, height: 100)),
                const SizedBox(width: 4),
                Expanded(child: buildTile(3, height: 100)),
              ],
            ),
          ],
        ),
      );
    }

    // 5 images (or more)
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(child: buildTile(0, height: 105)),
              const SizedBox(width: 4),
              Expanded(child: buildTile(1, height: 105)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(child: buildTile(2, height: 80)),
              const SizedBox(width: 4),
              Expanded(child: buildTile(3, height: 80)),
              const SizedBox(width: 4),
              Expanded(child: buildTile(4, height: 80)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGridImageTile(
    BuildContext context,
    MessageAttachment att,
    List<String> allUrls,
    int index, {
    required double height,
  }) {
    return InkWell(
      onTap: () => ImageViewerScreen.openGallery(
        context,
        imageUrls: allUrls,
        initialIndex: index,
        title: att.fileName,
      ),
      child: SizedBox(
        height: height,
        child: CachedNetworkImage(
          imageUrl: att.dataUrl,
          fit: BoxFit.cover,
          width: double.infinity,
          placeholder: (ctx, url) => Container(
            color: Colors.black12,
            child: const Center(child: CircularProgressIndicator(strokeWidth: 1.5)),
          ),
          errorWidget: (ctx, url, error) => Container(
            color: Colors.black12,
            child: const Icon(Icons.broken_image_rounded, size: 24),
          ),
        ),
      ),
    );
  }

  Widget _buildVideoAttachment(BuildContext context, MessageAttachment att, {required bool isOutgoing}) {
    String formatDuration(double? seconds) {
      if (seconds == null || seconds <= 0) return '';
      final d = Duration(seconds: seconds.toInt());
      final min = d.inMinutes;
      final sec = d.inSeconds % 60;
      return '$min:${sec.toString().padLeft(2, '0')}';
    }

    return InkWell(
      onTap: () async {
        final uri = Uri.tryParse(att.dataUrl);
        if (uri != null && await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        constraints: const BoxConstraints(minWidth: 200, maxWidth: 280),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(10),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (att.thumbUrl != null && att.thumbUrl!.isNotEmpty)
              CachedNetworkImage(
                imageUrl: att.thumbUrl!,
                height: 140,
                width: double.infinity,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => Container(height: 120, color: const Color(0xFF1E293B)),
              )
            else
              Container(height: 120, width: double.infinity, color: const Color(0xFF1E293B)),
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 28),
            ),
            Positioned(
              left: 8,
              bottom: 8,
              right: 8,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      att.fileName ?? 'Video',
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (att.duration != null && att.duration! > 0)
                    Text(
                      formatDuration(att.duration),
                      style: const TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachment(BuildContext context, MessageAttachment att, {required bool isOutgoing}) {
    if (isImageAttachment(att)) {
      return _buildSingleImage(context, att, [att.dataUrl], 0);
    }

    if (isVideoAttachment(att)) {
      return _buildVideoAttachment(context, att, isOutgoing: isOutgoing);
    }

    if (isAudioAttachment(att)) {
      return AudioPlayerBubble(
        audioUrl: att.dataUrl,
        isOutgoing: isOutgoing,
        fileName: att.fileName,
        initialDurationSeconds: att.duration,
        transcribedText: att.transcribedText,
      );
    }

    return DocumentAttachmentTile(
      fileUrl: att.dataUrl,
      fileName: att.fileName,
      fileSize: att.fileSize,
      fileType: att.fileType,
      isOutgoing: isOutgoing,
    );
  }
}
