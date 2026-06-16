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
      sizedImageBuilder: _buildImage,
      onTapLink: _onTapLink,
    );
  }

  /// Render markdown images with explicit loading + error states so iOS
  /// doesn't silently fall through to a zero-size widget when the network
  /// fetch fails. Uses the same `Image.network` pattern as the cocktail
  /// card / hero so behavior is consistent across the app.
  Widget _buildImage(MarkdownImageConfig config) {
    final alt = config.alt;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 240),
          child: Image.network(
            config.uri.toString(),
            width: config.width,
            height: config.height,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                color: Colors.grey.shade200,
                height: 160,
                alignment: Alignment.center,
                child: const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Tooltip(
                message:
                    alt?.isNotEmpty == true ? alt! : config.uri.toString(),
                child: Container(
                  color: Colors.grey.shade200,
                  height: 120,
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.broken_image_outlined,
                    color: Colors.grey.shade500,
                    size: 32,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  /// Open links tapped inside the rendered markdown.
  ///
  /// Web URLs (`http`/`https`) skip `canLaunchUrl` and call `launchUrl`
  /// directly. iOS's `canOpenURL` returns false for schemes that aren't
  /// in `LSApplicationQueriesSchemes`, and on some iOS versions it
  /// rejects `http`/`https` too when the whitelist is absent — so we
  /// fail open and let `launchUrl` itself decide. Errors are caught and
  /// silently dropped (invalid URI, no browser installed, etc.).
  ///
  /// For non-web schemes (mailto, tel, …) we keep the `canLaunchUrl`
  /// gate; the matching schemes are in Info.plist.
  Future<void> _onTapLink(String text, String? href, String title) async {
    if (href == null || href.isEmpty) return;
    final uri = Uri.tryParse(href);
    if (uri == null) return;
    final isWeb = uri.scheme == 'http' || uri.scheme == 'https';
    try {
      if (isWeb || await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      // Swallow — bad URI, no handler, simulator without browser, etc.
    }
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
