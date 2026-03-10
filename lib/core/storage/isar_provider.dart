import 'package:digital_family_vault/features/documents/domain/models/document.dart';
import 'package:digital_family_vault/features/family/domain/models/family_member.dart';
import 'package:digital_family_vault/features/settings/domain/models/app_settings.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'isar_provider.g.dart';

@Riverpod(keepAlive: true)
Future<Isar> isar(IsarRef ref) async {
  final dir = await getApplicationDocumentsDirectory();
  return Isar.open(
    [FamilyMemberSchema, AppDocumentSchema, AppSettingsSchema],
    directory: dir.path,
  );
}
