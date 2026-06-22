import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../../config/app_colors.dart';
import 'app_markdown_view.dart';
import 'inline_image_text_controller.dart';

/// Multi-line markdown editor with a styled toolbar.
///
/// Toolbar buttons mutate the underlying [TextEditingController] so that what
/// the user sees in the editor is real Markdown. The detail screen renders the
/// same string via [AppMarkdownView], keeping the typography in sync.
class AppRichTextField extends StatefulWidget {
  const AppRichTextField({
    super.key,
    required this.controller,
    this.label = 'Instructions',
    this.hintText,
    this.minLines = 5,
    this.onPickImage,
  });

  final TextEditingController controller;
  final String label;
  final String? hintText;
  final int minLines;

  /// Optional async callback invoked when the user taps the image toolbar
  /// button. Should drive the picker + upload flow and return the public
  /// URL of the uploaded image (or null if the user cancelled). When this
  /// is null, the image button is hidden — the editor never asks the user
  /// to type a URL.
  final Future<String?> Function()? onPickImage;

  @override
  State<AppRichTextField> createState() => _AppRichTextFieldState();
}

class _AppRichTextFieldState extends State<AppRichTextField> {
  final FocusNode _focusNode = FocusNode();
  bool _previewMode = false;
  bool _splitMode = false;
  bool _pickingImage = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleTextChanged);
    _focusNode.dispose();
    super.dispose();
  }

  void _handleTextChanged() {
    // Refresh preview/split renderings so they stay in sync as the user types.
    if (_previewMode || _splitMode) setState(() {});
  }

  // ── Editor mutations ──

  /// Wrap the current selection with [marker] on both sides.
  ///
  /// Selection rules, in order:
  /// 1. If the user has a non-empty selection, wrap it.
  /// 2. Otherwise, find the word at (or directly adjacent to) the caret and
  ///    wrap that — matches Google Docs / Word / Notion UX where tapping
  ///    Bold after typing a word bolds the whole word without forcing the
  ///    user to select it first.
  /// 3. If there's no adjacent word (caret on whitespace, at a line edge,
  ///    or in an empty buffer), drop the markers at the caret and place
  ///    the caret between them so the user can keep typing.
  ///
  /// After the mutation, the wrapped text is re-selected so the user can
  /// immediately apply another format (e.g. bold then italic).
  void _wrap(String marker) {
    final controller = widget.controller;
    final selection = controller.selection;
    final text = controller.text;
    final position =
        selection.isValid ? selection.baseOffset : text.length;
    final hasRange = selection.isValid && !selection.isCollapsed;

    int wrapStart;
    int wrapEnd;
    if (hasRange) {
      wrapStart = selection.start;
      wrapEnd = selection.end;
    } else {
      final word = _wordRangeAt(text, position);
      wrapStart = word.start;
      wrapEnd = word.end;
    }

    final selected = text.substring(wrapStart, wrapEnd);
    final replacement = '$marker$selected$marker';
    final newText = text.replaceRange(wrapStart, wrapEnd, replacement);

    controller.text = newText;
    if (selected.isEmpty) {
      // Empty wrap — caret goes between the markers.
      controller.selection = TextSelection.collapsed(
        offset: wrapStart + marker.length,
      );
    } else {
      // Re-select the wrapped text so the user can chain formatting.
      controller.selection = TextSelection(
        baseOffset: wrapStart + marker.length,
        extentOffset: wrapStart + marker.length + selected.length,
      );
    }
    _focusNode.requestFocus();
  }

  /// Range of the word that contains or is directly adjacent to [position].
  /// Returns a zero-length range at [position] when the caret is not next
  /// to a word (whitespace, line edge, or empty buffer). "Word boundary"
  /// treats whitespace and markdown emphasis markers (`*`, `_`) as breaks
  /// so we don't try to wrap inside an existing `**bold**` span.
  ({int start, int end}) _wordRangeAt(String text, int position) {
    if (text.isEmpty) return (start: 0, end: 0);
    final clamped = position.clamp(0, text.length);
    int start = clamped;
    while (start > 0 && !_isBoundary(text[start - 1])) {
      start--;
    }
    int end = clamped;
    while (end < text.length && !_isBoundary(text[end])) {
      end++;
    }
    return (start: start, end: end);
  }

  bool _isBoundary(String char) {
    if (char.isEmpty) return true;
    final code = char.codeUnitAt(0);
    // Whitespace family (space, tab, newline, etc.)
    if (char.trim().isEmpty) return true;
    // Markdown emphasis markers — don't wrap inside an existing emphasis span.
    if (code == 0x2A /* * */ || code == 0x5F /* _ */) return true;
    return false;
  }

  /// Apply a per-line prefix to every line intersecting the current selection
  /// (or just the caret's line when nothing is selected).
  ///
  /// [prefixFor] receives the zero-based line index inside the block being
  /// modified so callers can return either a static prefix (bullets, quotes,
  /// headings) or an incrementing one (numbered lists).
  void _prefixLines(String Function(int lineIndex) prefixFor) {
    final controller = widget.controller;
    final text = controller.text;
    final selection = controller.selection;
    final caretValid = selection.isValid && selection.baseOffset >= 0;
    final start = caretValid ? selection.start : text.length;
    final end = caretValid ? selection.end : text.length;

    int lineStart = start;
    while (lineStart > 0 && text[lineStart - 1] != '\n') {
      lineStart--;
    }
    int lineEnd = end;
    while (lineEnd < text.length && text[lineEnd] != '\n') {
      lineEnd++;
    }

    final block = text.substring(lineStart, lineEnd);
    final lines = block.split('\n');
    final modified = [
      for (int i = 0; i < lines.length; i++) '${prefixFor(i)}${lines[i]}',
    ].join('\n');
    final newText = text.replaceRange(lineStart, lineEnd, modified);

    controller.text = newText;
    controller.selection = TextSelection.collapsed(
      offset: lineStart + modified.length,
    );
    _focusNode.requestFocus();
  }

  /// Insert a markdown link. The selection (if any) becomes the link label;
  /// otherwise a `text` placeholder is used. The URL placeholder is
  /// pre-selected so the user can paste straight over it.
  void _insertLink() {
    final controller = widget.controller;
    final selection = controller.selection;
    final text = controller.text;
    final position =
        selection.isValid ? selection.baseOffset : text.length;
    final hasRange = selection.isValid && !selection.isCollapsed;
    final label = hasRange ? selection.textInside(text) : 'text';

    final replacement = '[$label](https://)';
    final newStart = hasRange ? selection.start : position;
    final newEnd = hasRange ? selection.end : position;
    final newText = text.replaceRange(newStart, newEnd, replacement);

    controller.text = newText;
    final urlStart = newStart + label.length + 3; // `[label](`
    final urlEnd = newStart + replacement.length - 1; // before final `)`
    controller.selection = TextSelection(
      baseOffset: urlStart,
      extentOffset: urlEnd,
    );
    _focusNode.requestFocus();
  }

  /// Drive the parent's image-pick callback and, on success, insert
  /// `![image](url)` at the caret. No-op when no callback is wired or the
  /// user cancelled the picker. We capture the caret position before the
  /// async gap so the insertion lands where the user originally tapped,
  /// even if they moved the caret mid-upload.
  Future<void> _insertImage() async {
    final picker = widget.onPickImage;
    if (picker == null || _pickingImage) return;

    final controller = widget.controller;
    final selectionAtStart = controller.selection;
    final textAtStart = controller.text;
    final insertAt = selectionAtStart.isValid
        ? selectionAtStart.baseOffset
        : textAtStart.length;

    setState(() => _pickingImage = true);
    String? url;
    try {
      url = await picker();
    } finally {
      if (mounted) setState(() => _pickingImage = false);
    }

    if (!mounted || url == null || url.isEmpty) return;

    final replacement = '![image]($url)';

    if (controller is InlineImageTextController) {
      // Inline controller renders the image as a thumbnail card in place
      // of the markdown — delegate so the sidecar URL list stays in sync.
      // Re-anchor the caret against the LATEST text first so the image
      // lands where the user originally tapped.
      final anchor = insertAt.clamp(0, controller.text.length);
      controller.selection = TextSelection.collapsed(offset: anchor);
      controller.insertImage(replacement);
    } else {
      // Plain controller: splice the markdown into the raw text.
      final currentText = controller.text;
      final anchor = insertAt.clamp(0, currentText.length);
      controller.text = currentText.replaceRange(anchor, anchor, replacement);
      controller.selection = TextSelection.collapsed(
        offset: anchor + replacement.length,
      );
    }
    _focusNode.requestFocus();
  }

  void _togglePreview() {
    setState(() {
      _previewMode = !_previewMode;
      if (_previewMode) {
        _splitMode = false; // mutually exclusive — preview replaces the editor
      } else {
        _focusNode.requestFocus();
      }
    });
  }

  void _toggleSplit() {
    setState(() {
      _splitMode = !_splitMode;
      if (_splitMode) _previewMode = false;
    });
  }

  Future<void> _openFullscreen() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => _FullscreenEditor(
          controller: widget.controller,
          label: widget.label,
          hintText: widget.hintText,
          onPickImage: widget.onPickImage,
        ),
      ),
    );
    // After returning from fullscreen, the parent controller already has the
    // updated text — rebuild so any preview state reflects the latest content.
    if (mounted) setState(() {});
  }

  // ── Render ──

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.inputBorder),
            borderRadius: BorderRadius.circular(4),
            color: Colors.white,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ExcludeFocus prevents toolbar buttons from claiming the
              // Flutter focus from the editor. Without this, on iOS the
              // soft keyboard dismisses between the tap and the explicit
              // _focusNode.requestFocus() and the user's next keystroke
              // can land in a different field or be lost.
              ExcludeFocus(
                child: _Toolbar(
                  onBold: () => _wrap('**'),
                  onItalic: () => _wrap('*'),
                  onHeading: () => _prefixLines((_) => '# '),
                  onQuote: () => _prefixLines((_) => '> '),
                  onBulletList: () => _prefixLines((_) => '- '),
                  onNumberedList: () =>
                      _prefixLines((i) => '${i + 1}. '),
                  onLink: _insertLink,
                  onImage: widget.onPickImage == null
                      ? null
                      : () {
                          _insertImage();
                        },
                  imageBusy: _pickingImage,
                  onTogglePreview: _togglePreview,
                  onToggleSplit: _toggleSplit,
                  onFullscreen: _openFullscreen,
                  previewActive: _previewMode,
                  splitActive: _splitMode,
                ),
              ),
              _buildBody(context),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context) {
    // Preview must see fully-assembled markdown so `![image](url)` regions
    // render as images. Inline-image controllers store `￼` placeholders
    // in `.text` — calling `getMarkdown()` splices them back into real
    // markdown.
    final controller = widget.controller;
    final previewSource = controller is InlineImageTextController
        ? controller.getMarkdown()
        : controller.text;

    if (_previewMode) {
      return _Preview(
        text: previewSource,
        minHeight: widget.minLines * 24.0,
      );
    }
    final editor = _Editor(
      controller: widget.controller,
      focusNode: _focusNode,
      minLines: widget.minLines,
      hintText: widget.hintText,
    );
    if (_splitMode) {
      return Column(
        children: [
          editor,
          Container(height: 1, color: AppColors.inputBorder),
          _Preview(
            text: previewSource,
            minHeight: widget.minLines * 12.0,
            background: Colors.grey.shade50,
          ),
        ],
      );
    }
    return editor;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Toolbar
// ─────────────────────────────────────────────────────────────────────────────

class _Toolbar extends StatelessWidget {
  const _Toolbar({
    required this.onBold,
    required this.onItalic,
    required this.onHeading,
    required this.onQuote,
    required this.onBulletList,
    required this.onNumberedList,
    required this.onLink,
    required this.onImage,
    required this.imageBusy,
    required this.onTogglePreview,
    required this.onToggleSplit,
    required this.onFullscreen,
    required this.previewActive,
    required this.splitActive,
  });

  final VoidCallback onBold;
  final VoidCallback onItalic;
  final VoidCallback onHeading;
  final VoidCallback onQuote;
  final VoidCallback onBulletList;
  final VoidCallback onNumberedList;
  final VoidCallback onLink;
  /// When null, the image button is hidden — the parent didn't wire a
  /// picker, so there's no useful action to expose.
  final VoidCallback? onImage;
  /// True while the parent's pick-and-upload future is in flight. The
  /// button renders a spinner and rejects re-taps.
  final bool imageBusy;
  final VoidCallback onTogglePreview;
  final VoidCallback onToggleSplit;
  final VoidCallback onFullscreen;
  final bool previewActive;
  final bool splitActive;

  @override
  Widget build(BuildContext context) {
    // While preview is on, formatting buttons have nothing to act on — disable
    // them so users get a clear signal to switch back to edit mode.
    final formattingDisabled = previewActive;
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(
          bottom: BorderSide(color: AppColors.inputBorder),
        ),
      ),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          _ToolbarButton.text(
            label: 'B',
            tooltip: 'Bold',
            style: const TextStyle(
              fontFamily: 'Times New Roman',
              fontFamilyFallback: ['serif'],
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
            onPressed: formattingDisabled ? null : onBold,
          ),
          _ToolbarButton.text(
            label: 'I',
            tooltip: 'Italic',
            style: const TextStyle(
              fontFamily: 'Times New Roman',
              fontFamilyFallback: ['serif'],
              fontWeight: FontWeight.w700,
              fontStyle: FontStyle.italic,
              fontSize: 18,
            ),
            onPressed: formattingDisabled ? null : onItalic,
          ),
          _ToolbarButton.text(
            label: 'H',
            tooltip: 'Heading',
            style: const TextStyle(
              fontFamily: 'Times New Roman',
              fontFamilyFallback: ['serif'],
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
            onPressed: formattingDisabled ? null : onHeading,
          ),
          _ToolbarButton.icon(
            icon: Icons.format_quote,
            tooltip: 'Quote',
            onPressed: formattingDisabled ? null : onQuote,
          ),
          _ToolbarButton.icon(
            icon: Icons.format_list_bulleted,
            tooltip: 'Bulleted list',
            onPressed: formattingDisabled ? null : onBulletList,
          ),
          _ToolbarButton.icon(
            icon: Icons.format_list_numbered,
            tooltip: 'Numbered list',
            onPressed: formattingDisabled ? null : onNumberedList,
          ),
          _ToolbarButton.icon(
            icon: Icons.link,
            tooltip: 'Link',
            onPressed: formattingDisabled ? null : onLink,
          ),
          if (onImage != null)
            imageBusy
                ? _ToolbarButton.spinner(tooltip: 'Uploading image…')
                : _ToolbarButton.icon(
                    icon: Icons.image_outlined,
                    tooltip: 'Image',
                    onPressed: formattingDisabled ? null : onImage,
                  ),
          _ToolbarButton.icon(
            icon: previewActive ? Icons.visibility_off : Icons.visibility,
            tooltip: previewActive ? 'Edit' : 'Preview',
            onPressed: onTogglePreview,
            active: previewActive,
          ),
          _ToolbarButton.icon(
            icon: Icons.vertical_split_outlined,
            tooltip: splitActive ? 'Hide split view' : 'Split view',
            onPressed: previewActive ? null : onToggleSplit,
            active: splitActive,
          ),
          _ToolbarButton.icon(
            icon: Icons.fullscreen,
            tooltip: 'Fullscreen editor',
            onPressed: onFullscreen,
          ),
        ],
      ),
    );
  }
}

