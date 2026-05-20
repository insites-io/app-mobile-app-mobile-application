import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/app_colors.dart';

/// Styled markdown renderer shared between the rich-text editor preview and
/// the cocktail detail tabs so the two views can't drift apart.
class AppMarkdownView extends StatelessWidget {
  const AppMarkdownView({
    super.key,
    required this.data,
    this.shrinkWrap = true,
    this.selectable = false,
  });

  final String data;
  final bool shrinkWrap;
  final bool selectable;

  @override
  Widget build(BuildContext context) {
    return MarkdownBody(
      data: data,
      styleSheet: appMarkdownStyleSheet(context),
      shrinkWrap: shrinkWrap,
      selectable: selectable,
      onTapLink: (text, href, title) async {
        if (href == null || href.isEmpty) return;
        final uri = Uri.tryParse(href);
        if (uri == null) return;
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
    );
  }
}

/// The single source of truth for how cocktail markdown looks across the app.
MarkdownStyleSheet appMarkdownStyleSheet(BuildContext context) {
  final theme = Theme.of(context);
  final bodyStyle = theme.textTheme.bodyLarge?.copyWith(
        color: AppColors.textPrimary,
        fontSize: 14,
        height: 1.5,
      ) ??
      const TextStyle(fontSize: 14, height: 1.5);

  return MarkdownStyleSheet(
    p: bodyStyle,
    strong: bodyStyle.copyWith(fontWeight: FontWeight.w700),
    em: bodyStyle.copyWith(fontStyle: FontStyle.italic),
    h1: theme.textTheme.headlineSmall?.copyWith(
      fontWeight: FontWeight.w700,
      color: AppColors.textPrimary,
    ),
    h2: theme.textTheme.titleLarge?.copyWith(
      fontWeight: FontWeight.w700,
      color: AppColors.textPrimary,
    ),
    h3: theme.textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w700,
      color: AppColors.textPrimary,
    ),
    listBullet: bodyStyle,
    a: bodyStyle.copyWith(
      color: AppColors.primary,
      decoration: TextDecoration.underline,
    ),
    blockquote: bodyStyle.copyWith(
      color: AppColors.textSecondary,
      fontStyle: FontStyle.italic,
    ),
    blockquoteDecoration: BoxDecoration(
      color: Colors.grey.shade100,
      border: Border(
        left: BorderSide(color: AppColors.primary, width: 3),
      ),
    ),
    blockquotePadding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
    code: bodyStyle.copyWith(
      fontFamily: 'monospace',
      backgroundColor: Colors.grey.shade100,
    ),
    codeblockDecoration: BoxDecoration(
      color: Colors.grey.shade100,
      borderRadius: BorderRadius.circular(4),
    ),
    codeblockPadding: const EdgeInsets.all(12),
    listIndent: 20,
    blockSpacing: 10,
  );
}
