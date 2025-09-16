import 'dart:async';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:immich_mobile/providers/infrastructure/album.provider.dart';
import 'package:immich_mobile/providers/websocket.provider.dart';
import 'package:logging/logging.dart';

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
  String toString() => 'PendingAlbumAddition(checksum: $checksum, album: $albumName, retries: $retryCount)';
}

/// Service that listens to upload success events from Immich websocket
/// and triggers album-specific addition of assets if needed.
class UploadListenerService {
  final Ref _ref;
  final _log = Logger('UploadListenerService');

  // State management for pending album additions
  final List<PendingAlbumAddition> _pendingAdditions = [];
  final Map<String, int> _successfulAdditions = {}; // albumId -> count
  final Map<String, int> _failedAdditions = {}; // albumId -> count

  // Connection state
  bool _shouldBeListening = false;
  bool _isCurrentlyListening = false;

  UploadListenerService(this._ref) {
    // Watch websocket connection state and auto-connect/disconnect listeners
    _ref.listen<WebsocketState>(websocketProvider, (previous, next) => _handleWebsocketStateChange(previous, next));
  }

  /// Start listening to websocket events (will connect when websocket is available)
  void startListening() {
    _shouldBeListening = true;
    _log.info('Upload listener enabled - will connect when websocket is available');
    _tryAttachListeners();
  }

  /// Stop listening to websocket events
  void stopListening() {
    _shouldBeListening = false;
    _detachListeners();
    _log.info('Upload listener disabled');
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
    _log.info(
      'Added pending album addition: $originalFileName -> $albumName (checksum: ${checksum.substring(0, 8)}...)',
    );
  }

  /// Remove a pending addition (if no longer needed)
  void removePendingAlbumAddition(String checksum, String albumId) {
    _pendingAdditions.removeWhere((p) => p.checksum == checksum && p.albumId == albumId);
    _log.info('Removed pending addition for checksum ${checksum.substring(0, 8)}... to album $albumId');
  }

  /// Get all pending additions (for debugging/UI)
  List<PendingAlbumAddition> get pendingAdditions => List.unmodifiable(_pendingAdditions);

  /// Get statistics
  Map<String, dynamic> get statistics => {
    'pending': _pendingAdditions.length,
    'successful': _successfulAdditions.values.fold(0, (a, b) => a + b),
    'failed': _failedAdditions.values.fold(0, (a, b) => a + b),
    'successByAlbum': Map.from(_successfulAdditions),
    'failedByAlbum': Map.from(_failedAdditions),
  };

  /// Clear old pending additions (older than specified duration)
  void cleanupOldPendingAdditions({Duration maxAge = const Duration(hours: 24)}) {
    final cutoff = DateTime.now().subtract(maxAge);
    final removed = _pendingAdditions.where((p) => p.createdAt.isBefore(cutoff)).toList();

    _pendingAdditions.removeWhere((p) => p.createdAt.isBefore(cutoff));

    if (removed.isNotEmpty) {
      _log.info('Cleaned up ${removed.length} old pending additions');
    }
  }

  /// Handle websocket connection state changes
  void _handleWebsocketStateChange(WebsocketState? previous, WebsocketState next) {
    _log.info('Websocket state changed: isConnected=${next.isConnected}, socket=${next.socket != null}');

    if (next.isConnected && next.socket != null && _shouldBeListening) {
      _tryAttachListeners();
    } else {
      _detachListeners();
    }
  }

  /// Try to attach listeners to the websocket
  void _tryAttachListeners() {
    if (_isCurrentlyListening || !_shouldBeListening) return;

    final websocketState = _ref.read(websocketProvider);
    final socket = websocketState.socket;

    if (socket != null && websocketState.isConnected) {
      socket.on('AssetUploadReadyV1', _handleAssetUploadReady);
      _isCurrentlyListening = true;
      _log.info('Successfully attached listeners to AssetUploadReadyV1 events (beta timeline)');
    } else {
      _log.fine('Websocket not ready yet - waiting for connection');
    }
  }

  /// Detach listeners from the websocket
  void _detachListeners() {
    if (!_isCurrentlyListening) return;

    final websocketState = _ref.read(websocketProvider);
    final socket = websocketState.socket;

    if (socket != null) {
      socket.off('AssetUploadReadyV1', _handleAssetUploadReady);
      _log.info('Detached listeners from AssetUploadReadyV1 events');
    }

    _isCurrentlyListening = false;
  }

  void _handleAssetUploadReady(dynamic data) {
    if (_pendingAdditions.isEmpty) {
      return;
    }

    try {
      // AssetUploadReadyV1 event structure: { asset: SyncAssetV1, exif: SyncAssetExifV1 }
      final assetData = data['asset'];
      if (assetData == null) {
        _log.warning('AssetUploadReadyV1 event missing asset data');
        return;
      }

      // Extract asset ID and checksum from SyncAssetV1
      final assetId = assetData['id'] as String?;
      final checksum = assetData['checksum'] as String?;

      if (assetId == null) {
        _log.warning('AssetUploadReadyV1 event missing asset ID');
        return;
      }

      if (checksum == null) {
        _log.warning('AssetUploadReadyV1 event missing checksum');
        return;
      }

      _log.info('Asset upload ready: $assetId (checksum: ${checksum.substring(0, 8)}...)');

      // Process pending album additions for this asset (async operation)
      _processPendingAdditions(assetId, checksum);
    } catch (e) {
      _log.severe('Error handling AssetUploadReadyV1 event', e);
    }
  }

