import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:immich_mobile/constants/constants.dart';
import 'package:immich_mobile/domain/models/asset/base_asset.model.dart';
import 'package:immich_mobile/infrastructure/repositories/local_asset.repository.dart';
import 'package:immich_mobile/platform/native_sync_api.g.dart';
import 'package:immich_mobile/providers/infrastructure/platform.provider.dart';
import 'package:logging/logging.dart';
import 'package:loomory/repositories/local_assets.dart';

// Immich only creates checksums (hashes) for albums selected for backup automatically. Since we do not
// select albums for backup, we do not have checksums for LocalAssets. This is needed when looking up
// remoteId for a localId that was directly added to an album.

final manualHashServiceProvider = Provider(
  (ref) => ManualHashService(
    localAssetRepository: ref.watch(localAssetRepository),
    nativeSyncApi: ref.watch(nativeSyncApiProvider),
  ),
);

class ManualHashService {
  final int _batchSize;
  final DriftLocalAssetRepository _localAssetRepository;
  final NativeSyncApi _nativeSyncApi;
  final bool Function()? _cancelChecker;
  final _log = Logger('HashService');

  ManualHashService({
    required DriftLocalAssetRepository localAssetRepository,
    required NativeSyncApi nativeSyncApi,
    bool Function()? cancelChecker,
    int? batchSize,
  }) : _localAssetRepository = localAssetRepository,
       _cancelChecker = cancelChecker,
       _nativeSyncApi = nativeSyncApi,
       _batchSize = batchSize ?? kBatchHashFileLimit;

  bool get isCancelled => _cancelChecker?.call() ?? false;

  /// Processes a list of [LocalAsset]s, storing their hash and updating the assets in the DB
  /// with hash for those that were successfully hashed. Hashes are looked up in a table
  /// [LocalAssetHashEntity] by local id. Only missing entries are newly hashed and added to the DB.
  Future<void> hashAssets(List<LocalAsset> assetsToHash) async {
    final toHash = <String, LocalAsset>{};

    for (final asset in assetsToHash) {
      if (isCancelled) {
        _log.warning("Hashing cancelled. Stopped processing assets.");
        return;
      }

      toHash[asset.id] = asset;
      if (toHash.length == _batchSize) {
        await _processBatch(toHash);
        toHash.clear();
      }
    }

    await _processBatch(toHash);
  }

  /// Processes a batch of assets.
  Future<void> _processBatch(Map<String, LocalAsset> toHash) async {
    if (toHash.isEmpty) {
      return;
    }

    _log.fine("Hashing ${toHash.length} files");

    final hashed = <String, String>{};
    final hashResults = await _nativeSyncApi.hashAssets(toHash.keys.toList(), allowNetworkAccess: true);
    assert(
      hashResults.length == toHash.length,
      "Hashes length does not match toHash length: ${hashResults.length} != ${toHash.length}",
    );

    for (int i = 0; i < hashResults.length; i++) {
      if (isCancelled) {
        _log.warning("Hashing cancelled. Stopped processing batch.");
        return;
      }

      final hashResult = hashResults[i];
      if (hashResult.hash != null) {
        hashed[hashResult.assetId] = hashResult.hash!;
      } else {
        final asset = toHash[hashResult.assetId];
        _log.warning(
          "Failed to hash asset with id: ${hashResult.assetId}, name: ${asset?.name}, createdAt: ${asset?.createdAt}, Error: ${hashResult.error ?? "unknown"}",
        );
      }
    }

    _log.fine("Hashed ${hashed.length}/${toHash.length} assets");

    await _localAssetRepository.updateHashes(hashed);
  }
}
