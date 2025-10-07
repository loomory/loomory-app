import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:immich_mobile/providers/infrastructure/album.provider.dart';
import 'package:loomory/domain/album_access.dart';

import 'album_access.provider.dart';

// For the person who shared a link to approve or reject a request
@RoutePage()
class AlbumAccessPage extends ConsumerWidget {
  const AlbumAccessPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingApprovals = ref.watch(nonBlockedAlbumAccessProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pending requests'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
      ),
      body: pendingApprovals.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              
            ],
          ),
        ),
        data: (result) {
          if (result.isNotEmpty) {
            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: result.length,
              itemBuilder: (context, index) {
                final albumAccess = result[index];
                return _buildApprovalCard(context, ref, albumAccess);
              },
            );
          } else {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No pending access requests', style: TextStyle(fontSize: 18, color: Colors.grey)),
                ],
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildApprovalCard(BuildContext context, WidgetRef ref, AlbumAccess albumAccess) {
    final remoteAlbums = ref.watch(remoteAlbumProvider).albums;

    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Album: ${remoteAlbums.where((a) => a.id == albumAccess.albumId).firstOrNull?.name ?? ''}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 4),
                  Text('From: ${albumAccess.requestorName}', style: Theme.of(context).textTheme.bodyMedium),
                  if (albumAccess.requestorMessage != null)
                    Text('Message: ${albumAccess.requestorMessage}', style: Theme.of(context).textTheme.bodyMedium),
                  if (albumAccess.blocked) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.red.shade100, borderRadius: BorderRadius.circular(12)),
                      child: Text(
                        'Blocked',
                        style: TextStyle(color: Colors.red.shade800, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 16),
            if (!albumAccess.blocked) ...[
              _buildActionButton(
                context,
                ref,
                albumAccess,
                icon: Icons.check,
                color: Colors.green,
                onPressed: () => _approveAccess(context, ref, albumAccess),
              ),
              const SizedBox(width: 8),
              _buildActionButton(
                context,
                ref,
                albumAccess,
                icon: Icons.close,
                color: Colors.red,
                onPressed: () => _blockAccess(context, ref, albumAccess),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    WidgetRef ref,
    AlbumAccess albumAccess, {
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          child: Icon(icon, color: color, size: 24),
        ),
      ),
    );
  }

  Future<void> _approveAccess(BuildContext context, WidgetRef ref, AlbumAccess albumAccess) async {
    final success = await ref.read(albumAccessProvider.notifier).approveAlbumAccess(albumAccess);

    if (!success) {
      // Show error message if needed
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to approve access'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _blockAccess(BuildContext context, WidgetRef ref, AlbumAccess albumAccess) async {
    final success = await ref.read(albumAccessProvider.notifier).blockAlbumAccessRequest(albumAccess);

    if (!success) {
      // Show error message if needed
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to block access'), backgroundColor: Colors.red));
      }
    }
  }
}
