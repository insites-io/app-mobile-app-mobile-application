import 'package:equatable/equatable.dart';

import '../data/models/notification_model.dart';

sealed class NotificationState extends Equatable {
  const NotificationState();

  @override
  List<Object?> get props => [];

  int get unreadCount => 0;
}

final class NotificationInitial extends NotificationState {
  const NotificationInitial();
}

final class NotificationsLoaded extends NotificationState {
  const NotificationsLoaded(this.notifications);

  final List<AppNotification> notifications;

  @override
  int get unreadCount => notifications.where((n) => !n.isRead).length;

  @override
  List<Object?> get props => [notifications];
}
