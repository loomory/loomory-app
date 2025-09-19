import 'dart:async';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:immich_mobile/providers/infrastructure/album.provider.dart';
import 'package:logging/logging.dart';

import '../repositories/local_assets.dart';

// This service polls for updates of the upload status of a LocalAsset, meaning
// they have been assigned a remoteID and are now ready to be added to an Album.
// It is used by:
// 1. The companion album_ext.service which registers the pending event
// 2. The provider in the UI level listening to updates about the upload progress.
//    In particular for the case of an album only getting LocalAssets, we can assign the
//    thumbnailID for the first image ready to improve UX.

// Events that the service can emit to UI level Notifiers
abstract class UploadEvent {}

class AssetAddedToAlbumEvent extends UploadEvent {
  final String assetId;
  final String albumId;
  final String albumName;

  AssetAddedToAlbumEvent({required this.assetId, required this.albumId, required this.albumName});
}

class UploadProgressEvent extends UploadEvent {
  final int totalPending;

  UploadProgressEvent({required this.totalPending});
}

/// Represents a pending album addition operation, the checksum is our key for the localAsset
/// that we need to assign a remoteId when we have it.
class PendingAlbumAddition {
  final String checksum;
  final String albumId;
  final String albumName;
  final DateTime createdAt;
  final String? originalFileName;

  const PendingAlbumAddition({
    required this.checksum,
    required this.albumId,
    required this.albumName,
    required this.createdAt,
    this.originalFileName,
  });

  PendingAlbumAddition copyWith({
    String? checksum,
    String? albumId,
    String? albumName,
    DateTime? createdAt,
    String? originalFileName,
  }) {
    return PendingAlbumAddition(
      checksum: checksum ?? this.checksum,
      albumId: albumId ?? this.albumId,
      albumName: albumName ?? this.albumName,
      createdAt: createdAt ?? this.createdAt,
      originalFileName: originalFileName ?? this.originalFileName,
    );
  }

  @override
  String toString() => 'PendingAlbumAddition: checksum: ${checksum.substring(0, 8)}, album: $albumName)';
}

// After a sync update (triggered by a websocket event in Immich) the remoteId will be available
// and we match that with the checksum to know when we can add an image to an album.
class SyncedAsset {
  final String remoteId;
  final String checksum;

  SyncedAsset(this.remoteId, this.checksum);
}

/// Service that listens to upload success events from Immich websocket
/// and triggers album-specific addition of assets if needed.
class AlbumExtListenerService {
  final Ref _ref;
  final _log = Logger('UploadListenerService');

  // Stream controller for events
  final _eventController = StreamController<UploadEvent>.broadcast();
  Stream<UploadEvent> get events => _eventController.stream;

  // State management for pending album additions
  final List<PendingAlbumAddition> _pendingAdditions = [];

  late Timer _t;
  AlbumExtListenerService(this._ref);

  void start() {
    _t = Timer.periodic(Duration(seconds: 1), (_) {
      _tick();
    });
  }

  /// Add a pending album addition (before upload starts)
  /// This allows the service to queue the addition before the photo is actually uploaded
  void addPendingAlbumAddition({
    required String checksum,
    required String albumId,
    required String albumName,
    String? originalFileName,
  }) {
    // Check if already exists
    final existingIndex = _pendingAdditions.indexWhere((p) => p.checksum == checksum && p.albumId == albumId);

    if (existingIndex != -1) {
      _log.fine('Pending addition already exists for checksum $checksum to album $albumName');
      return;
    }

    final pending = PendingAlbumAddition(
      checksum: checksum,
      albumId: albumId,
      albumName: albumName,
      createdAt: DateTime.now(),
      originalFileName: originalFileName,
    );

    _pendingAdditions.add(pending);
    _log.info('Added pending album addition: $checksum -> $albumName');
  }

