import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:immich_mobile/extensions/build_context_extensions.dart';
import 'package:loomory/routing/router.dart';

enum AddOptions { createAlbum, joinAlbum, createEvent, addPhotos }

class DraggingHandle extends StatelessWidget {
  const DraggingHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 4,
      width: 35,
      decoration: BoxDecoration(
        color: context.themeData.dividerColor,
        borderRadius: const BorderRadius.all(Radius.circular(20)),
      ),
    );
  }
}

class AddOptionsBottomSheet extends ConsumerWidget {
  const AddOptionsBottomSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          const Align(alignment: Alignment.center, child: DraggingHandle()),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _AddOptionTile(
                  icon: Icons.photo_album_outlined,
                  title: 'create_album_title'.tr(),
                  description: 'create_album_description'.tr(),
                  backgroundColor: Colors.blue.withOpacity(0.1),
                  iconColor: Colors.blue,
                  onTap: () async {
                    await ref.context.pushRoute(const CreateAlbumRoute());
                    if (context.mounted) {
                      context.pop(AddOptions.createAlbum);
                    }
                  },
                ),
                const SizedBox(height: 16),
                _AddOptionTile(
                  icon: Icons.event_outlined,
                  title: 'create_event_title'.tr(),
                  description: 'create_event_description'.tr(),
                  backgroundColor: Colors.purple.withOpacity(0.1),
                  iconColor: Colors.purple,
                  onTap: () {
                    context.pop();
                    // TODO: Implement create event
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text('Create event - Coming soon!')));
                  },
                ),
                const SizedBox(height: 16),
                _AddOptionTile(
                  icon: Icons.add_photo_alternate_outlined,
                  title: 'add_photos_title'.tr(),
                  description: 'add_photos_description'.tr(),
                  backgroundColor: Colors.orange.withOpacity(0.1),
                  iconColor: Colors.orange,
                  onTap: () async {
                    context.pop();
                    await ref.context.pushRoute(const AddPhotosRoute());
                  },
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AddOptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color backgroundColor;
  final Color iconColor;
  final VoidCallback onTap;

  const _AddOptionTile({
    required this.icon,
    required this.title,
    required this.description,
    required this.backgroundColor,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.colorScheme.outline.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: backgroundColor, borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: context.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, size: 16, color: context.colorScheme.onSurface.withOpacity(0.5)),
            ],
          ),
        ),
      ),
    );
  }
}
