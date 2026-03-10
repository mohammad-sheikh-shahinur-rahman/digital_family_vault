import 'package:isar/isar.dart';

part 'family_member.g.dart';

@collection
class FamilyMember {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String name;

  String? relation;

  String? profileImagePath;

  DateTime? createdAt;
}
