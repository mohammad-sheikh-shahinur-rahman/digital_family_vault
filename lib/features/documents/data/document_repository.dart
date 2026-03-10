import 'dart:io';
import 'dart:typed_data';
import 'package:digital_family_vault/core/encryption/encryption_service.dart';
import 'package:digital_family_vault/features/documents/domain/models/document.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class DocumentRepository {
  final Isar isar;
  final EncryptionService _encryptionService = EncryptionService();

  DocumentRepository(this.isar);

  Future<List<AppDocument>> getDocumentsByMember(int memberId) async {
    return await isar.appDocuments.filter().memberIdEqualTo(memberId).findAll();
  }

  Future<void> saveDocument({
    required File sourceFile,
    required String title,
    required String category,
    required int memberId,
    DateTime? expiryDate,
    bool isEmergency = false,
    String? ocrText,
  }) async {
    final bytes = await sourceFile.readAsBytes();
    final encryptedBytes = await _encryptionService.encryptData(bytes);

    final appDir = await getApplicationDocumentsDirectory();
    final vaultDir = Directory(p.join(appDir.path, 'vault'));
    if (!await vaultDir.exists()) {
      await vaultDir.create(recursive: true);
    }

    final fileName = '${DateTime.now().millisecondsSinceEpoch}.enc';
    final savedFile = File(p.join(vaultDir.path, fileName));
    await savedFile.writeAsBytes(encryptedBytes);

    final doc = AppDocument()
      ..title = title
      ..category = category
      ..filePath = savedFile.path
      ..memberId = memberId
      ..expiryDate = expiryDate
      ..isEmergencyAccess = isEmergency
      ..createdAt = DateTime.now()
      ..ocrText = ocrText;

    await isar.writeTxn(() async {
      await isar.appDocuments.put(doc);
    });
  }

  Future<Uint8List> getDecryptedFile(String filePath) async {
    final file = File(filePath);
    final encryptedBytes = await file.readAsBytes();
    return await _encryptionService.decryptData(encryptedBytes);
  }

  Future<void> deleteDocument(AppDocument doc) async {
    await isar.writeTxn(() async {
      await isar.appDocuments.delete(doc.id);
    });
    
    final file = File(doc.filePath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<void> exportToPdf(AppDocument doc) async {
    final decryptedBytes = await getDecryptedFile(doc.filePath);
    final pdf = pw.Document();
    final image = pw.MemoryImage(decryptedBytes);

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Center(
            child: pw.Image(image),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: '${doc.title}.pdf',
    );
  }
}
