import 'package:flutter/material.dart';

import '../../config/app_colors.dart';

/// Markdown editor controller that renders `![image](url)` markdown as an
/// inline image thumbnail while keeping the underlying markdown intact for
/// save/load.
///
/// The trick: in the live [text] we store a single OBJECT REPLACEMENT
/// CHARACTER (`￼`) per image and keep the full markdown for each one
/// in a sidecar list. `￼` is exactly what Flutter inserts for a
/// [WidgetSpan] in the plain-text representation of a paragraph, so the
/// cursor / selection model stays in lock-step with the rendered layout
/// — caret moves treat each image as exactly one character, which is
/// what users expect.
///
/// Use [setMarkdown] to load existing content (parses `![image](url)`
/// patterns into placeholders + sidecar entries), [getMarkdown] to read
/// the assembled markdown back, and [insertImage] to drop a new image at
/// the caret without disturbing the user's selection.
class InlineImageTextController extends TextEditingController {
  InlineImageTextController({String initialMarkdown = ''}) {
    setMarkdown(initialMarkdown);
    addListener(_reconcileOnEdit);
  }

  /// Markdown of each inline image, in the same order as the `￼`
  /// characters appear in [text].
  final List<String> _images = [];

  /// Snapshot of [text] from the previous notification — used to detect
  /// which `￼` characters the user deleted so we can drop the matching
  /// sidecar entries.
  String _lastSeenText = '';

  /// Guards [_reconcileOnEdit] from running while we mutate [text]
  /// ourselves (otherwise we'd remove the entries we just added).
  bool _suppressReconcile = false;

  /// `￼` — same code point Flutter substitutes for a [WidgetSpan]
  /// in the plain-text representation of a paragraph.
  static const String placeholderChar = '￼';

  /// Matches a markdown inline image. Captures the URL in group 1.
  static final RegExp _imageRegex = RegExp(r'!\[[^\]]*\]\(([^)]+)\)');

  /// Replace the editor content with [markdown]. Inline images are
  /// stripped to `￼` placeholders and stored in the sidecar list.
  void setMarkdown(String markdown) {
    _suppressReconcile = true;
    _images.clear();
    final buffer = StringBuffer();
    int lastEnd = 0;
    for (final m in _imageRegex.allMatches(markdown)) {
      buffer.write(markdown.substring(lastEnd, m.start));
      buffer.write(placeholderChar);
      _images.add(m.group(0)!);
      lastEnd = m.end;
    }
    buffer.write(markdown.substring(lastEnd));
    text = buffer.toString();
    _lastSeenText = text;
    _suppressReconcile = false;
  }

  /// Assemble the markdown by splicing each `￼` back into its full
  /// `![image](url)` form.
  String getMarkdown() {
    if (_images.isEmpty) return text;
    final buffer = StringBuffer();
    int imgIndex = 0;
    for (int i = 0; i < text.length; i++) {
      final ch = text[i];
      if (ch == placeholderChar && imgIndex < _images.length) {
        buffer.write(_images[imgIndex]);
        imgIndex++;
      } else {
        buffer.write(ch);
      }
    }
    return buffer.toString();
  }

