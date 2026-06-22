import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../config/app_colors.dart';
import '../../core/widgets/widgets.dart';
import '../authentication/bloc/auth_bloc.dart';
import '../authentication/bloc/auth_state.dart';
import 'bloc/notification_bloc.dart';
import 'bloc/notification_event.dart';
import 'bloc/notification_state.dart';
import 'data/models/notification_model.dart';

class NotificationsTab extends StatelessWidget {
  const NotificationsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          const AppHeader(title: 'Notifications', showMenuIcon: false),
          Expanded(
            child: BlocBuilder<NotificationBloc, NotificationState>(
              builder: (context, state) {
                if (state is! NotificationsLoaded ||
                    state.notifications.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Text(
                        'No notifications yet',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: state.notifications.length,
                  itemBuilder: (context, index) {
                    final notification = state.notifications[index];
                    return Column(
                      key: ValueKey(notification.id),
                      children: [
                        _NotificationTile(notification: notification),
                        Divider(
                          height: 1,
                          thickness: 0.5,
                          color: AppColors.divider,
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification});

  final AppNotification notification;

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  @override
  Widget build(BuildContext context) {
    // Use the broad helper so swipe-to-toggle/delete still works after a
    // failed profile update (AuthProfileError keeps the user logged in
    // but isn't AuthAuthenticated).
    final user = authenticatedUserOf(context.read<AuthBloc>().state);
    final userId = user?.id ?? '';

    return Dismissible(
      key: ValueKey(notification.id),
      background: Container(
        color: notification.isRead
            ? AppColors.warning
            : AppColors.success,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 24),
        child: Text(
          notification.isRead ? 'Mark as\nUnread' : 'Mark as\nRead',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
      secondaryBackground: Container(
        color: AppColors.error,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Text(
          'Delete',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          context.read<NotificationBloc>().add(
                NotificationDeleteRequested(
                  userId: userId,
                  notificationId: notification.id,
                ),
              );
          return true;
        } else {
          context.read<NotificationBloc>().add(
                NotificationToggleRead(
                  userId: userId,
                  notificationId: notification.id,
                ),
              );
          return false;
        }
      },
      child: Container(
        color: AppColors.backgroundLight,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    notification.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: notification.isRead
                          ? FontWeight.w500
                          : FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  _formatTime(notification.createdAt),
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              notification.body,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
