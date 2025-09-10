import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:immich_mobile/providers/infrastructure/album.provider.dart';
import 'package:immich_mobile/providers/infrastructure/current_album.provider.dart';

import '../../routing/router.dart';
import 'widgets/album_selector.widget.dart';

@RoutePage()
class AlbumsPage extends ConsumerStatefulWidget {
  const AlbumsPage({super.key});

  @override
  ConsumerState<AlbumsPage> createState() => _AlbumsPageState();
}

class _AlbumsPageState extends ConsumerState<AlbumsPage> {
  Future<void> onRefresh() async {
    await ref.read(remoteAlbumProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: onRefresh,
        edgeOffset: 100,
        child: CustomScrollView(
          slivers: [
            AlbumSelector(
              onAlbumSelected: (album) {
                ref.read(currentRemoteAlbumProvider.notifier).setAlbum(album);
                context.router.push(RemoteAlbumRoute(album: album));
              },
            ),
          ],
        ),
      ),
    );
  }
}
