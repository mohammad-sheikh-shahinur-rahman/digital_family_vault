import 'package:digital_family_vault/core/storage/isar_provider.dart';
import 'package:digital_family_vault/features/documents/data/document_repository.dart';
import 'package:digital_family_vault/features/documents/domain/models/document.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:shimmer/shimmer.dart';

class EmergencyScreen extends ConsumerWidget {
  const EmergencyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isarAsync = ref.watch(isarProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.errorContainer.withOpacity(0.1),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: theme.colorScheme.error,
            foregroundColor: theme.colorScheme.onError,
            pinned: true,
            expandedHeight: 150,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Emergency Vault',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onError,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.error,
                      theme.colorScheme.error.withOpacity(0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: _buildWarningBanner(context, theme),
          ),
          isarAsync.when(
            data: (isar) => _buildDocumentList(isar, ref, theme),
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (err, stack) => SliverFillRemaining(
              child: Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarningBanner(BuildContext context, ThemeData theme) {
    return Container(
      color: theme.colorScheme.error,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_outline, color: theme.colorScheme.onError, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Read-Only: Editing is disabled for security.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: theme.colorScheme.onError,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentList(Isar isar, WidgetRef ref, ThemeData theme) {
    return StreamBuilder<List<AppDocument>>(
      stream: isar.appDocuments
          .filter()
          .isEmergencyAccessEqualTo(true)
          .watch(fireImmediately: true),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return _buildLoadingShimmer();
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SliverFillRemaining(child: _EmptyEmergencyState());
        }

        final docs = snapshot.data!;
        return SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList.separated(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              return _DocumentCard(
                doc: doc,
                theme: theme,
                onTap: () => _viewDocument(context, ref, doc),
              );
            },
            separatorBuilder: (context, index) => const SizedBox(height: 12),
          ),
        );
      },
    );
  }

  Widget _buildLoadingShimmer() {
    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverList(delegate: SliverChildBuilderDelegate((context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            height: 88, 
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        );
      }, childCount: 5,)),
    );
  }

  Future<void> _viewDocument(BuildContext context, WidgetRef ref, AppDocument doc) async {
    final isar = await ref.read(isarProvider.future);
    final repo = DocumentRepository(isar);
    
    try {
      final bytes = await repo.getDecryptedFile(doc.filePath);
      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => Scaffold(
              appBar: AppBar(
                title: Text(doc.title),
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
              ),
              backgroundColor: Colors.black,
              body: InteractiveViewer(
                panEnabled: false,
                boundaryMargin: const EdgeInsets.all(80),
                minScale: 0.5,
                maxScale: 4,
                child: Center(
                  child: Image.memory(bytes),
                ),
              ),
            ),
            fullscreenDialog: true,
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

class _EmptyEmergencyState extends StatelessWidget {
  const _EmptyEmergencyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.health_and_safety_outlined,
            size: 100,
            color: theme.colorScheme.error.withOpacity(0.7),
          ),
          const SizedBox(height: 24),
          Text(
            'No Emergency Documents',
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Mark vital documents (e.g., Medical Reports, Blood Group) with the emergency toggle in their details screen.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
            ),
          ),
        ],
      ),
    );
  }
}

class _DocumentCard extends StatelessWidget {
  final AppDocument doc;
  final ThemeData theme;
  final VoidCallback onTap;

  const _DocumentCard({required this.doc, required this.theme, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shadowColor: theme.colorScheme.error.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.error.withOpacity(0.5), width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        splashColor: theme.colorScheme.error.withOpacity(0.2),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          leading: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [Icon(Icons.verified_user_outlined, color: theme.colorScheme.error, size: 36)],
          ),
          title: Text(
            doc.title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
          ),
          subtitle: Text(
            doc.category,
            style: TextStyle(color: theme.textTheme.bodySmall?.color?.withOpacity(0.8)),
          ),
          trailing: Icon(
            Icons.arrow_forward_ios_rounded,
            color: theme.colorScheme.error,
          ),
        ),
      ),
    );
  }
}
