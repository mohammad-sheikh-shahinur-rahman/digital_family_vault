import 'package:digital_family_vault/core/storage/isar_provider.dart';
import 'package:digital_family_vault/features/documents/data/document_repository.dart';
import 'package:digital_family_vault/features/documents/domain/models/document.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isarAsync = ref.watch(isarProvider);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search documents...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.grey),
          ),
          style: const TextStyle(fontSize: 18),
          onChanged: (value) {
            setState(() {
              _query = value;
            });
          },
        ),
      ),
      body: isarAsync.when(
        data: (isar) {
          if (_query.isEmpty) {
            return const Center(
              child: Text('Type to search by title or category'),
            );
          }

          return StreamBuilder<List<AppDocument>>(
            stream: isar.appDocuments
                .filter()
                .titleContains(_query, caseSensitive: false)
                .or()
                .categoryContains(_query, caseSensitive: false)
                .watch(fireImmediately: true),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('No matches found'));
              }

              final docs = snapshot.data!;
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.search),
                      title: Text(doc.title),
                      subtitle: Text(doc.category),
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
    );
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
              appBar: AppBar(title: Text(doc.title)),
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
          const SnackBar(content: Text('Could not open document')),
        );
      }
    }
  }
}
