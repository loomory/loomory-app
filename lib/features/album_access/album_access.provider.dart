import 'dart:async';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:immich_mobile/providers/user.provider.dart';
import 'package:logging/logging.dart';

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
      "loomory://album-access-request?user_id=${currentUser?.id}&album_id=$albumId&album_name=$albumName",
    );
    return shareUri.toString();
  }
}

final albumAccessProvider = AsyncNotifierProvider<AlbumAccessNotifier, List<AlbumAccess>>(() {
  return AlbumAccessNotifier();
});
