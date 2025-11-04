import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final notificationServiceProvider = Provider((ref) {
  final service = NotificationService();
  ref.onDispose(() => service.dispose());
  return service;
});

class NotificationService {
  final _newNotificationController = StreamController<void>.broadcast();
  final _markReadController = StreamController<int>.broadcast();

  Stream<void> get onNewNotification => _newNotificationController.stream;
  Stream<int> get onMarkRead => _markReadController.stream;

  void notifyNewNotification() {
    _newNotificationController.add(null);
  }

  void notifyMarkRead(int notificationId) {
    _markReadController.add(notificationId);
  }

  void dispose() {
    _newNotificationController.close();
    _markReadController.close();
  }
}
