import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/services/link_preview_service.dart';

class ClickableTextWithLinks extends StatefulWidget {
  final String text;
  final TextStyle textStyle;
  final TextStyle? linkStyle;
  final TextAlign? textAlign;
  final TextDirection? textDirection;

  const ClickableTextWithLinks({
    super.key,
    required this.text,
    required this.textStyle,
    this.linkStyle,
    this.textAlign,
    this.textDirection,
  });

  @override
  State<ClickableTextWithLinks> createState() => _ClickableTextWithLinksState();
}

class _ClickableTextWithLinksState extends State<ClickableTextWithLinks> {
  final List<TapGestureRecognizer> _recognizers = [];

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  void _disposeRecognizers() {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();
  }

  Future<void> _launch(String rawUrl) async {
    var u = rawUrl.trim();
    if (u.toLowerCase().startsWith('www.')) {
      u = 'https://$u';
    }
    final uri = Uri.tryParse(u);
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  List<TextSpan> _parseBoldSpans(String text, TextStyle baseStyle) {
    final spans = <TextSpan>[];
    final boldRegex = RegExp(r'\*([^*]+)\*');
    int last = 0;

    for (final m in boldRegex.allMatches(text)) {
      if (m.start > last) {
        spans.add(TextSpan(
          text: text.substring(last, m.start),
          style: baseStyle,
        ));
      }
      spans.add(TextSpan(
        text: m.group(1),
        style: baseStyle.copyWith(fontWeight: FontWeight.bold),
      ));
      last = m.end;
    }

    if (last < text.length) {
      spans.add(TextSpan(
        text: text.substring(last),
        style: baseStyle,
      ));
    }

    return spans;
  }

  @override
  Widget build(BuildContext context) {
    _disposeRecognizers();

    final text = widget.text;
    final defaultLinkStyle = widget.linkStyle ??
        widget.textStyle.copyWith(
          color: const Color(0xFF38BDF8),
          decoration: TextDecoration.underline,
          decorationColor: const Color(0xFF38BDF8).withValues(alpha: 0.6),
          fontWeight: FontWeight.w600,
        );

    final spans = <InlineSpan>[];
    final matches = LinkPreviewService.urlRegExp.allMatches(text);

    if (matches.isEmpty) {
      final boldSpans = _parseBoldSpans(text, widget.textStyle);
      return Text.rich(
        TextSpan(children: boldSpans),
        style: widget.textStyle,
        textAlign: widget.textAlign,
        textDirection: widget.textDirection,
      );
    }

    int currentIndex = 0;
    for (final match in matches) {
      if (match.start > currentIndex) {
        final nonLinkText = text.substring(currentIndex, match.start);
        spans.addAll(_parseBoldSpans(nonLinkText, widget.textStyle));
      }

      final fullMatch = match.group(0)!;
      final trailingPunctMatch = RegExp(r'[\.,\?!:;\)\]]+$').firstMatch(fullMatch);
      String cleanUrl = fullMatch;
      String trailingPunct = '';

      if (trailingPunctMatch != null) {
        cleanUrl = fullMatch.substring(0, trailingPunctMatch.start);
        trailingPunct = trailingPunctMatch.group(0)!;
      }

      if (cleanUrl.isNotEmpty) {
        final recognizer = TapGestureRecognizer()..onTap = () => _launch(cleanUrl);
        _recognizers.add(recognizer);

        spans.add(TextSpan(
          text: cleanUrl,
          style: defaultLinkStyle,
          recognizer: recognizer,
        ));
      }

      if (trailingPunct.isNotEmpty) {
        spans.add(TextSpan(
          text: trailingPunct,
          style: widget.textStyle,
        ));
      }

      currentIndex = match.end;
    }

    if (currentIndex < text.length) {
      final nonLinkText = text.substring(currentIndex);
      spans.addAll(_parseBoldSpans(nonLinkText, widget.textStyle));
    }

    return Text.rich(
      TextSpan(children: spans),
      style: widget.textStyle,
      textAlign: widget.textAlign,
      textDirection: widget.textDirection,
    );
  }
}
