import 'package:flutter/material.dart';

import '../../config/app_colors.dart';

/// Severity of an [AppToast] — picks the border, icon, and progress-bar colour.
enum AppToastType { success, error }

/// Notyf-style transient toast pinned to the top-right of the screen.
///
/// Built around an [OverlayEntry] so it floats above any Scaffold, route
/// transition, or modal. Only one toast lives on screen at a time — a new
/// `show()` call cancels and replaces the previous toast.
///
/// Visual spec (Figma 17545:72963 / 17545:73507):
/// - 1 px border in the variant colour (`AppColors.successBadge` for
///   success, `AppColors.error` for error).
/// - 4 px corner radius, soft 0×8 / 8-blur drop shadow.
/// - 18 px icon + 12 px gap + 12 pt body text.
/// - 4 px progress bar pinned to the bottom edge, shrinking from full to
///   empty as the toast counts down.
class AppToast extends StatefulWidget {
  const AppToast._({
    required this.message,
    required this.type,
    required this.duration,
    required this.onDismiss,
  });

  final String message;
  final AppToastType type;
  final Duration duration;
  final VoidCallback onDismiss;

  /// Tracks the currently visible toast so [show] can replace it.
  static OverlayEntry? _current;

  /// Pop a transient toast for [message]. Replaces any toast already on
  /// screen and auto-dismisses after [duration].
  static void show(
    BuildContext context,
    String message, {
    AppToastType type = AppToastType.success,
    Duration duration = const Duration(seconds: 4),
  }) {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;

    // Replace any toast already on screen — only one at a time, matching
    // Notyf's behaviour.
    _current?.remove();
    _current = null;

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => AppToast._(
        message: message,
        type: type,
        duration: duration,
        onDismiss: () {
          if (identical(_current, entry)) _current = null;
          entry.remove();
        },
      ),
    );
    _current = entry;
    overlay.insert(entry);
  }

  @override
  State<AppToast> createState() => _AppToastState();
}

class _AppToastState extends State<AppToast>
    with TickerProviderStateMixin {
  static const Duration _slideDuration = Duration(milliseconds: 200);

  /// Drives slide-in / slide-out and fade.
  late final AnimationController _slide;

  /// Drives the bottom progress bar from full (1.0) to empty (0.0).
  late final AnimationController _progress;

  late final Animation<Offset> _offset;
  late final Animation<double> _fade;
  bool _dismissed = false;

  @override
  void initState() {
    super.initState();
    _slide = AnimationController(vsync: this, duration: _slideDuration)
      ..forward();
    _offset = Tween<Offset>(
      begin: const Offset(0.3, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slide, curve: Curves.easeOutCubic));
    _fade = CurvedAnimation(parent: _slide, curve: Curves.easeOut);

    _progress = AnimationController(vsync: this, duration: widget.duration)
      ..forward()
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) _dismiss();
      });
  }

  Future<void> _dismiss() async {
    if (_dismissed) return;
    _dismissed = true;
    await _slide.reverse();
    if (!mounted) return;
    widget.onDismiss();
  }

  @override
  void dispose() {
    _slide.dispose();
    _progress.dispose();
    super.dispose();
  }

  ({Color color, IconData icon}) _variantStyle(AppToastType type) {
    switch (type) {
      case AppToastType.success:
        // AppColors.successBadge is #048801 — matches the Figma exactly.
        return (color: AppColors.successBadge, icon: Icons.check_circle);
      case AppToastType.error:
        return (color: AppColors.error, icon: Icons.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = _variantStyle(widget.type);

    return Positioned(
      top: 0,
      left: 16,
      right: 16,
      child: SafeArea(
        child: Align(
          alignment: AlignmentDirectional.topEnd,
          child: ConstrainedBox(
            // Keep the toast clearly anchored to the right rather than
            // spanning the full width on phones — matches the Figma where
            // the card sits ~280pt wide in the top-right corner.
            constraints: const BoxConstraints(maxWidth: 280),
            child: FadeTransition(
              opacity: _fade,
              child: SlideTransition(
                position: _offset,
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      border: Border.all(color: style.color, width: 1),
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x05000000),
                          offset: Offset(0, 8),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: Stack(
                        children: [
                          Padding(
                            // 16 horizontal × 12 vertical per Figma; bump
                            // bottom to 16 so the 4 px progress bar doesn't
                            // crowd the text.
                            padding: const EdgeInsets.fromLTRB(
                              16, 12, 16, 16,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  style.icon,
                                  size: 18,
                                  color: style.color,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Semantics(
                                    liveRegion: true,
                                    label: widget.message,
                                    child: Text(
                                      widget.message,
                                      // Use the app's Poppins theme instead
                                      // of forcing Montserrat — keeps the
                                      // toast typographically consistent
                                      // with every other surface.
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                        color: AppColors.textPrimary,
                                        height: 18 / 12,
                                      ),
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child: SizedBox(
                              height: 4,
                              child: AnimatedBuilder(
                                animation: _progress,
                                builder: (_, _) => LinearProgressIndicator(
                                  // Bar fills left → right as time elapses,
                                  // signalling "how much time has passed"
                                  // (rather than "how much remains" which
                                  // would shrink right → left).
                                  value: _progress.value,
                                  backgroundColor: Colors.transparent,
                                  valueColor: AlwaysStoppedAnimation(
                                    style.color,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