/// A 36x36 toolbar button with a soft grey background and rounded corners.
/// Renders either a glyph (`B`, `I`, `H`), a Material icon, or a spinner.
class _ToolbarButton extends StatelessWidget {
  const _ToolbarButton._({
    required this.tooltip,
    required this.onPressed,
    required this.active,
    required this.spinner,
    this.label,
    this.style,
    this.icon,
  });

  factory _ToolbarButton.text({
    required String label,
    required String tooltip,
    required TextStyle style,
    required VoidCallback? onPressed,
    bool active = false,
  }) =>
      _ToolbarButton._(
        tooltip: tooltip,
        onPressed: onPressed,
        active: active,
        spinner: false,
        label: label,
        style: style,
      );

  factory _ToolbarButton.icon({
    required IconData icon,
    required String tooltip,
    required VoidCallback? onPressed,
    bool active = false,
  }) =>
      _ToolbarButton._(
        tooltip: tooltip,
        onPressed: onPressed,
        active: active,
        spinner: false,
        icon: icon,
      );

  /// A disabled, busy-looking variant — replaces an icon while an async
  /// action (e.g. an image upload) is in flight.
  factory _ToolbarButton.spinner({required String tooltip}) =>
      _ToolbarButton._(
        tooltip: tooltip,
        onPressed: null,
        active: false,
        spinner: true,
      );

