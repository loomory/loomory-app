import 'dart:convert';

enum AlbumAccessRequestResult { success, blocked, error }

class AlbumAccess {
  final String userId;
  final String requestorId;
  final String albumId;

  AlbumAccess(this.userId, this.requestorId, this.albumId);

  AlbumAccess.fromJson(Map<String, dynamic> json)
    : userId = json["user_id"],
      requestorId = json['requestorId'],
      albumId = json['albumId'];

  String toJson() {
    final map = {'user_id': userId, 'requestor_id': requestorId, 'album_id': albumId};
    return jsonEncode(map);
  }
}
