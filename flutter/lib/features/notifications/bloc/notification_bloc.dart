import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/repositories/notification_repository.dart';
import 'notification_event.dart';
import 'notification_state.dart';

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  NotificationBloc({required this.notificationRepository})
      : super(const NotificationInitial()) {
    on<NotificationsLoadRequested>(_onLoadRequested);
    on<NotificationsCheckNewCocktails>(_onCheckNewCocktails);
    on<NotificationToggleRead>(_onToggleRead);
    on<NotificationDeleteRequested>(_onDelete);
  }

  final NotificationRepository notificationRepository;

  Future<void> _onLoadRequested(
    NotificationsLoadRequested event,
    Emitter<NotificationState> emit,
  ) async {
    final notifications =
        await notificationRepository.getNotifications(event.userId);
    emit(NotificationsLoaded(notifications));
  }

  Future<void> _onCheckNewCocktails(
    NotificationsCheckNewCocktails event,
    Emitter<NotificationState> emit,
  ) async {
    final notifications = await notificationRepository.checkNewCocktails(
      event.userId,
      event.cocktailIds,
    );
    emit(NotificationsLoaded(notifications));
  }

  Future<void> _onToggleRead(
    NotificationToggleRead event,
    Emitter<NotificationState> emit,
  ) async {
    final notifications = await notificationRepository.toggleRead(
      event.userId,
      event.notificationId,
    );
    emit(NotificationsLoaded(notifications));
  }

  Future<void> _onDelete(
    NotificationDeleteRequested event,
    Emitter<NotificationState> emit,
  ) async {
    final notifications = await notificationRepository.deleteNotification(
      event.userId,
      event.notificationId,
    );
    emit(NotificationsLoaded(notifications));
  }
}
