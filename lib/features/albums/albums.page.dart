import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:immich_mobile/domain/models/timeline.model.dart';
import 'package:immich_mobile/domain/utils/event_stream.dart';
import 'package:immich_mobile/providers/asset_viewer/is_motion_video_playing.provider.dart';
import 'package:immich_mobile/providers/background_sync.provider.dart';
import 'package:immich_mobile/providers/infrastructure/album.provider.dart';
import 'package:immich_mobile/providers/infrastructure/current_album.provider.dart';
import 'package:immich_mobile/providers/infrastructure/timeline.provider.dart';
import 'package:loomory/features/common/asset_viewer.page.dart';

import '../../providers/album_ext.provider.dart';
import '../../routing/router.dart';
import 'widgets/album_selector.widget.dart';

@RoutePage()
class AlbumsPage extends ConsumerWidget {
  const AlbumsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(albumExtProvider);
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          await ref.read(backgroundSyncProvider).syncRemote();
          await ref.read(remoteAlbumProvider.notifier).refresh();
          // Not sure if this refresh does much, maybe we need to do the remoteSync if this is really needed here?
        },
        edgeOffset: 100,
        child: CustomScrollView(
          slivers: [
            AlbumSelector(
              onAlbumSelected: (album) async {
                ref.read(currentRemoteAlbumProvider.notifier).setAlbum(album);
                final timelineService = ref.read(timelineFactoryProvider).remoteAlbum(albumId: album.id);
                // This is more complex than the normal usage of timelineService which has a Timeline as a child
                // AssetViewer requires us to set the initial asset before pushing the route and this timelineService
                // init is async. Due to that, the complex logic below to wait for the timeline to init (thanks Claude).

                // Wait for the timeline service to initialize by listening to TimelineReloadEvent
                // or checking if totalAssets > 0 (which means buckets have loaded)
                final completer = Completer<void>();
                StreamSubscription? eventSubscription;

                // Check if already initialized
                if (timelineService.totalAssets > 0) {
                  completer.complete();
                } else {
                  // Listen for the reload event which indicates timeline is ready
                  eventSubscription = EventStream.shared.listen<TimelineReloadEvent>((event) {
                    if (timelineService.totalAssets > 0 && !completer.isCompleted) {
                      completer.complete();
                    }
                  });

                  // Also add a timeout to avoid hanging
                  Timer(const Duration(seconds: 2), () {
                    if (!completer.isCompleted) {
                      completer.completeError('Timeline initialization timeout');
                    }
                  });
                }

                try {
                  await completer.future;
                  eventSubscription?.cancel();

                  // Now we can safely load assets
                  final assets = await timelineService.loadAssets(0, 1);
                  if (assets.isEmpty) {
                    return; // No assets in album
                  }

                  ref.read(isPlayingMotionVideoProvider.notifier).playing = false;
                  AssetViewer.setAsset(ref, assets[0]);
                  context.pushRoute(AssetViewerRoute(initialIndex: 0, timelineService: timelineService));
                } catch (e) {
                  eventSubscription?.cancel();
                  // Handle error - timeline failed to initialize
                  debugPrint("Error: handling album timeline $e");
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
