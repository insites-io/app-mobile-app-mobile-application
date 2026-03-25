import 'package:equatable/equatable.dart';

sealed class NotificationEvent extends Equatable {
  const NotificationEvent();

  @override
  List<Object?> get props => [];
}

/// Load stored notifications from local storage.
final class NotificationsLoadRequested extends NotificationEvent {
  const NotificationsLoadRequested(this.userId);

  final String userId;

  @override
  List<Object?> get props => [userId];
}

/// Compare current cocktail IDs with known ones, creating notifications
/// for any new cocktails.
final class NotificationsCheckNewCocktails extends NotificationEvent {
  const NotificationsCheckNewCocktails({
    required this.userId,
    required this.cocktailIds,
  });

  final String userId;
  final List<int> cocktailIds;

  @override
  List<Object?> get props => [userId, cocktailIds];
}

/// Toggle the read/unread state of a notification.
final class NotificationToggleRead extends NotificationEvent {
  const NotificationToggleRead({
    required this.userId,
    required this.notificationId,
  });

  final String userId;
  final String notificationId;

  @override
  List<Object?> get props => [userId, notificationId];
}

/// Delete a notification.
final class NotificationDeleteRequested extends NotificationEvent {
  const NotificationDeleteRequested({
    required this.userId,
    required this.notificationId,
  });

  final String userId;
  final String notificationId;

  @override
  List<Object?> get props => [userId, notificationId];
}
