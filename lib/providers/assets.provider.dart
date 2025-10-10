import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:immich_mobile/domain/models/asset/base_asset.model.dart';
import 'package:immich_mobile/providers/sync_status.provider.dart';
import 'package:flutter/foundation.dart';

import '../repositories/local_assets.dart';

// All assets provider that automatically refreshes on local sync completion
final allAssetsProvider = AsyncNotifierProvider<AllAssetsNotifier, List<BaseAsset>>(AllAssetsNotifier.new);

class AllAssetsNotifier extends AsyncNotifier<List<BaseAsset>> {
  @override
  Future<List<BaseAsset>> build() async {
    // Listen to sync status changes
    ref.listen<SyncStatusState>(syncStatusProvider, (previous, next) {
      if (previous?.localSyncStatus != next.localSyncStatus) {
        if (next.localSyncStatus == SyncStatus.success) {
          debugPrint("Local sync completed! Refreshing assets automatically");
          // Trigger a rebuild by setting state
          state = const AsyncValue.loading();
          _loadAssets();
        } else if (next.localSyncStatus == SyncStatus.error) {
          debugPrint("Local sync failed: ${next.errorMessage}");
        }
      }
    });

    return _loadAssets();
  }

  Future<List<BaseAsset>> _loadAssets() async {
    final repository = ref.watch(localAssetRepository);
    final localAssets = await repository.getAllLocalAssets();
    final result = localAssets.cast<BaseAsset>();
    state = AsyncValue.data(result);
    return result;
  }
}
