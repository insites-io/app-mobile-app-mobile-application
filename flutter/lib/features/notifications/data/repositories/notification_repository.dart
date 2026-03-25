import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/notification_model.dart';

class NotificationRepository {
  NotificationRepository();

  final _storage = const FlutterSecureStorage();

  String _notificationsKey(String userId) => 'notifications_$userId';
  String _knownCocktailsKey(String userId) => 'known_cocktails_$userId';

  Future<List<AppNotification>> getNotifications(String userId) async {
    final raw = await _storage.read(key: _notificationsKey(userId));
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> _saveNotifications(
    String userId,
    List<AppNotification> notifications,
  ) async {
    final json = jsonEncode(notifications.map((n) => n.toJson()).toList());
    await _storage.write(key: _notificationsKey(userId), value: json);
  }

  Future<Set<int>> _getKnownCocktailIds(String userId) async {
    final raw = await _storage.read(key: _knownCocktailsKey(userId));
    if (raw == null || raw.isEmpty) return {};
    final list = jsonDecode(raw) as List<dynamic>;
    return list.map((e) => e as int).toSet();
  }

  Future<void> _saveKnownCocktailIds(String userId, Set<int> ids) async {
    final json = jsonEncode(ids.toList());
    await _storage.write(key: _knownCocktailsKey(userId), value: json);
  }

  /// Compares current cocktail IDs with previously known ones.
  /// Creates notifications for any new cocktails found.
  Future<List<AppNotification>> checkNewCocktails(
    String userId,
    List<int> currentCocktailIds,
  ) async {
    final known = await _getKnownCocktailIds(userId);
    final notifications = await getNotifications(userId);

    if (known.isEmpty && currentCocktailIds.isNotEmpty) {
      // First load — mark all as known without creating notifications.
      await _saveKnownCocktailIds(userId, currentCocktailIds.toSet());
      return notifications;
    }

    final newIds =
        currentCocktailIds.where((id) => !known.contains(id)).toList();

    for (final id in newIds) {
      notifications.insert(
        0,
        AppNotification(
          id: 'cocktail_$id',
          title: 'New cocktail added',
          body: "If you need a cocktail, look no further. We've got recipes "
              'for blended drinks, and more. Bottoms up!',
          cocktailId: id,
          createdAt: DateTime.now(),
        ),
      );
    }

    if (newIds.isNotEmpty) {
      await _saveKnownCocktailIds(
        userId,
        {...known, ...currentCocktailIds},
      );
      await _saveNotifications(userId, notifications);
    }

    return notifications;
  }

  Future<List<AppNotification>> toggleRead(
    String userId,
    String notificationId,
  ) async {
    final notifications = await getNotifications(userId);
    final index = notifications.indexWhere((n) => n.id == notificationId);
    if (index >= 0) {
      notifications[index] = notifications[index].copyWith(
        isRead: !notifications[index].isRead,
      );
      await _saveNotifications(userId, notifications);
    }
    return notifications;
  }

  Future<List<AppNotification>> deleteNotification(
    String userId,
    String notificationId,
  ) async {
    final notifications = await getNotifications(userId);
    notifications.removeWhere((n) => n.id == notificationId);
    await _saveNotifications(userId, notifications);
    return notifications;
  }
}
