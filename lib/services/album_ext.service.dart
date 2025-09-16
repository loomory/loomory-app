import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:immich_mobile/domain/models/album/album.model.dart';
import 'package:immich_mobile/domain/models/asset/base_asset.model.dart';
import 'package:immich_mobile/providers/infrastructure/album.provider.dart';
import 'package:immich_mobile/providers/infrastructure/current_album.provider.dart';
import 'package:immich_mobile/services/upload.service.dart';
import '../services/upload_listener.service.dart';

// Our album creation is more complex than Immich. Immich only allows creating Albums using
// remote assets. So, for our needs, we need to separate remote and localOnly images when
// creating an album since we allow the user to select freely.
final albumExtServiceProvider = Provider((ref) => AlbumExtService(ref));

class AlbumExtService {
  final Ref _ref;

  AlbumExtService(this._ref);

  // Remote assets are added instantly when the album is created (supported in the API call).
  // Local assets must be uploaded first, then our upload_listener reacts to websocket events
  // from the server and has a list of assets pending album addition that is processed when
  // the server notifies us that new assets have been added.
  (List<String>, List<LocalAsset>) splitRemoteLocal(Set<BaseAsset> selectedAssets) {
    final remoteIds = <String>[];
    final localOnlyAssets = <LocalAsset>[];

    for (final asset in selectedAssets) {
      if (asset.hasRemote) {
        if (asset is LocalAsset && asset.remoteId != null) {
          remoteIds.add(asset.remoteId!);
        } else if (asset is RemoteAsset) {
          remoteIds.add(asset.id);
        } else {
          debugPrint("Error: can't process $asset unexpected or incorrect.");
        }
      } else {
        if (asset.checksum != null) {
          localOnlyAssets.add(asset as LocalAsset);
        } else {
          debugPrint("Error: can't process $asset");
        }
      }
    }
    return (remoteIds, localOnlyAssets);
  }

  // Backup the new Assets and queue them for addition to the album
  Future<void> addLocalOnlyAssets(RemoteAlbum album, List<LocalAsset> localOnlyAssets) async {
    _ref.read(currentRemoteAlbumProvider.notifier).setAlbum(album);

    // Upload local assets
    await _ref.read(uploadServiceProvider).manualBackup(localOnlyAssets);

    // Queue local assets for album addition when their remoteIDs are available
    for (final localAsset in localOnlyAssets) {
      _ref
          .read(uploadListenerServiceProvider)
          .addPendingAlbumAddition(checksum: localAsset.checksum!, albumId: album.id, albumName: album.name);
      debugPrint("queuing local image to ${album.name}");
    }
  }

  // Create new album and optionally provide the initial assets
  Future<void> createAlbum(String title, Set<BaseAsset> selectedAssets) async {
    final (remoteIds, localOnlyAssets) = splitRemoteLocal(selectedAssets);

    debugPrint(
      "Creating album: $title and adding ${remoteIds.length} remote images. Pending ${localOnlyAssets.length} local assets",
    );

    final album = await _ref.read(remoteAlbumProvider.notifier).createAlbum(title: title, assetIds: remoteIds);

    if (album != null) {
      addLocalOnlyAssets(album, localOnlyAssets);
    }
  }

  // Add assets to existing album
  Future<void> addToAlbum(RemoteAlbum album, Set<BaseAsset> selectedAssets) async {
    final (remoteIds, localOnlyAssets) = splitRemoteLocal(selectedAssets);
    final added = await _ref.read(remoteAlbumProvider.notifier).addAssets(album.id, remoteIds);

    addLocalOnlyAssets(album, localOnlyAssets);
    debugPrint(
      "addToAlbum #selectedAssets=${selectedAssets.length} #remoteIds=${remoteIds.length} #localAssets=${localOnlyAssets.length} #added=$added",
    );
  }
}