  /// Remove a pending addition, it has been successfully added.
  void removePendingAlbumAddition(String checksum, String albumId) {
    _pendingAdditions.removeWhere((p) => p.checksum == checksum && p.albumId == albumId);
    _log.info('Removed pending addition for checksum ${checksum.substring(0, 8)}... to album $albumId');
  }

  /// Clear old pending additions, in theory this should never happen
  void cleanupOldPendingAdditions({Duration maxAge = const Duration(hours: 24)}) {
    final cutoff = DateTime.now().subtract(maxAge);
    final removed = _pendingAdditions.where((p) => p.createdAt.isBefore(cutoff)).toList();

    _pendingAdditions.removeWhere((p) => p.createdAt.isBefore(cutoff));

    if (removed.isNotEmpty) {
      _log.warning('Cleaned up ${removed.length} old pending additions');
    }
  }

  void _tick() async {
    if (_pendingAdditions.isEmpty) {
      return;
    }

    // Map of albumId to list of assets we have found the remoteId for by now
    final readyToAdd = <String, List<SyncedAsset>>{};

    for (final pa in _pendingAdditions) {
      final localAssets = await _ref.read(localAssetRepository).getRemoteIdForAssetWithChecksum(pa.checksum);
      if (localAssets.isEmpty) {
        _log.info("${pa.checksum} for album ${pa.albumName} no synced yet");
        continue;
      } else if (localAssets.length > 1) {
        _log.warning("${pa.checksum} has ${localAssets.length} matches in local db");
      }
      final matchingAsset = localAssets.first;
      if (matchingAsset.remoteId == null) {
        _log.severe("${pa.checksum} in ${matchingAsset} has no remoteId");
        continue;
      }
      if (readyToAdd[pa.albumId] == null) {
        readyToAdd[pa.albumId] = [SyncedAsset(matchingAsset.remoteId!, pa.checksum)];
      } else {
        readyToAdd[pa.albumId]!.add(SyncedAsset(matchingAsset.remoteId!, pa.checksum));
      }
    }

    // We now have a map of albumIds with the remoteIds we can add to the album in this iteration
    for (final albumId in readyToAdd.keys) {
      try {
        final remoteIds = readyToAdd[albumId]?.map((e) => e.remoteId).toList() ?? [];
        final result = await _ref.read(remoteAlbumProvider.notifier).addAssets(albumId, remoteIds);
        if (result == 0) {
          // This could mean the asset is already in the album, which is actually success
          _log.warning('No assets added to $albumId, should not happen');
        }
        _log.info('Successfully added $result assets to album $albumId ($remoteIds)');

        // Emit events for each asset added
        final checksums = readyToAdd[albumId]?.map((e) => e.checksum).toList() ?? [];
        for (final checksum in checksums) {
          final pendingItem = _pendingAdditions.firstWhere((p) => p.checksum == checksum);
          final syncedAsset = readyToAdd[albumId]!.firstWhere((s) => s.checksum == checksum);

          _eventController.add(
            AssetAddedToAlbumEvent(assetId: syncedAsset.remoteId, albumId: albumId, albumName: pendingItem.albumName),
          );

          removePendingAlbumAddition(checksum, albumId);
        }

        // Emit progress event
        _eventController.add(UploadProgressEvent(totalPending: _pendingAdditions.length));
      } catch (e) {
        final errorMsg = e.toString();
        _log.severe('Unexpected error adding assets to album $albumId: $errorMsg');
        // Continue processing other albums
        continue;
      }
    }

    cleanupOldPendingAdditions();
  }

  void dispose() {
    _t.cancel();
    _eventController.close();
  }
}

final albumExtListenerServiceProvider = Provider<AlbumExtListenerService>((ref) {
  final service = AlbumExtListenerService(ref);

  // Add debug logging to track service lifecycle
  final log = Logger('AlbumExtProvider');
  log.info('Upload listener service created');

  ref.onDispose(() {
    log.info('Upload listener service disposing');
    service.dispose();
  });

  return service;
});
