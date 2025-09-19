import 'dart:async';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:immich_mobile/domain/models/album/album.model.dart';
import 'package:immich_mobile/domain/models/asset/base_asset.model.dart';
import 'package:immich_mobile/providers/infrastructure/album.provider.dart';
import 'package:logging/logging.dart';

import '../services/album_ext.service.dart';
import '../services/album_ext_listener.service.dart';

class UploadListenerState {
  final int totalPending;

  const UploadListenerState({this.totalPending = 0});

  UploadListenerState copyWith({int? totalPending}) {
    return UploadListenerState(totalPending: totalPending ?? this.totalPending);
  }

  @override
  String toString() => 'ExtAlbumState(pending: $totalPending)';
}

class AlbumExtNotifier extends StateNotifier<UploadListenerState> {
  final Ref _ref;
  final Logger _log = Logger('AlbumExtNotifier');
  late final StreamSubscription<UploadEvent> _eventSubscription;

  AlbumExtNotifier(this._ref) : super(const UploadListenerState()) {
    _initializeEventListening();
    _ref.read(albumExtListenerServiceProvider).start();
  }

  void _initializeEventListening() {
    _eventSubscription = _ref.read(albumExtListenerServiceProvider).events.listen(_handleUploadEvent);
  }

  void _handleUploadEvent(UploadEvent event) async {
    switch (event) {
      case AssetAddedToAlbumEvent():
        _log.info('Asset ${event.assetId} added to album ${event.albumName}');

        final remoteAlbum = await _ref.read(remoteAlbumServiceProvider).get(event.albumId);
        if (remoteAlbum != null && remoteAlbum.thumbnailAssetId == null) {
          _log.info("First local asset uploaded to album without thumbnail");
          await _ref.read(remoteAlbumServiceProvider).updateAlbum(event.albumId, thumbnailAssetId: event.assetId);
          await _ref.read(remoteAlbumProvider.notifier).refresh();
        }
      case UploadProgressEvent():
        // Not used in the UI yet, would only be able to show how many uploads are left to process.
        _log.fine('Uploads pending: ${event.totalPending}');
        state = state.copyWith(totalPending: event.totalPending);
    }
  }

  Future<void> createAlbum(String title, Set<BaseAsset> selectedAssets) async {
    return _ref.read(albumExtServiceProvider).createAlbum(title, selectedAssets);
  }

  Future<void> addToAlbum(RemoteAlbum album, Set<BaseAsset> selectedAssets) {
    return _ref.read(albumExtServiceProvider).addToAlbum(album, selectedAssets);
  }

  @override
  void dispose() {
    _log.warning("Disposing AlbumExtNotifier, this should only happen on app shutdown");
    _eventSubscription.cancel();
    _ref.read(albumExtListenerServiceProvider).dispose();
    super.dispose();
  }
}

// Provider definition
final albumExtProvider = StateNotifierProvider<AlbumExtNotifier, UploadListenerState>((ref) {
  return AlbumExtNotifier(ref);
});
