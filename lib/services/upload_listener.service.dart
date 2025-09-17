import 'dart:async';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:immich_mobile/providers/infrastructure/album.provider.dart';
import 'package:immich_mobile/providers/websocket.provider.dart';
import 'package:logging/logging.dart';

import '../repositories/local_assets.dart';

/// Represents a pending album addition operation, the checksum is our key for the localAsset that we need to assign
/// a remoteId when we have it.
class PendingAlbumAddition {
  final String checksum;
  final String albumId;
  final String albumName;
  final DateTime createdAt;
  final int retryCount;
  final String? originalFileName;

  const PendingAlbumAddition({
    required this.checksum,
    required this.albumId,
    required this.albumName,
    required this.createdAt,
    this.retryCount = 0,
    this.originalFileName,
  });

  PendingAlbumAddition copyWith({
    String? checksum,
    String? albumId,
    String? albumName,
    DateTime? createdAt,
    int? retryCount,
    String? originalFileName,
  }) {
    return PendingAlbumAddition(
      checksum: checksum ?? this.checksum,
      albumId: albumId ?? this.albumId,
      albumName: albumName ?? this.albumName,
      createdAt: createdAt ?? this.createdAt,
      retryCount: retryCount ?? this.retryCount,
      originalFileName: originalFileName ?? this.originalFileName,
    );
  }

  @override
  String toString() =>
      'PendingAlbumAddition: checksum: ${checksum.substring(0, 8)}, album: $albumName, retries: $retryCount)';
}

// After a websocket sync event the remoteId will be available and we match that with
// the checksum to know when we can add an image to an album.
class SyncedAsset {
  final String remoteId;
  final String checksum;

  SyncedAsset(this.remoteId, this.checksum);
}

/// Service that listens to upload success events from Immich websocket
/// and triggers album-specific addition of assets if needed.
class UploadListenerService {
  final Ref _ref;
  final _log = Logger('UploadListenerService');

  // State management for pending album additions
  final List<PendingAlbumAddition> _pendingAdditions = [];

  late Timer _t;
  UploadListenerService(this._ref);

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

  /// Remove a pending addition (if no longer needed)
  void removePendingAlbumAddition(String checksum, String albumId) {
    _pendingAdditions.removeWhere((p) => p.checksum == checksum && p.albumId == albumId);
    _log.info('Removed pending addition for checksum ${checksum.substring(0, 8)}... to album $albumId');
  }

  /// Clear old pending additions (older than specified duration)
  void cleanupOldPendingAdditions({Duration maxAge = const Duration(hours: 24)}) {
    final cutoff = DateTime.now().subtract(maxAge);
    final removed = _pendingAdditions.where((p) => p.createdAt.isBefore(cutoff)).toList();

    _pendingAdditions.removeWhere((p) => p.createdAt.isBefore(cutoff));

    if (removed.isNotEmpty) {
      _log.info('Cleaned up ${removed.length} old pending additions');
    }
  }

  void _tick() async {
    if (_pendingAdditions.isEmpty) {
      return;
    }

    // Map of albumId and list of assets we have found the remoteId for by now
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

        final checksums = readyToAdd[albumId]?.map((e) => e.checksum).toList() ?? [];
        for (final checksum in checksums) {
          removePendingAlbumAddition(checksum, albumId);
        }
      } catch (e) {
        final errorMsg = e.toString();
        _log.severe('Unexpected error adding asset assets to album $albumId: $errorMsg');
        rethrow;
      }
    }
  }

  void dispose() {
    _t.cancel();
  }
}

final uploadListenerServiceProvider = Provider<UploadListenerService>((ref) {
  final service = UploadListenerService(ref);

  // Add debug logging to track service lifecycle
  final log = Logger('UploadListenerProvider');
  log.info('Upload listener service created');

  ref.onDispose(() {
    log.info('Upload listener service disposing');
    service.dispose();
  });

  return service;
});
