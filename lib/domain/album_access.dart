import 'dart:convert';

enum AlbumAccessRequestResult { success, blocked, error }

class AlbumAccess {
  final String userId;
  final String albumId;
  final String requestorId;
  final String requestorName;
  final String? requestorMessage;

  final bool blocked;

  AlbumAccess({
    required this.userId,
    required this.albumId,
    required this.requestorId,
    required this.requestorName,
    this.requestorMessage,
    this.blocked = false,
  });

  AlbumAccess.fromJson(Map<String, dynamic> json)
    : userId = json["user_id"],
      albumId = json['album_id'],
      requestorId = json['requestor_id'],
      requestorName = json['requestor_name'],
      requestorMessage = json['requestor_message'],
      blocked = json['blocked'] ?? false;

  String toJson() {
    final map = {
      'user_id': userId,
      'album_id': albumId,
      'requestor_id': requestorId,
      'requestor_name': requestorName,
      'requestor_message': requestorMessage,
      'blocked': blocked,
    };
    return jsonEncode(map);
  }
}
