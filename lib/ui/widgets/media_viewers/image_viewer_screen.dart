import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';

class ImageViewerScreen extends StatefulWidget {
  final String imageUrl;
  final String? title;

  const ImageViewerScreen({
    super.key,
    required this.imageUrl,
    this.title,
  });

  static void open(BuildContext context, {required String imageUrl, String? title}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ImageViewerScreen(imageUrl: imageUrl, title: title),
        fullscreenDialog: true,
      ),
    );
  }

  @override
  State<ImageViewerScreen> createState() => _ImageViewerScreenState();
}

class _ImageViewerScreenState extends State<ImageViewerScreen> {
  final TransformationController _transformController = TransformationController();
  TapDownDetails? _doubleTapDetails;

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  void _handleDoubleTap() {
    if (_transformController.value != Matrix4.identity()) {
      _transformController.value = Matrix4.identity();
    } else {
      final position = _doubleTapDetails?.localPosition ?? Offset.zero;
      // ignore: deprecated_member_use
      final zoomed = Matrix4.identity()
        // ignore: deprecated_member_use
        ..translate(-position.dx, -position.dy)
        // ignore: deprecated_member_use
        ..scale(2.5);
      _transformController.value = zoomed;
    }
  }

  Future<void> _openExternal() async {
    final uri = Uri.tryParse(widget.imageUrl);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fileName = widget.title ?? widget.imageUrl.split('/').last.split('?').first;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black.withValues(alpha: 0.8),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          fileName.isNotEmpty ? fileName : 'Image',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white),
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_browser_rounded),
            tooltip: 'فتح في المتصفح',
            onPressed: _openExternal,
          ),
        ],
      ),
      body: Center(
        child: GestureDetector(
          onDoubleTapDown: (d) => _doubleTapDetails = d,
          onDoubleTap: _handleDoubleTap,
          child: InteractiveViewer(
            transformationController: _transformController,
            minScale: 0.8,
            maxScale: 4.0,
            child: CachedNetworkImage(
              imageUrl: widget.imageUrl,
              fit: BoxFit.contain,
              placeholder: (context, url) => const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
              errorWidget: (context, url, error) => Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.broken_image_rounded, size: 64, color: Colors.white54),
                  SizedBox(height: 12),
                  Text(
                    'تعذر تحميل الصورة',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
