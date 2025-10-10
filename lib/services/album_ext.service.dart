import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:immich_mobile/domain/models/album/album.model.dart';
import 'package:immich_mobile/domain/models/asset/base_asset.model.dart';
import 'package:immich_mobile/providers/infrastructure/album.provider.dart';
import 'package:immich_mobile/providers/infrastructure/asset.provider.dart';
import 'package:immich_mobile/providers/infrastructure/current_album.provider.dart';
import 'package:immich_mobile/services/upload.service.dart';
import 'package:logging/logging.dart';
import 'album_ext_listener.service.dart';
import 'manual_hash.service.dart';

// This service offers album creation and addition with both local and remote assets.
// Immich only allows creating Albums using remote assets but we need to separate
// remote and localOnly images when creating or adding to an album since we allow
// the user to select images freely.
final albumExtServiceProvider = Provider((ref) => AlbumExtService(ref));

class AlbumExtService {
  final Ref _ref;
  final Logger _log = Logger('AlbumExtService');

  AlbumExtService(this._ref);

  // Remote assets are added instantly when the album is created (supported in the API call).
  // Local assets must be uploaded first, then our album_ext_listener.service polls for updates
  // for the new checksums and process pending assets album addition when the remoteId is set in
  // the local drift database.
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
          _log.severe("Error: can't process $asset unexpected or incorrect.");
        }
      } else {
        localOnlyAssets.add(asset as LocalAsset);
      }
    }
    return (remoteIds, localOnlyAssets);
  }

  // Backup the new Assets and queue them for addition to the album
  Future<void> addLocalOnlyAssets(RemoteAlbum album, List<LocalAsset> localOnlyAssets) async {
    _ref.read(currentRemoteAlbumProvider.notifier).setAlbum(album);

    // LocalAssets that already have checksums are fine. this could happen if we for instance
    // auto backup the favorites local album in the future.
    final updatedLocalAssets = localOnlyAssets.where((asset) => asset.checksum != null).toList();

    // Otherwise LocalAssets will not have checksums so we need to calculate them
    final localAssetsWithoutChecksum = localOnlyAssets.where((asset) => asset.checksum == null).toList();
    _log.info("hashing ${localAssetsWithoutChecksum.length} localAssets without checksum");
    await _ref.read(manualHashServiceProvider).hashAssets(localAssetsWithoutChecksum);

    // Now get the updated localAssets with the checksums just hashed
    for (final localAsset in localAssetsWithoutChecksum) {
      final updatedAsset = await _ref.read(assetServiceProvider).getAsset(localAsset) as LocalAsset?;
      if (updatedAsset != null) {
        updatedLocalAssets.add(updatedAsset);
      } else {
        _log.severe("Error: Failed to find updated local asset with checksum");
      }
    }

    // Upload local assets
    await _ref.read(uploadServiceProvider).manualBackup(updatedLocalAssets);

    // Queue local assets for album addition when their remoteIDs are available
    for (final localAsset in updatedLocalAssets) {
      _ref
          .read(albumExtListenerServiceProvider)
          .addPendingAlbumAddition(
            checksum: localAsset.checksum!,
            albumId: album.id,
            albumName: album.name,
            originalFileName: localAsset.name,
          );
    }
  }

  // Create new album and optionally provide the initial assets.
  // If there is at least one remote asset selected, it will instantly show as the cover
  // If there are only local assets selected, we need to upload them first, then
  // they are synced through the websocket notifications. The websocket
  // use debounsing so first update will be immediate and then at least 5 sec apart so
  // it will take time before all the assets are visible in the album.
  Future<void> createAlbum(String title, Set<BaseAsset> selectedAssets) async {
    final (remoteIds, localOnlyAssets) = splitRemoteLocal(selectedAssets);

    _log.info(
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
    _log.info(
      "addToAlbum #selectedAssets=${selectedAssets.length} #remoteIds=${remoteIds.length} #localAssets=${localOnlyAssets.length} #added=$added",
    );
  }
}
