import 'package:isar/isar.dart';

part 'document.g.dart';

@collection
class AppDocument {
  Id id = Isar.autoIncrement;

  late String title;
  
  @Index()
  late String category;

  late String filePath;

  String? notes;

  List<String>? tags;

  DateTime? expiryDate;

  bool isEmergencyAccess = false;

  int? memberId; // Link to FamilyMember.id

  DateTime? createdAt;

  String? ocrText;
}
