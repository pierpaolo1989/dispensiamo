import 'package:flutter/foundation.dart';
import 'package:dispensiamo/l10n/app_strings.dart';
import 'package:dispensiamo/service/app_settings.dart';
import 'package:dispensiamo/service/notification_service.dart';
import 'package:dispensiamo/theme/app_theme.dart';
import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _updateLanguage(
    BuildContext context,
    String languageCode,
  ) async {
    try {
      await AppSettings.instance.setLanguageCode(languageCode);
      await NotificationService.instance.rescheduleAll();
    } catch (error) {
      if (!context.mounted) return;
      final strings = AppStrings.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.settingsSaveError(error))),
      );
    }
  }

  Future<void> _updateReminderDays(BuildContext context, int days) async {
    try {
      await AppSettings.instance.setDefaultExpirationAlertDays(days);
      final permissionGranted = await NotificationService.instance
          .rescheduleAll(requestPermission: days > 0);
      if (!permissionGranted && context.mounted) {
        final strings = AppStrings.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              kIsWeb
                  ? strings.notificationsUnavailable
                  : strings.notificationsDenied,
            ),
          ),
        );
      }
    } catch (error) {
      if (!context.mounted) return;
      final strings = AppStrings.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.settingsSaveError(error))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final settings = AppSettings.instance;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      children: [
        Text(
          strings.settingsDescription,
          style: const TextStyle(color: AppColors.muted, height: 1.4),
        ),
        const SizedBox(height: 24),
        _SettingsCard(
          icon: Icons.language_rounded,
          title: strings.language,
          child: DropdownButtonFormField<String>(
            initialValue: settings.languageCode,
            decoration: InputDecoration(labelText: strings.language),
            items: [
              DropdownMenuItem(
                value: 'it',
                child: Text(strings.italian),
              ),
              DropdownMenuItem(
                value: 'en',
                child: Text(strings.english),
              ),
            ],
            onChanged: (value) {
              if (value != null) _updateLanguage(context, value);
            },
          ),
        ),
        const SizedBox(height: 16),
        _SettingsCard(
          icon: Icons.notifications_active_outlined,
          title: strings.expirationReminders,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<int>(
                initialValue: settings.defaultExpirationAlertDays,
                decoration: InputDecoration(
                  labelText: strings.defaultAlert,
                ),
                items: [0, 1, 2, 3, 7, 14].map((days) {
                  return DropdownMenuItem(
                    value: days,
                    child: Text(
                      days == 0
                          ? strings.noReminder
                          : strings.defaultAlertDays(days),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) _updateReminderDays(context, value);
                },
              ),
              const SizedBox(height: 12),
              Text(
                strings.reminderOverrideHint,
                style: const TextStyle(
                  color: AppColors.muted,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                strings.reminderPermissionExplanation,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFF8F8F5),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.black),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}
