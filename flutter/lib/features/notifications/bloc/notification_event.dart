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

/// Fetch every cocktail id from the API and create notifications for any
/// that aren't already in the known set. Pulls all pages so the diff covers
/// the whole catalogue, not just what the list screen has scrolled to.
final class NotificationsCheckNewCocktails extends NotificationEvent {
  const NotificationsCheckNewCocktails(this.userId);

  final String userId;

  @override
  List<Object?> get props => [userId];
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
