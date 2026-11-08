import 'package:dispensiamo/service/database_service.dart';
import 'package:flutter/material.dart';

class AppSettings extends ChangeNotifier {
  AppSettings._();

  static final AppSettings instance = AppSettings._();

  String _languageCode = 'it';
  int _defaultExpirationAlertDays = 3;

  String get languageCode => _languageCode;
  Locale get locale => Locale(_languageCode);
  int get defaultExpirationAlertDays => _defaultExpirationAlertDays;

  Future<void> load() async {
    final savedLanguage = await DatabaseService.getSetting('language');
    _languageCode =
        savedLanguage == 'it' || savedLanguage == 'en' ? savedLanguage! : 'it';
    final savedDays = await DatabaseService.getSetting('default_alert_days');
    final parsedDays = int.tryParse(savedDays ?? '');
    _defaultExpirationAlertDays =
        parsedDays != null && parsedDays >= 0 && parsedDays <= 30
            ? parsedDays
            : 3;
  }

  Future<void> setLanguageCode(String languageCode) async {
    if (languageCode != 'it' && languageCode != 'en') {
      throw ArgumentError.value(languageCode, 'languageCode');
    }
    if (_languageCode == languageCode) return;
    await DatabaseService.setSetting('language', languageCode);
    _languageCode = languageCode;
    notifyListeners();
  }

  Future<void> setDefaultExpirationAlertDays(int days) async {
    if (days < 0 || days > 30) {
      throw ArgumentError.value(days, 'days');
    }
    if (_defaultExpirationAlertDays == days) return;
    await DatabaseService.setSetting('default_alert_days', '$days');
    _defaultExpirationAlertDays = days;
    notifyListeners();
  }
}
