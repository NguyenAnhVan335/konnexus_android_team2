import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Đoạn text tự nhận diện URL và cho phép chạm để mở bằng ứng dụng hệ thống.
///
/// Dùng `TextSpan` + `TapGestureRecognizer`; các recognizer được quản lý theo
/// vòng đời widget để tránh rò rỉ bộ nhớ (dispose khi rebuild/unmount).
class LinkifiedText extends StatefulWidget {
  const LinkifiedText(
    this.text, {
    super.key,
    this.style,
    this.linkStyle,
    this.maxLines,
    this.overflow,
    this.textAlign,
  });

  final String text;
  final TextStyle? style;
  final TextStyle? linkStyle;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextAlign? textAlign;

  @override
  State<LinkifiedText> createState() => _LinkifiedTextState();
}

class _LinkifiedTextState extends State<LinkifiedText> {
  static final RegExp _urlPattern =
      RegExp(r'(https?://[^\s]+|www\.[^\s]+)', caseSensitive: false);

  final List<TapGestureRecognizer> _recognizers = <TapGestureRecognizer>[];
  List<InlineSpan> _spans = const <InlineSpan>[];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _rebuildSpans();
  }

  @override
  void didUpdateWidget(covariant LinkifiedText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text ||
        oldWidget.style != widget.style ||
        oldWidget.linkStyle != widget.linkStyle) {
      _rebuildSpans();
    }
  }

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  void _rebuildSpans() {
    _disposeRecognizers();
    _spans = _buildSpans(Theme.of(context).colorScheme.primary);
  }

  List<InlineSpan> _buildSpans(Color primary) {
    final List<InlineSpan> spans = <InlineSpan>[];
    final String text = widget.text;
    final TextStyle linkStyle = widget.linkStyle ??
        TextStyle(
          color: primary,
          decoration: TextDecoration.underline,
          decorationColor: primary,
        );
    int start = 0;
    for (final RegExpMatch match in _urlPattern.allMatches(text)) {
      if (match.start > start) {
        spans.add(TextSpan(text: text.substring(start, match.start)));
      }
      final String raw = match.group(0) ?? '';
      // Bỏ dấu câu thường dính ở cuối URL (ví dụ "xem tại https://a.com.").
      final String trimmed = _trimTrailingPunctuation(raw);
      final String suffix = raw.substring(trimmed.length);
      final String url = trimmed.toLowerCase().startsWith('www.')
          ? 'https://$trimmed'
          : trimmed;
      final TapGestureRecognizer recognizer = TapGestureRecognizer()
        ..onTap = () => _openLink(url);
      _recognizers.add(recognizer);
      spans.add(TextSpan(
        text: trimmed,
        style: linkStyle,
        recognizer: recognizer,
      ));
      if (suffix.isNotEmpty) {
        spans.add(TextSpan(text: suffix));
      }
      start = match.end;
    }
    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start)));
    }
    return spans;
  }

  String _trimTrailingPunctuation(String value) {
    const String punctuation = '.,;:!?)]}\'"';
    int end = value.length;
    while (end > 0 && punctuation.contains(value[end - 1])) {
      end--;
    }
    return value.substring(0, end);
  }

  Future<void> _openLink(String url) async {
    final Uri? uri = Uri.tryParse(url);
    if (uri == null) {
      return;
    }
    try {
      final bool opened =
          await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened) {
        _showOpenError();
      }
    } catch (_) {
      _showOpenError();
    }
  }

  void _showOpenError() {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      const SnackBar(content: Text('Không mở được liên kết.')),
    );
  }

  void _disposeRecognizers() {
    for (final TapGestureRecognizer recognizer in _recognizers) {
      recognizer.dispose();
    }
    _recognizers.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(style: widget.style, children: _spans),
      maxLines: widget.maxLines,
      overflow: widget.overflow,
      textAlign: widget.textAlign,
    );
  }
}