  /// Process pending album additions for the uploaded asset
  Future<void> _processPendingAdditions(String assetId, String checksum) async {
    // Find all pending additions for this checksum
    final matchingPending = _pendingAdditions.where((p) => p.checksum == checksum).toList();

    if (matchingPending.isEmpty) {
      _log.fine('No pending additions for checksum ${checksum.substring(0, 8)}...');
      return;
    }

    _log.info('Processing ${matchingPending.length} pending additions for asset $assetId');

    for (final pending in matchingPending) {
      try {
        await _executeAlbumAddition(assetId, pending);

        // Track success
        _successfulAdditions[pending.albumId] = (_successfulAdditions[pending.albumId] ?? 0) + 1;

        // Remove from pending
        _pendingAdditions.remove(pending);

        _log.info('Successfully added asset $assetId to album ${pending.albumName}');
      } catch (e) {
        _log.severe('Failed to add asset $assetId to album ${pending.albumName}: $e');

        // Track failure
        _failedAdditions[pending.albumId] = (_failedAdditions[pending.albumId] ?? 0) + 1;

        // Retry logic - increase retry count
        final updatedPending = pending.copyWith(retryCount: pending.retryCount + 1);
        final index = _pendingAdditions.indexOf(pending);

        if (updatedPending.retryCount >= 3) {
          // Max retries reached, remove from pending
          _pendingAdditions.removeAt(index);
          _log.warning('Max retries reached for asset addition to ${pending.albumName}, giving up');
        } else {
          // Update with increased retry count
          _pendingAdditions[index] = updatedPending;
          _log.info('Will retry adding asset to ${pending.albumName} (attempt ${updatedPending.retryCount + 1}/3)');

          // Schedule retry after delay
          final retryDelay = Duration(milliseconds: 500 * updatedPending.retryCount); // Exponential backoff
          Future.delayed(retryDelay, () => _retryPendingAddition(assetId, updatedPending));
        }
      }
    }
  }

  /// Retry a pending addition after a delay
  Future<void> _retryPendingAddition(String assetId, PendingAlbumAddition pending) async {
    // Check if the pending addition still exists (might have been removed)
    final currentIndex = _pendingAdditions.indexWhere(
      (p) => p.checksum == pending.checksum && p.albumId == pending.albumId,
    );

    if (currentIndex == -1) {
      _log.fine('Pending addition no longer exists for retry: ${pending.albumName}');
      return;
    }

    final currentPending = _pendingAdditions[currentIndex];

    // Only retry if the retry count matches (prevents duplicate retries)
    if (currentPending.retryCount != pending.retryCount) {
      _log.fine('Retry count mismatch, skipping retry for ${pending.albumName}');
      return;
    }

    _log.info('Retrying asset addition: $assetId -> ${pending.albumName} (attempt ${pending.retryCount + 1}/3)');

    try {
      await _executeAlbumAddition(assetId, currentPending);

      // Track success
      _successfulAdditions[currentPending.albumId] = (_successfulAdditions[currentPending.albumId] ?? 0) + 1;

      // Remove from pending
      _pendingAdditions.removeAt(currentIndex);

      _log.info('Successfully added asset $assetId to album ${currentPending.albumName} on retry');
    } catch (e) {
      _log.severe('Retry failed for asset $assetId to album ${currentPending.albumName}: $e');

      // Track failure
      _failedAdditions[currentPending.albumId] = (_failedAdditions[currentPending.albumId] ?? 0) + 1;

      // Update retry count for next attempt
      final updatedPending = currentPending.copyWith(retryCount: currentPending.retryCount + 1);

      if (updatedPending.retryCount >= 3) {
        // Max retries reached, remove from pending
        _pendingAdditions.removeAt(currentIndex);
        _log.warning('Max retries reached for asset addition to ${currentPending.albumName}, giving up');
      } else {
        // Update with increased retry count and schedule next retry
        _pendingAdditions[currentIndex] = updatedPending;
        _log.info(
          'Will retry adding asset to ${currentPending.albumName} (attempt ${updatedPending.retryCount + 1}/3)',
        );

        // Schedule next retry with exponential backoff
        final retryDelay = Duration(milliseconds: 500 * updatedPending.retryCount);
        Future.delayed(retryDelay, () => _retryPendingAddition(assetId, updatedPending));
      }
    }
  }

  Future<void> _executeAlbumAddition(String assetId, PendingAlbumAddition pending) async {
    _log.info('Executing album addition: asset $assetId -> album ${pending.albumName}');

    // Simulate the addition (replace with real implementation)
    await Future.delayed(const Duration(milliseconds: 100));

    final result = await _ref.read(remoteAlbumProvider.notifier).addAssets(pending.albumId, [assetId]);
    if (result == 0) {
      throw Exception('No assets were added to album (asset may already exist)');
    }
  }

  /// Get current connection status
  bool get isConnected => _isCurrentlyListening;

  /// Get listener status
  bool get shouldBeListening => _shouldBeListening;

  void dispose() {
    stopListening();
    _pendingAdditions.clear();
    _successfulAdditions.clear();
    _failedAdditions.clear();
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
