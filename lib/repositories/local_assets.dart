import 'package:drift/drift.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:immich_mobile/domain/models/asset/base_asset.model.dart';
import 'package:immich_mobile/infrastructure/entities/local_asset.entity.dart';
import 'package:immich_mobile/infrastructure/repositories/db.repository.dart';
import 'package:immich_mobile/infrastructure/repositories/local_asset.repository.dart';
import 'package:immich_mobile/providers/infrastructure/db.provider.dart';

// All local assets, this includes the ones also synced to the server
final localAssetRepository = Provider<LocalAssetsRepository>((ref) => LocalAssetsRepository(ref.watch(driftProvider)));

// All assets
final allAssetsProvider = FutureProvider<List<BaseAsset>>((ref) async {
  final repository = ref.watch(localAssetRepository);
  final localAssets = await repository.getAllLocalAssets();
  return localAssets.cast<BaseAsset>();
});

class LocalAssetsRepository extends DriftLocalAssetRepository {
  final Drift _db;

  LocalAssetsRepository(this._db) : super(_db);

  Future<List<LocalAsset>> getAllLocalAssets() {
    final query = _db.localAssetEntity.select().addColumns([_db.remoteAssetEntity.id]).join([
      leftOuterJoin(
        _db.remoteAssetEntity,
        _db.localAssetEntity.checksum.equalsExp(_db.remoteAssetEntity.checksum),
        useColumns: false,
      ),
    ])..orderBy([OrderingTerm.desc(_db.localAssetEntity.createdAt)]);

    return query.map((row) {
      final asset = row.readTable(_db.localAssetEntity).toDto();
      return asset.copyWith(remoteId: row.read(_db.remoteAssetEntity.id));
    }).get();
  }

  Future<List<LocalAsset>> getLocalOnlyAssets() async {
    final allAssets = await getAllLocalAssets();
    return allAssets.where((asset) => asset.remoteId == null).toList();
  }
}
