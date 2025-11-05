import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/notifications_repository.dart';
import '../data/notification_models.dart';

final unreadNotificationsCountProvider = StreamProvider<int>((ref) async* {
  final repo = ref.watch(notificationsRepositoryProvider);

  // Initial count
  try {
    final notifications = await repo.list(
      scope: NotificationScope.unread,
      limit: 100,
    );
    yield notifications.length;
  } catch (e) {
    yield 0;
  }

  // Listen to changes every 30 seconds
  await for (final _ in Stream.periodic(const Duration(seconds: 30))) {
    try {
      final notifications = await repo.list(
        scope: NotificationScope.unread,
        limit: 100,
      );
      yield notifications.length;
    } catch (e) {
      yield 0;
    }
  }
});
