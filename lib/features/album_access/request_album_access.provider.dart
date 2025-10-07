import 'dart:async';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:immich_mobile/providers/user.provider.dart';
import 'package:logging/logging.dart';

import '../../domain/album_access.dart';
import '../../repositories/album_access.dart';

// This is for the requesting end, when a user has clicked on an album request link.
class RequestAlbumAccessNotifier extends AsyncNotifier<AlbumAccessRequestResult?> {
  final Logger _log = Logger('RequestAlbumAccessNotifier');

  @override
  FutureOr<AlbumAccessRequestResult?> build() async {
    return null;
  }

  void requestAlbumAccess(String ownerId, String albumId, String requestorName, String requestorMessage) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser != null) {
      state = AsyncValue.loading();
      final res = await ref
          .read(albumAccessRepository)
          .requestAlbumAccess(
            AlbumAccess(
              userId: ownerId,
              albumId: albumId,
              requestorId: currentUser.id,
              requestorName: requestorName,
              requestorMessage: requestorMessage,
            ),
          );
      switch (res) {
        case AlbumAccessRequestResult.success:
          state = AsyncValue.data(res);
        case AlbumAccessRequestResult.blocked:
          state = AsyncValue.data(res);
        case AlbumAccessRequestResult.error:
          state = AsyncValue.error(Object(), StackTrace.current);
      }
    } else {
      _log.severe("currentUser is null when requesting album access");
      state = AsyncValue.error(Object(), StackTrace.current);
    }
  }
}

final requestAlbumAccessProvider = AsyncNotifierProvider<RequestAlbumAccessNotifier, AlbumAccessRequestResult?>(() {
  return RequestAlbumAccessNotifier();
});