  final String tooltip;
  final VoidCallback? onPressed;
  final bool active;
  final bool spinner;
  final String? label;
  final TextStyle? style;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;
    final fg = disabled
        ? AppColors.textSecondary.withValues(alpha: 0.35)
        : active
            ? AppColors.primary
            : AppColors.textPrimary;
    final bg = active
        ? AppColors.primary.withValues(alpha: 0.1)
        : Colors.grey.shade200;
    final Widget content;
    if (spinner) {
      content = SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
      );
    } else if (icon != null) {
      content = Icon(icon, size: 20, color: fg);
    } else {
      content = Text(label!, style: style?.copyWith(color: fg));
    }
    return Tooltip(
      message: tooltip,
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: SizedBox(
            width: 38,
            height: 38,
            child: Center(child: content),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Editor body / preview
// ─────────────────────────────────────────────────────────────────────────────

class _Editor extends StatelessWidget {
  const _Editor({
    required this.controller,
    required this.focusNode,
    required this.minLines,
    required this.hintText,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final int minLines;
  final String? hintText;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => focusNode.requestFocus(),
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        minLines: minLines,
        maxLines: null,
        keyboardType: TextInputType.multiline,
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(12),
          hintText: hintText,
          hintStyle: TextStyle(
            color: AppColors.textSecondary.withValues(alpha: 0.7),
          ),
        ),
      ),
    );
  }
}

