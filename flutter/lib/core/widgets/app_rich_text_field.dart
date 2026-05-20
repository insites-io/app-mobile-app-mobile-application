import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../../config/app_colors.dart';
import 'app_markdown_view.dart';

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
  });

  final TextEditingController controller;
  final String label;
  final String? hintText;
  final int minLines;

  @override
  State<AppRichTextField> createState() => _AppRichTextFieldState();
}

class _AppRichTextFieldState extends State<AppRichTextField> {
  final FocusNode _focusNode = FocusNode();
  bool _previewMode = false;
  bool _splitMode = false;

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

  /// Wrap the current selection with [marker] on both sides. If nothing is
  /// selected, drop the markers at the caret with the caret placed between
  /// them so the user can keep typing.
  void _wrap(String marker) {
    final controller = widget.controller;
    final selection = controller.selection;
    final text = controller.text;
    final position =
        selection.isValid ? selection.baseOffset : text.length;
    final hasRange = selection.isValid && !selection.isCollapsed;
    final selected = hasRange ? selection.textInside(text) : '';

    final replacement = '$marker$selected$marker';
    final newStart = hasRange ? selection.start : position;
    final newEnd = hasRange ? selection.end : position;
    final newText = text.replaceRange(newStart, newEnd, replacement);

    controller.text = newText;
    if (hasRange) {
      controller.selection = TextSelection(
        baseOffset: newStart + marker.length,
        extentOffset: newStart + marker.length + selected.length,
      );
    } else {
      controller.selection = TextSelection.collapsed(
        offset: newStart + marker.length,
      );
    }
    _focusNode.requestFocus();
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

  /// Insert an image markdown snippet. The `alt` placeholder is left for the
  /// user to overwrite — caret lands inside the URL slot so they can paste.
  void _insertImage() {
    final controller = widget.controller;
    final selection = controller.selection;
    final text = controller.text;
    final position =
        selection.isValid ? selection.baseOffset : text.length;
    final replacement = '![alt](https://)';
    final newText = text.replaceRange(position, position, replacement);

    controller.text = newText;
    final urlStart = position + 'alt'.length + 4; // `![alt](`
    final urlEnd = position + replacement.length - 1;
    controller.selection = TextSelection(
      baseOffset: urlStart,
      extentOffset: urlEnd,
    );
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
              _Toolbar(
                onBold: () => _wrap('**'),
                onItalic: () => _wrap('*'),
                onHeading: () => _prefixLines((_) => '# '),
                onQuote: () => _prefixLines((_) => '> '),
                onBulletList: () => _prefixLines((_) => '- '),
                onNumberedList: () => _prefixLines((i) => '${i + 1}. '),
                onLink: _insertLink,
                onImage: _insertImage,
                onTogglePreview: _togglePreview,
                onToggleSplit: _toggleSplit,
                onFullscreen: _openFullscreen,
                previewActive: _previewMode,
                splitActive: _splitMode,
              ),
              _buildBody(context),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_previewMode) {
      return _Preview(
        text: widget.controller.text,
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
            text: widget.controller.text,
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
  final VoidCallback onImage;
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
          _ToolbarButton.icon(
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
/// Renders either a glyph (`B`, `I`, `H`) or a Material icon.
class _ToolbarButton extends StatelessWidget {
  const _ToolbarButton._({
    required this.tooltip,
    required this.onPressed,
    required this.active,
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
        icon: icon,
      );

  final String tooltip;
  final VoidCallback? onPressed;
  final bool active;
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
            child: Center(
              child: icon != null
                  ? Icon(icon, size: 20, color: fg)
                  : Text(label!, style: style?.copyWith(color: fg)),
            ),
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
  });

  final TextEditingController controller;
  final String label;
  final String? hintText;

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
        ),
      ),
    );
  }
}
