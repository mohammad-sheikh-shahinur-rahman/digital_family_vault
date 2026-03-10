import 'dart:io';
import 'package:digital_family_vault/core/storage/isar_provider.dart';
import 'package:digital_family_vault/features/documents/data/document_repository.dart';
import 'package:digital_family_vault/features/documents/domain/models/document.dart';
import 'package:digital_family_vault/features/family/domain/models/family_member.dart';
import 'package:digital_family_vault/features/scanner/presentation/camera_screen.dart';
import 'package:digital_family_vault/features/documents/presentation/add_document_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';

class MemberDocumentsScreen extends ConsumerWidget {
  final FamilyMember member;
  const MemberDocumentsScreen({super.key, required this.member});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isarAsync = ref.watch(isarProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('${member.name}\'s Vault'),
      ),
      body: isarAsync.when(
        data: (isar) {
          return StreamBuilder<List<AppDocument>>(
            stream: isar.appDocuments
                .filter()
                .memberIdEqualTo(member.id)
                .build()
                .watch(fireImmediately: true),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Container(
                    padding: const EdgeInsets.all(32.0),
                    constraints: const BoxConstraints(maxWidth: 350),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.shield_outlined,
                          size: 80,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Your Vault is Empty',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Tap the button below to scan and secure your first document.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Colors.grey[700],
                              ),
                        ),
                        const SizedBox(height: 32),
                        ElevatedButton.icon(
                          onPressed: () => _openCamera(context),
                          icon: const Icon(Icons.camera_alt_outlined),
                          label: const Text('Scan Document'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            foregroundColor: Theme.of(context).colorScheme.onPrimary,
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30.0),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final docs = snapshot.data!;
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: const Icon(Icons.insert_drive_file, color: Colors.deepPurple),
                      title: Text(doc.title),
                      subtitle: Text(doc.category),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (doc.isEmergencyAccess)
                            const Icon(Icons.emergency, color: Colors.red, size: 20),
                          const SizedBox(width: 8),
                          const Icon(Icons.chevron_right),
                        ],
                      ),
                      onTap: () => _viewDocument(context, ref, doc),
                    ),
                  );
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openCamera(context),
        child: const Icon(Icons.camera_alt),
      ),
    );
  }

  Future<void> _openCamera(BuildContext context) async {
    final File? imageFile = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CameraScreen()),
    );

    if (imageFile != null && context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AddDocumentScreen(
            imageFile: imageFile,
            member: member,
          ),
        ),
      );
    }
  }

  Future<void> _viewDocument(BuildContext context, WidgetRef ref, AppDocument doc) async {
    final isar = await ref.read(isarProvider.future);
    final repo = DocumentRepository(isar);
    
    try {
      final bytes = await repo.getDecryptedFile(doc.filePath);
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (_) => Dialog.fullscreen(
            child: Scaffold(
              appBar: AppBar(
                title: Text(doc.title),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.picture_as_pdf),
                    onPressed: () => repo.exportToPdf(doc),
                    tooltip: 'Export to PDF',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _confirmDelete(context, repo, doc),
                  )
                ],
              ),
              body: InteractiveViewer(
                child: Center(
                  child: Image.memory(bytes),
                ),
              ),
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error decrypting file: $e')),
        );
      }
    }
  }

  Future<void> _confirmDelete(BuildContext context, DocumentRepository repo, AppDocument doc) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Document?'),
        content: const Text('This will permanently remove this document from the vault.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await repo.deleteDocument(doc);
      if (context.mounted) Navigator.pop(context); // Close fullscreen dialog
    }
  }
}