class _Preview extends StatelessWidget {
  const _Preview({
    required this.text,
    required this.minHeight,
    this.background,
  });

  final String text;
  final double minHeight;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: background,
      padding: const EdgeInsets.all(12),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: minHeight),
        child: text.trim().isEmpty
            ? Text(
                'Nothing to preview yet.',
                style: TextStyle(
                  color: AppColors.textSecondary.withValues(alpha: 0.7),
                  fontStyle: FontStyle.italic,
                ),
              )
            : MarkdownBody(
                data: text,
                styleSheet: appMarkdownStyleSheet(context),
                shrinkWrap: true,
              ),
      ),
    );
  }
}

class _FullscreenEditor extends StatefulWidget {
  const _FullscreenEditor({
    required this.controller,
    required this.label,
    required this.hintText,
    required this.onPickImage,
  });

  final TextEditingController controller;
  final String label;
  final String? hintText;
  final Future<String?> Function()? onPickImage;

  @override
  State<_FullscreenEditor> createState() => _FullscreenEditorState();
}

class _FullscreenEditorState extends State<_FullscreenEditor> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.label),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: AppRichTextField(
          controller: widget.controller,
          label: widget.label,
          hintText: widget.hintText,
          minLines: 12,
          onPickImage: widget.onPickImage,
        ),
      ),
    );
  }
}
