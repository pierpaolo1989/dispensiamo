import 'package:dispensiamo/service/expired_products_service.dart';
import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';

class WorkManagerService {
  static const String deleteExpiredProductsTaskName =
      'deleteExpiredProductsDaily';

  static Future<void> initializeWorkManager() async {
    if (kIsWeb) return;

    try {
      await Workmanager().initialize(
        callbackDispatcher,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Failed to initialize WorkManager: $e');
      }
    }
  }

  static Future<void> scheduleDeleteExpiredProductsTask() async {
    if (kIsWeb) return;

    try {
      await Workmanager().registerPeriodicTask(
        deleteExpiredProductsTaskName,
        deleteExpiredProductsTaskName,
        frequency: const Duration(days: 1),
        initialDelay: const Duration(hours: 1),
      );

      if (kDebugMode) {
        print('Scheduled daily task to delete expired products');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to schedule delete expired products task: $e');
      }
    }
  }

  static Future<void> cancelDeleteExpiredProductsTask() async {
    if (kIsWeb) return;

    try {
      await Workmanager().cancelByUniqueName(deleteExpiredProductsTaskName);

      if (kDebugMode) {
        print('Cancelled daily delete expired products task');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to cancel delete expired products task: $e');
      }
    }
  }
}

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      if (task == WorkManagerService.deleteExpiredProductsTaskName) {
        final deletedCount =
            await ExpiredProductsService.deleteExpiredProducts();
        if (kDebugMode) {
          print('Deleted $deletedCount expired products');
        }
        return true;
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Error in work task: $e');
      }
      return false;
    }
  });
}
