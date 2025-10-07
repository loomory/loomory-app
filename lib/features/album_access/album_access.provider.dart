import 'dart:async';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:immich_mobile/providers/infrastructure/album.provider.dart';
import 'package:immich_mobile/providers/user.provider.dart';
import 'package:logging/logging.dart';
import 'package:openapi/api.dart';

import '../../domain/album_access.dart';
import '../../repositories/album_access.dart';

// This is for the owner side of an album, to create invite links and handle approvals.
class AlbumAccessNotifier extends AsyncNotifier<List<AlbumAccess>> {
  final Logger _log = Logger('AlbumAccessNotifier');

  @override
  FutureOr<List<AlbumAccess>> build() async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser != null) {
      final albumAccessRequests = await ref.read(albumAccessRepository).get(currentUser.id);
      _log.info("Found ${albumAccessRequests.length} album access requests");
      return albumAccessRequests;
    }

    return [];
  }

  String createRequestAccessLink(String albumId, String albumName) {
    final currentUser = ref.read(currentUserProvider);
    final shareUri = Uri.parse(
      "https://loomory.app/dl/raa?user_id=${currentUser?.id}&album_id=$albumId&album_name=$albumName",
    );
    return shareUri.toString();
  }

  Future<bool> approveAlbumAccess(AlbumAccess aa) async {
    try {
      await ref.read(remoteAlbumProvider.notifier).addUsers(aa.albumId, [aa.requestorId]);
    } on ApiException catch (e) {
      _log.severe("Failed to add ${aa.requestorId} to ${aa.albumId} - Status: ${e.code}, Message: ${e.message}");

      if (e.code == 400) {
        _log.info(
          "User already added to album (HTTP 400). This should not happen but it is not a problem so continue.",
        );
      } else {
        return false;
      }
    } catch (e) {
      _log.severe("Failed to add ${aa.requestorId} to ${aa.albumId} - Unexpected error: ${e.toString()}");
      return false;
    }

    final res = await ref.read(albumAccessRepository).deleteAlbumAccessRequest(aa);
    switch (res) {
      case AlbumAccessRequestResult.success:
        _log.info("albumAccessRequest deleted ok");
      case AlbumAccessRequestResult.blocked:
        _log.warning("delete of album access request returned blocked, must never happen");
      case AlbumAccessRequestResult.error:
        _log.warning("failed to delete album access request");
    }
    state = AsyncValue.data(
      state.value
              ?.where(
                (request) =>
                    !(request.userId == aa.userId &&
                        request.requestorId == aa.requestorId &&
                        request.albumId == aa.albumId),
              )
              .toList() ??
          [],
    );
    return true;
  }

  Future<bool> blockAlbumAccessRequest(AlbumAccess aa) async {
    final res = await ref.read(albumAccessRepository).blockAlbumAccessRequest(aa);
    switch (res) {
      case AlbumAccessRequestResult.success:
        _log.info("albumAccessRequest blocked successfully");
        state = AsyncValue.data(
          state.value?.map((request) {
                if (request.userId == aa.userId &&
                    request.requestorId == aa.requestorId &&
                    request.albumId == aa.albumId) {
                  return AlbumAccess(
                    userId: request.userId,
                    albumId: request.albumId,
                    requestorId: request.requestorId,
                    requestorName: request.requestorName,
                    requestorMessage: request.requestorMessage,
                    blocked: true,
                  );
                }
                return request;
              }).toList() ??
              [],
        );
        return true;
      case AlbumAccessRequestResult.blocked:
        _log.warning("block album access request returned blocked, must never happen");
        return false;
      case AlbumAccessRequestResult.error:
        _log.warning("failed to block album access request");
        return false;
    }
  }
}

final albumAccessProvider = AsyncNotifierProvider<AlbumAccessNotifier, List<AlbumAccess>>(() {
  return AlbumAccessNotifier();
});

// Provider that filters albumAccessProvider to only include non-blocked album access requests
final nonBlockedAlbumAccessProvider = Provider<AsyncValue<List<AlbumAccess>>>((ref) {
  final albumAccessState = ref.watch(albumAccessProvider);

  return albumAccessState.when(
    data: (albumAccessList) {
      final nonBlocked = albumAccessList.where((access) => !access.blocked).toList();
      return AsyncValue.data(nonBlocked);
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stackTrace) => AsyncValue.error(error, stackTrace),
  );
});
