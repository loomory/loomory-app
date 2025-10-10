import 'package:drift/drift.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:immich_mobile/domain/models/asset/base_asset.model.dart';
import 'package:immich_mobile/infrastructure/entities/local_asset.entity.dart';
import 'package:immich_mobile/infrastructure/repositories/db.repository.dart';
import 'package:immich_mobile/infrastructure/repositories/local_asset.repository.dart';
import 'package:immich_mobile/providers/infrastructure/db.provider.dart';

// Repository provider for local assets, a local asset for Loomory can be:
// 1. An asset added by the user, meaning it has a remote id and is visible in the timeline
// 2. An asset that is just available on the device but not added to Loomory.
// We need this to be able to pick from all possible photos everywhere, not only ones added by the user.
final localAssetRepository = Provider<LocalAssetsRepository>((ref) => LocalAssetsRepository(ref.watch(driftProvider)));

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

  Future<List<LocalAsset>> getRemoteIdForAssetWithChecksum(String checksum) async {
    final query =
        _db.localAssetEntity.select().addColumns([_db.remoteAssetEntity.id]).join([
            leftOuterJoin(
              _db.remoteAssetEntity,
              _db.localAssetEntity.checksum.equalsExp(_db.remoteAssetEntity.checksum),
              useColumns: false,
            ),
          ])
          ..where(_db.localAssetEntity.checksum.equals(checksum) & _db.remoteAssetEntity.id.isNotNull())
          ..orderBy([OrderingTerm.desc(_db.localAssetEntity.createdAt)]);

    return query.map((row) {
      final asset = row.readTable(_db.localAssetEntity).toDto();
      return asset.copyWith(remoteId: row.read(_db.remoteAssetEntity.id));
    }).get();
  }
}
