import 'dart:io';
import 'package:digital_family_vault/features/settings/presentation/settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:digital_family_vault/features/family/domain/models/family_member.dart';
import 'package:digital_family_vault/core/storage/isar_provider.dart';
import 'package:digital_family_vault/features/family/data/family_repository.dart';
import 'package:digital_family_vault/core/constants/app_strings.dart';

class AddMemberScreen extends ConsumerStatefulWidget {
  final bool isAddingSelf;
  const AddMemberScreen({super.key, this.isAddingSelf = false});

  @override
  ConsumerState<AddMemberScreen> createState() => _AddMemberScreenState();
}

class _AddMemberScreenState extends ConsumerState<AddMemberScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String? _selectedRelation;
  File? _profileImage;

  @override
  void initState() {
    super.initState();
    if (widget.isAddingSelf) {
      _selectedRelation = 'Me';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    
    if (image != null) {
      setState(() {
        _profileImage = File(image.path);
      });
    }
  }

  Future<void> _saveMember() async {
    if (_formKey.currentState!.validate()) {
      final isar = await ref.read(isarProvider.future);
      final repository = FamilyRepository(isar);

      String? savedImagePath;
      if (_profileImage != null) {
        final appDir = await getApplicationDocumentsDirectory();
        final profilesDir = Directory(p.join(appDir.path, 'profiles'));
        if (!await profilesDir.exists()) {
          await profilesDir.create(recursive: true);
        }
        
        final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}${p.extension(_profileImage!.path)}';
        final savedFile = await _profileImage!.copy(p.join(profilesDir.path, fileName));
        savedImagePath = savedFile.path;
      }

      final member = FamilyMember()
        ..name = _nameController.text
        ..relation = _selectedRelation
        ..profileImagePath = savedImagePath
        ..createdAt = DateTime.now();

      await repository.addMember(member);

      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(settingsNotifierProvider).value?.language ?? 'bn';
    final theme = Theme.of(context);
    final relations = AppStrings.getRelations(lang);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.get('addMember', lang)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildImagePicker(theme),
              const SizedBox(height: 40),
              _buildNameField(lang, theme),
              const SizedBox(height: 24),
              _buildRelationDropdown(lang, theme, relations),
              const SizedBox(height: 40),
              _buildSaveButton(lang, theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePicker(ThemeData theme) {
    return Center(
      child: GestureDetector(
        onTap: _pickImage,
        child: Stack(
          children: [
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.secondaryContainer,
                border: Border.all(color: theme.colorScheme.primary.withOpacity(0.3), width: 3),
                image: _profileImage != null 
                    ? DecorationImage(image: FileImage(_profileImage!), fit: BoxFit.cover)
                    : null,
              ),
              child: _profileImage == null
                  ? Icon(Icons.person, size: 70, color: theme.colorScheme.primary.withOpacity(0.8))
                  : null,
            ),
            Positioned(
              bottom: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.primary,
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(1,1))]
                ),
                child: const Icon(Icons.add_a_photo, size: 22, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNameField(String lang, ThemeData theme) {
    return TextFormField(
      controller: _nameController,
      decoration: InputDecoration(
        labelText: AppStrings.get('fullName', lang),
        hintText: AppStrings.get('fullNameHint', lang),
        prefixIcon: const Icon(Icons.person_outline_rounded),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return AppStrings.get('nameValidation', lang);
        }
        return null;
      },
    );
  }

  Widget _buildRelationDropdown(String lang, ThemeData theme, List<String> relations) {
    return DropdownButtonFormField<String>(
      value: _selectedRelation,
      decoration: InputDecoration(
        labelText: AppStrings.get('relation', lang),
        prefixIcon: const Icon(Icons.people_alt_outlined),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      hint: Text(AppStrings.get('relationHint', lang)),
      items: relations.map((String relation) {
        return DropdownMenuItem<String>(
          value: relation,
          child: Text(relation),
        );
      }).toList(),
      onChanged: widget.isAddingSelf ? null : (String? newValue) {
        setState(() {
          _selectedRelation = newValue;
        });
      },
      validator: (value) {
        if (value == null) {
          return AppStrings.get('relationValidation', lang);
        }
        return null;
      },
    );
  }

  Widget _buildSaveButton(String lang, ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _saveMember,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(AppStrings.get('saveMember', lang), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
