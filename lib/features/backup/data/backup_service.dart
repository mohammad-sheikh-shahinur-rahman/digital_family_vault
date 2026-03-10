import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';

class BackupService {
  Future<void> exportVault() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final vaultDir = Directory(p.join(appDir.path, 'vault'));
      
      final zipFile = File(p.join(appDir.path, 'family_vault_backup.zip'));
      final encoder = ZipFileEncoder();
      encoder.create(zipFile.path);

      // Add encrypted files
      if (await vaultDir.exists()) {
        await for (final entity in vaultDir.list()) {
          if (entity is File) {
            encoder.addFile(entity, p.join('vault', p.basename(entity.path)));
          }
        }
      }

      // Add Isar Database
      final isarFile = File(p.join(appDir.path, 'default.isar'));
      if (await isarFile.exists()) {
        encoder.addFile(isarFile, 'default.isar');
      }
      
      encoder.close();

      await Share.shareXFiles(
        [XFile(zipFile.path)],
        subject: 'Digital Family Vault Backup',
      );
      
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> restoreVault() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zip'],
      );

      if (result != null) {
        final zipFile = File(result.files.single.path!);
        final bytes = await zipFile.readAsBytes();
        final archive = ZipDecoder().decodeBytes(bytes);

        final appDir = await getApplicationDocumentsDirectory();

        for (final file in archive) {
          final filename = file.name;
          if (file.isFile) {
            final data = file.content as List<int>;
            File(p.join(appDir.path, filename))
              ..createSync(recursive: true)
              ..writeAsBytesSync(data);
          }
        }
        return true;
      }
      return false;
    } catch (e) {
      rethrow;
    }
  }
}
