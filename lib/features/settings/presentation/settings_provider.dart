import 'package:digital_family_vault/core/storage/isar_provider.dart';
import 'package:digital_family_vault/features/settings/data/settings_repository.dart';
import 'package:digital_family_vault/features/settings/domain/models/app_settings.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'settings_provider.g.dart';

@riverpod
class SettingsNotifier extends _$SettingsNotifier {
  @override
  Future<AppSettings> build() async {
    final isar = await ref.watch(isarProvider.future);
    return SettingsRepository(isar).getSettings();
  }

  Future<void> updateSettings(AppSettings settings) async {
    final isar = await ref.read(isarProvider.future);
    final repo = SettingsRepository(isar);
    await repo.updateSettings(settings);
    ref.invalidateSelf();
  }

  Future<void> toggleBiometric(bool value) async {
    final current = await future;
    current.isBiometricEnabled = value;
    await updateSettings(current);
  }

  Future<void> toggleDarkMode(bool value) async {
    final current = await future;
    current.isDarkMode = value;
    await updateSettings(current);
  }

  Future<void> setLanguage(String lang) async {
    final current = await future;
    current.language = lang;
    await updateSettings(current);
  }
}
