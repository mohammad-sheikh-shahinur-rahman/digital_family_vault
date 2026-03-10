import 'dart:io';
import 'package:digital_family_vault/core/constants/app_strings.dart';
import 'package:digital_family_vault/core/notifications/notification_service.dart';
import 'package:digital_family_vault/core/storage/isar_provider.dart';
import 'package:digital_family_vault/core/scanner/ocr_service.dart';
import 'package:digital_family_vault/features/documents/data/document_repository.dart';
import 'package:digital_family_vault/features/documents/presentation/ocr_review_screen.dart';
import 'package:digital_family_vault/features/family/domain/models/family_member.dart';
import 'package:digital_family_vault/features/settings/presentation/settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class AddDocumentScreen extends ConsumerStatefulWidget {
  final File imageFile;
  final FamilyMember member;

  const AddDocumentScreen({
    super.key,
    required this.imageFile,
    required this.member,
  });

  @override
  ConsumerState<AddDocumentScreen> createState() => _AddDocumentScreenState();
}

class _AddDocumentScreenState extends ConsumerState<AddDocumentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  late final OCRService _ocrService;
  String? _selectedCategory;
  DateTime? _selectedExpiryDate;
  bool _isEmergency = false;
  bool _isSaving = false;
  bool _isScanningText = false;
  String? _ocrResultText;

  @override
  void initState() {
    super.initState();
    final lang = ref.read(settingsNotifierProvider).value?.language ?? 'en';
    _ocrService = OCRService(languageCode: lang);
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _runOCR(BuildContext context) async {
    setState(() => _isScanningText = true);
    try {
      final rawText = await _ocrService.recognizeText(widget.imageFile);

      if (rawText.trim().isEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No text recognized in the image.')),
        );
        return;
      }

      final correctedText = await Navigator.push<String>(
        context,
        MaterialPageRoute(
          builder: (_) => OCRReviewScreen(
            imageFile: widget.imageFile,
            recognizedText: rawText,
          ),
          fullscreenDialog: true,
        ),
      );

      if (correctedText != null && correctedText.isNotEmpty) {
        setState(() {
          _ocrResultText = correctedText;
        });
        _analyzeTextAndSuggestFields(correctedText);
      }
    } catch (e) {
      debugPrint('OCR Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An error occurred during text recognition: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isScanningText = false);
    }
  }

  void _analyzeTextAndSuggestFields(String text) {
    final lines = text.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
    if (lines.isEmpty) return;

    // 1. Title Suggestion (simple first line for now)
    _titleController.text = lines[0];

    final lang = ref.read(settingsNotifierProvider).value?.language ?? 'bn';
    final categories = AppStrings.getCategories(lang);

    // 2. Category Suggestion
    for (final line in lines) {
      final lowerLine = line.toLowerCase();
      if (lowerLine.contains('passport') || lowerLine.contains('nid')) {
        _selectedCategory = categories[0]; // NID / Passport
        break;
      } else if (lowerLine.contains('birth certificate')) {
        _selectedCategory = categories[1]; // Birth Certificate
        break;
      }
      // Add more category keyword checks here
    }

    // 3. Expiry Date Suggestion (Regex for DD/MM/YYYY, DD-MM-YYYY, etc.)
    final RegExp dateRegExp = RegExp(r'(\d{1,2}[/-]\d{1,2}[/-]\d{4})|(\d{4}[/-]\d{1,2}[/-]\d{1,2})');
    for (final line in lines) {
      final match = dateRegExp.firstMatch(line);
      if (match != null) {
        try {
          // Basic parsing, can be improved with intl
          String dateStr = match.group(0)!;
          DateTime parsedDate;
          if (dateStr.contains('/')) {
            final parts = dateStr.split('/');
            if (parts[2].length == 4) { // DD/MM/YYYY
              parsedDate = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
            } else { // YYYY/MM/DD
              parsedDate = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
            }
          } else {
             final parts = dateStr.split('-');
             if (parts[2].length == 4) { // DD-MM-YYYY
              parsedDate = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
            } else { // YYYY-MM-DD
              parsedDate = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
            }
          }

          if (parsedDate.isAfter(DateTime.now())) {
            _selectedExpiryDate = parsedDate;
            break;
          }
        } catch (e) {
          debugPrint("Date parsing error: $e");
        }
      }
    }

    setState(() {}); // Update UI with suggestions

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('We analyzed the text and filled in some fields for you!')),
    );
  }

  Future<void> _selectExpiryDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedExpiryDate ?? DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (picked != null && picked != _selectedExpiryDate) {
      setState(() {
        _selectedExpiryDate = picked;
      });
    }
  }

  Future<void> _saveDocument() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) return;

    setState(() => _isSaving = true);

    try {
      final isar = await ref.read(isarProvider.future);
      final repo = DocumentRepository(isar);

      await repo.saveDocument(
        sourceFile: widget.imageFile,
        title: _titleController.text,
        category: _selectedCategory!,
        memberId: widget.member.id,
        isEmergency: _isEmergency,
        expiryDate: _selectedExpiryDate,
        ocrText: _ocrResultText, // Save the corrected OCR text
      );

      if (_selectedExpiryDate != null) {
        await NotificationService().scheduleExpiryReminder(
          id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          title: 'Document Expiry Warning',
          body: '${_titleController.text} will expire soon!',
          scheduledDate: _selectedExpiryDate!,
        );
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save document: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

   @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsNotifierProvider).value;
    final lang = settings?.language ?? 'bn';
    final categories = AppStrings.getCategories(lang);
    final theme = Theme.of(context);
    
    if (_selectedCategory == null || !categories.contains(_selectedCategory)) {
      _selectedCategory = categories.first;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.get('addDocument', lang)),
        backgroundColor: theme.colorScheme.surfaceVariant,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100), // Added bottom padding for FAB
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildImagePreview(context, theme, lang),
              const SizedBox(height: 24),
              _buildTitleField(lang, theme),
              const SizedBox(height: 16),
              _buildCategoryDropdown(lang, theme, categories),
              const SizedBox(height: 16),
              _buildExpiryDateTile(lang, theme),
              const SizedBox(height: 16),
              _buildEmergencySwitch(lang, theme),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildSaveButton(lang, theme),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildImagePreview(BuildContext context, ThemeData theme, String lang) {
    return Stack(
      alignment: Alignment.center,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.file(
            widget.imageFile,
            height: 200,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.4),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        if (_isScanningText)
          const CircularProgressIndicator(color: Colors.white)
        else
          ElevatedButton.icon(
            onPressed: () => _runOCR(context),
            icon: const Icon(Icons.document_scanner_outlined, size: 26),
            label: Text(AppStrings.get('scanAndReview', lang)),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary.withOpacity(0.85),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTitleField(String lang, ThemeData theme) {
    return TextFormField(
      controller: _titleController,
      decoration: InputDecoration(
        labelText: AppStrings.get('documentTitle', lang),
        hintText: AppStrings.get('documentTitleHint', lang),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        prefixIcon: const Icon(Icons.title_rounded),
      ),
      validator: (value) =>
          value == null || value.trim().isEmpty ? AppStrings.get('titleValidation', lang) : null,
    );
  }

  Widget _buildCategoryDropdown(String lang, ThemeData theme, List<String> categories) {
    return DropdownButtonFormField<String>(
      value: _selectedCategory,
      decoration: InputDecoration(
        labelText: AppStrings.get('category', lang),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        prefixIcon: const Icon(Icons.category_rounded),
      ),
      items: categories.map((cat) {
        return DropdownMenuItem(value: cat, child: Text(cat));
      }).toList(),
      onChanged: (val) => setState(() => _selectedCategory = val!),
    );
  }

  Widget _buildExpiryDateTile(String lang, ThemeData theme) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      tileColor: theme.colorScheme.surfaceVariant.withOpacity(0.5),
      leading: const Icon(Icons.calendar_today_rounded, size: 32),
      title: Text(AppStrings.get('expiryDateOptional', lang), style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(_selectedExpiryDate == null
          ? AppStrings.get('noDateSelected', lang)
          : DateFormat('dd MMMM yyyy').format(_selectedExpiryDate!)),
      trailing: TextButton(
        onPressed: () => _selectExpiryDate(context),
        child: Text(AppStrings.get('select', lang)),
      ),
    );
  }

  Widget _buildEmergencySwitch(String lang, ThemeData theme) {
    return SwitchListTile.adaptive(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      tileColor: theme.colorScheme.errorContainer.withOpacity(0.2),
      title: Text(AppStrings.get('showInEmergency', lang), style: TextStyle(fontWeight: FontWeight.w600, color: theme.colorScheme.error)),
      subtitle: Text(AppStrings.get('emergencySubtitle', lang)),
      value: _isEmergency,
      onChanged: (val) => setState(() => _isEmergency = val),
      secondary: Icon(Icons.emergency_outlined, size: 32, color: theme.colorScheme.error),
    );
  }

  Widget _buildSaveButton(String lang, ThemeData theme) {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.9,
      child: FloatingActionButton.extended(
        onPressed: _isSaving ? null : _saveDocument,
        icon: _isSaving
            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Icon(Icons.lock_person_rounded),
        label: Text(AppStrings.get('encryptAndSave', lang)),
      ),
    );
  }
}
