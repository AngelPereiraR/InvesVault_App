import 'package:flutter/material.dart';

import 'app.dart';
import 'core/services/notification_service.dart';
import 'core/services/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final storageService = StorageService();
  final notificationService = NotificationService();
  await notificationService.initialize();

  runApp(InvesVaultApp(
    storageService: storageService,
    notificationService: notificationService,
  ));
}

