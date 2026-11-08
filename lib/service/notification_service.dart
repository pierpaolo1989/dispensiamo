import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as timezone_data;
import 'package:timezone/timezone.dart' as timezone;

import 'app_settings.dart';
import 'database_service.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  Future<void> initialize() async {
    timezone_data.initializeTimeZones();
    if (kIsWeb) {
      _isInitialized = true;
      return;
    }

    if (!kIsWeb) {
      final localTimezone = await FlutterTimezone.getLocalTimezone();
      timezone.setLocalLocation(timezone.getLocation(localTimezone.identifier));
    }

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
        macOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
        linux: LinuxInitializationSettings(
          defaultActionName: 'Open notification',
        ),
        windows: WindowsInitializationSettings(
          appName: 'Dispensiamo',
          appUserModelId: 'Com.Soa.Dispensiamo',
          guid: 'a6b49289-4eba-4db4-bf0f-df6d5f30c8f2',
        ),
      ),
    );
    _isInitialized = true;
  }

  Future<bool> scheduleProductReminder({
    required int productId,
    required String productName,
    required String? expirationDate,
    required int? alertDays,
  }) =>
      _scheduleProductReminder(
        productId: productId,
        productName: productName,
        expirationDate: expirationDate,
        alertDays: alertDays,
        requestPermission: true,
      );

  Future<void> cancelProductReminder(int productId) async {
    _ensureInitialized();
    if (kIsWeb) return;
    await _plugin.cancel(id: productId);
  }

  Future<bool> _scheduleProductReminder({
    required int productId,
    required String productName,
    required String? expirationDate,
    required int? alertDays,
    required bool requestPermission,
  }) async {
    _ensureInitialized();
    if (kIsWeb) return false;
    await _plugin.cancel(id: productId);
    if (expirationDate == null) return true;

    final days = alertDays ?? AppSettings.instance.defaultExpirationAlertDays;
    if (days == 0) return true;

    final expiry = DateTime.parse(expirationDate);
    final reminderDate = DateTime(expiry.year, expiry.month, expiry.day)
        .subtract(Duration(days: days));
    final scheduledDate = timezone.TZDateTime(
      timezone.local,
      reminderDate.year,
      reminderDate.month,
      reminderDate.day,
      9,
    );
    if (!scheduledDate.isAfter(timezone.TZDateTime.now(timezone.local))) {
      return true;
    }
    if (requestPermission && !await _requestPermission()) return false;

    final isItalian = AppSettings.instance.languageCode == 'it';
    final dayPhrase = days == 1
        ? (isItalian ? 'domani' : 'tomorrow')
        : (isItalian ? 'tra $days giorni' : 'in $days days');

    await _plugin.zonedSchedule(
      id: productId,
      title: isItalian ? 'Prodotto in scadenza' : 'Product expiring soon',
      body: isItalian
          ? '$productName scade $dayPhrase.'
          : '$productName expires $dayPhrase.',
      scheduledDate: scheduledDate,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          'expiration_reminders_${isItalian ? 'it' : 'en'}',
          isItalian ? 'Promemoria scadenze' : 'Expiration reminders',
          channelDescription: isItalian
              ? 'Avvisi per i prodotti in scadenza'
              : 'Reminders for products that are expiring',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: const DarwinNotificationDetails(),
        macOS: const DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: productId.toString(),
    );
    return true;
  }

  Future<bool> rescheduleAll({bool requestPermission = false}) async {
    _ensureInitialized();
    final products = await DatabaseService.getAllProducts();
    final hasReminders = products.any((product) {
      final expirationDate = product['expiration_date'] as String?;
      final alertDays = product['alert_days'] as int?;
      return expirationDate != null &&
          (alertDays ?? AppSettings.instance.defaultExpirationAlertDays) > 0;
    });
    if (kIsWeb && hasReminders) return false;
    if (hasReminders) {
      final permissionGranted = requestPermission
          ? await _requestPermission()
          : await _notificationsAreEnabled();
      if (!permissionGranted) return false;
    }

    for (final product in products) {
      await _scheduleProductReminder(
        productId: int.parse(product['id'] as String),
        productName: product['name'] as String,
        expirationDate: product['expiration_date'] as String?,
        alertDays: product['alert_days'] as int?,
        requestPermission: false,
      );
    }
    return true;
  }

  Future<bool> _requestPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      return await android.requestNotificationsPermission() ?? true;
    }

    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      return await ios.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          true;
    }
    return true;
  }

  Future<bool> _notificationsAreEnabled() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      return await android.areNotificationsEnabled() ?? false;
    }

    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      return await ios.checkPermissions().then(
            (permissions) => permissions?.isEnabled ?? false,
          );
    }
    return true;
  }

  void _ensureInitialized() {
    if (!_isInitialized) {
      throw StateError('NotificationService has not been initialized.');
    }
  }
}
