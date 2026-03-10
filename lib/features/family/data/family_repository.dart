import 'package:digital_family_vault/features/family/domain/models/family_member.dart';
import 'package:isar/isar.dart';

class FamilyRepository {
  final Isar isar;

  FamilyRepository(this.isar);

  Future<List<FamilyMember>> getAllMembers() async {
    return await isar.familyMembers.where().findAll();
  }

  Future<void> addMember(FamilyMember member) async {
    await isar.writeTxn(() async {
      await isar.familyMembers.put(member);
    });
  }

  Future<void> deleteMember(int id) async {
    await isar.writeTxn(() async {
      await isar.familyMembers.delete(id);
    });
  }
}
