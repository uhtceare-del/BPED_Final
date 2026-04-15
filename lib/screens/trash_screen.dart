import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/app_colors.dart';
import '../providers/auth_provider.dart';
import '../services/soft_delete_service.dart';
import '../widgets/dashboard_module.dart';

class TrashScreen extends ConsumerWidget {
  final String collection;

  const TrashScreen({super.key, required this.collection});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authUser = ref.watch(authStateProvider).value;
    if (authUser == null) {
      return DashboardEmptyState(
        icon: Icons.restore_from_trash_outlined,
        title: 'Trash unavailable',
        message: 'Sign in to view deleted records.',
      );
    }

    final softDeleteService = SoftDeleteService(
      firestore: ref.watch(firestoreProvider),
    );

    return StreamBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
      stream: softDeleteService.getTrash(collection),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: kNavy));
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final docs =
            snapshot.data ?? <QueryDocumentSnapshot<Map<String, dynamic>>>[];
        if (docs.isEmpty) {
          return DashboardEmptyState(
            icon: Icons.restore_from_trash_outlined,
            title: 'Trash is empty',
            message: 'No deleted $collection found.',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data();
            final title =
                (data['title'] ??
                        data['fullName'] ??
                        data['email'] ??
                        data['name'] ??
                        data['className'] ??
                        data['subject'] ??
                        'Untitled')
                    .toString();

            return Card(
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                title: Text(title),
                subtitle: Text('${collection.toUpperCase()} • ${doc.id}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.restore, color: kNavy),
                      onPressed: () async {
                        await softDeleteService.restore(collection, doc.id);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('$title restored.')),
                          );
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_forever, color: Colors.red),
                      onPressed: () async {
                        await softDeleteService.hardDelete(collection, doc.id);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('$title permanently deleted.'),
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
