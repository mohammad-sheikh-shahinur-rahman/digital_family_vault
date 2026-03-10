import 'package:isar/isar.dart';

part 'app_settings.g.dart';

@collection
class AppSettings {
  Id id = 0;

  bool isBiometricEnabled = true;
  bool isDarkMode = false;
  String language = 'bn';
  bool isFirstRun = true;
}
