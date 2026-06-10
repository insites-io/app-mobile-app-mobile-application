import 'dart:async';
import 'dart:convert';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';

/// Parsed result of an incoming password reset deep link.
@immutable
class PasswordResetLink {
  const PasswordResetLink({required this.email, required this.token});

  final String email;
  final String token;
}

/// Subscribes to incoming Universal Links / App Links and emits parsed
/// deep-link events. Handles both cold-start links (app opened from the
/// email while closed) and hot links (app already running).
///
/// Silently ignores links with unexpected shapes: malformed URLs, wrong
/// paths, missing params, or a base64-decoded email that is not valid
/// UTF-8. Callers see only well-formed events.
class DeepLinkService {
  DeepLinkService({AppLinks? appLinks}) : _appLinks = appLinks ?? AppLinks();

  final AppLinks _appLinks;
  final StreamController<PasswordResetLink> _resetLinks =
      StreamController<PasswordResetLink>.broadcast();
  StreamSubscription<Uri>? _subscription;
  bool _started = false;

  // Dedup the last emitted link so the same Universal Link arriving via
  // both the `app_links` stream and Flutter's platform navigation channel
  // (`WidgetsBindingObserver.didPushRouteInformation`) is delivered once.
  PasswordResetLink? _lastEmitted;

  /// A stream of password reset deep-link events. Broadcasts, so late
  /// subscribers will not receive cold-start links — use [start] to prime
  /// the stream before subscribing if that matters.
  Stream<PasswordResetLink> get resetLinkStream => _resetLinks.stream;

  /// Begin listening for links. Safe to call more than once.
  Future<void> start() async {
    if (_started) return;
    _started = true;

    _subscription = _appLinks.uriLinkStream.listen(
      _handleUri,
      onError: (_) {
        // Platform plugin errors should not crash the app.
      },
    );

    try {
      final initial = await _appLinks.getInitialLink();
      if (initial != null) _handleUri(initial);
    } catch (_) {
      // Initial link lookup failed — ignore; runtime links still work.
    }
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    await _resetLinks.close();
  }

  void _handleUri(Uri uri) {
    final parsed = _tryParseResetLink(uri);
    if (parsed != null) _emit(parsed);
  }

  /// Accept a URI sourced from outside the `app_links` plugin — typically
  /// `WidgetsBindingObserver.didPushRouteInformation` for Universal Links
  /// that iOS delivers via Flutter's platform navigation channel.
  ///
  /// Returns `true` if the URI was recognised as a password reset link
  /// (in which case it has been emitted on [resetLinkStream]), `false`
  /// otherwise. Callers can use the return value to tell the Flutter
  /// framework whether the route information was handled.
  bool acceptUri(Uri uri) {
    final parsed = _tryParseResetLink(uri);
    if (parsed == null) return false;
    _emit(parsed);
    return true;
  }

  void _emit(PasswordResetLink link) {
    final last = _lastEmitted;
    if (last != null && last.email == link.email && last.token == link.token) {
      return;
    }
    _lastEmitted = link;
    _resetLinks.add(link);
  }

  /// Returns a [PasswordResetLink] if [uri] is a well-formed reset link,
  /// or null otherwise. Exposed for testing.
  @visibleForTesting
  static PasswordResetLink? tryParseResetLink(Uri uri) =>
      _tryParseResetLink(uri);

  static PasswordResetLink? _tryParseResetLink(Uri uri) {
    if (uri.path != '/api/mobile/app-redirect') return null;

    final type = uri.queryParameters['type'];
    final token = uri.queryParameters['token'];
    final emailBase64 = uri.queryParameters['email'];

    if (type != 'reset-password' ||
        token == null ||
        token.isEmpty ||
        emailBase64 == null ||
        emailBase64.isEmpty) {
      return null;
    }

    final String email;
    try {
      email = utf8.decode(base64Url.decode(base64Url.normalize(emailBase64)));
    } catch (_) {
      return null;
    }

    if (email.isEmpty) return null;

    return PasswordResetLink(email: email, token: token);
  }
}
