import 'package:auto_route/auto_route.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:immich_mobile/domain/models/album/album.model.dart';
import 'package:immich_mobile/domain/models/asset/base_asset.model.dart';
import 'package:immich_mobile/domain/models/timeline.model.dart';
import 'package:immich_mobile/extensions/build_context_extensions.dart';
import 'package:immich_mobile/extensions/translate_extensions.dart';
import 'package:immich_mobile/providers/infrastructure/timeline.provider.dart';
import 'package:immich_mobile/providers/timeline/multiselect.provider.dart';

import '../../providers/album_ext.provider.dart';
import '../../repositories/local_assets.dart';
import '../../design_system/ds_select_timeline.dart';

// Adding photos to existing Album.
@RoutePage()
class AssetSelectionTimelinePage extends HookConsumerWidget {
  final Set<BaseAsset> lockedSelectionAssets;
  final RemoteAlbum album;
  const AssetSelectionTimelinePage({super.key, required this.album, this.lockedSelectionAssets = const {}});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allAssetsAsync = ref.watch(allAssetsProvider);

    return allAssetsAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stack) => Scaffold(body: Center(child: Text('Error loading assets: $error'))),
      data: (assets) => SafeArea(
        child: ProviderScope(
          key: ValueKey(assets.length), // Force timline recreation when asset count changes
          overrides: [
            multiSelectProvider.overrideWith(
              () => MultiSelectNotifier(
                MultiSelectState(selectedAssets: {}, forceEnable: true, lockedSelectionAssets: {}),
              ),
            ),
            // Use our local timeline that shows everything both remote and local assets
            timelineServiceProvider.overrideWith((ref) {
              final timelineService = ref.watch(timelineFactoryProvider).fromAssets(assets);
              ref.onDispose(timelineService.dispose);
              return timelineService;
            }),
          ],
          child: Consumer(
            builder: (context, ref, child) {
              ref.watch(multiSelectProvider); // React to selection changes so we can activate the Add button
              return CupertinoPageScaffold(
                navigationBar: CupertinoNavigationBar(
                  backgroundColor: context.scaffoldBackgroundColor,
                  middle: const Text('add_to_album').t(),
                  leading: CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: Icon(CupertinoIcons.back),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                  trailing: CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: ref.read(multiSelectProvider).selectedAssets.isNotEmpty
                        ? () {
                            final selectedAssets = ref.read(multiSelectProvider).selectedAssets;
                            ref.read(albumExtProvider.notifier).addToAlbum(album, selectedAssets);

                            context.pop();
                          }
                        : null,
                    child: Icon(CupertinoIcons.add),
                  ),
                ),
                child: DSTimeline(key: const Key("add-to-album"), groupBy: GroupAssetsBy.none, appBar: null),
              );
            },
          ),
        ),
      ),
    );
  }
}
