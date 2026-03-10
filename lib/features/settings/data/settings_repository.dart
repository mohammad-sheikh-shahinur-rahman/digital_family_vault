import 'package:digital_family_vault/features/settings/domain/models/app_settings.dart';
import 'package:isar/isar.dart';

class SettingsRepository {
  final Isar isar;

  SettingsRepository(this.isar);

  Future<AppSettings> getSettings() async {
    final settings = await isar.appSettings.get(0);
    if (settings == null) {
      final defaultSettings = AppSettings();
      await isar.writeTxn(() async {
        await isar.appSettings.put(defaultSettings);
      });
      return defaultSettings;
    }
    return settings;
  }

  Future<void> updateSettings(AppSettings settings) async {
    await isar.writeTxn(() async {
      await isar.appSettings.put(settings);
    });
  }
}