  /// Insert a new image at the current caret. [imageMarkdown] is the
  /// full `![image](url)` form so we can persist alt text verbatim.
  void insertImage(String imageMarkdown) {
    final selection = this.selection;
    final caret = selection.isValid && selection.baseOffset >= 0
        ? selection.baseOffset
        : text.length;

    // Index in [_images] = number of placeholders sitting BEFORE the caret.
    int imgIndex = 0;
    for (int i = 0; i < caret && i < text.length; i++) {
      if (text[i] == placeholderChar) imgIndex++;
    }

    _suppressReconcile = true;
    _images.insert(imgIndex, imageMarkdown);
    final newText =
        text.substring(0, caret) + placeholderChar + text.substring(caret);
    value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: caret + 1),
    );
    _lastSeenText = newText;
    _suppressReconcile = false;
  }

  /// When the user backspaces over a `￼`, drop the matching sidecar
  /// entry so [getMarkdown] doesn't emit a phantom image. We work it out
  /// by walking the old and new text in parallel — anything in the old
  /// text not represented at the same relative position in the new text
  /// was deleted.
  void _reconcileOnEdit() {
    if (_suppressReconcile) return;
    final currentText = text;
    if (currentText == _lastSeenText) return;

    final oldCount = placeholderChar.allMatches(_lastSeenText).length;
    final newCount = placeholderChar.allMatches(currentText).length;

    if (newCount < oldCount) {
      // Walk both texts and find which placeholders survived.
      final survivors = <int>[]; // sidecar indices that are still present
      int oldImgIdx = 0;
      int oldPos = 0;
      int newPos = 0;
      while (oldPos < _lastSeenText.length && newPos < currentText.length) {
        if (_lastSeenText[oldPos] == placeholderChar &&
            currentText[newPos] == placeholderChar) {
          survivors.add(oldImgIdx);
          oldImgIdx++;
          oldPos++;
          newPos++;
        } else if (_lastSeenText[oldPos] == placeholderChar) {
          // The old placeholder was deleted.
          oldImgIdx++;
          oldPos++;
        } else if (currentText[newPos] == placeholderChar) {
          // A new placeholder appeared without going through insertImage —
          // probably a paste of an existing `￼` character. Drop it on
          // the floor (it'd render as an empty placeholder anyway).
          newPos++;
        } else {
          oldPos++;
          newPos++;
        }
      }
      // Anything past the loop in the old text is also gone.
      while (oldPos < _lastSeenText.length) {
        if (_lastSeenText[oldPos] == placeholderChar) {
          oldImgIdx++;
        }
        oldPos++;
      }
      final kept = [
        for (final idx in survivors)
          if (idx < _images.length) _images[idx],
      ];
      _images
        ..clear()
        ..addAll(kept);
    } else if (newCount > oldCount) {
      // User pasted a `￼` character we didn't issue. Pad the sidecar
      // with empty entries so indices stay aligned; renderer treats those
      // as broken placeholders.
      while (_images.length < newCount) {
        _images.add('');
      }
    }

    _lastSeenText = currentText;
  }

  /// Extract the URL out of a stored `![alt](url)` markdown entry.
  /// Returns an empty string when the entry is malformed or absent.
  String _extractUrl(String entry) {
    final m = _imageRegex.firstMatch(entry);
    return m?.group(1) ?? '';
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final src = text;
    if (!src.contains(placeholderChar)) {
      return super.buildTextSpan(
        context: context,
        style: style,
        withComposing: withComposing,
      );
    }

    final children = <InlineSpan>[];
    int lastEnd = 0;
    int imgIndex = 0;
    for (int i = 0; i < src.length; i++) {
      if (src[i] != placeholderChar) continue;
      if (i > lastEnd) {
        children.add(TextSpan(text: src.substring(lastEnd, i), style: style));
      }
      final url = imgIndex < _images.length ? _extractUrl(_images[imgIndex]) : '';
      children.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: _InlineImageCard(url: url),
        ),
      );
      imgIndex++;
      lastEnd = i + 1;
    }
    if (lastEnd < src.length) {
      children.add(TextSpan(text: src.substring(lastEnd), style: style));
    }
    return TextSpan(style: style, children: children);
  }

  @override
  void dispose() {
    removeListener(_reconcileOnEdit);
    super.dispose();
  }
}

/// Compact thumbnail rendered in place of `![image](url)` markdown.
/// Sized so it sits inline with surrounding text — falls back to a
/// "broken image" tile if the URL is empty or the network fails.
class _InlineImageCard extends StatelessWidget {
  const _InlineImageCard({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    const double height = 64;
    const double width = 96;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.inputBorder),
            borderRadius: BorderRadius.circular(4),
            color: Colors.grey.shade100,
          ),
          child: url.isEmpty
              ? _brokenPlaceholder()
              : Image.network(
                  url,
                  fit: BoxFit.cover,
                  width: width,
                  height: height,
                  loadingBuilder: (ctx, child, progress) {
                    if (progress == null) return child;
                    return const Center(
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  },
                  errorBuilder: (_, _, _) => _brokenPlaceholder(),
                ),
        ),
      ),
    );
  }

  Widget _brokenPlaceholder() => Center(
        child: Icon(
          Icons.broken_image_outlined,
          size: 24,
          color: AppColors.textSecondary,
        ),
      );
}
