import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../domain/album_access.dart';

// Repository providing access to the album access request feature in Supabase
class AlbumAccessRepository {
  static const apiUrl = "https://fziocldhxscibxrfabho.supabase.co/functions/v1/album-requests";

  // johan_: 870d4688-bb08-415f-a2e4-3e09b8ba84a4
  Future<List<AlbumAccess>> get(String userID) async {
    final uri = Uri.parse('$apiUrl?user_id=$userID');

    final response = await http.get(uri);
    if (response.statusCode == 200) {
      try {
        final jsonData = jsonDecode(response.body);

        final data = jsonData['data'] as List;
        debugPrint("Data array extracted: $data");
        return data.map((e) => AlbumAccess.fromJson(e)).toList();
      } catch (e, stackTrace) {
        debugPrint("Error during JSON decoding: $e");
        debugPrint("Stack trace: $stackTrace");
        return [];
      }
    }
    return [];
  }

  Future<AlbumAccessRequestResult> requestAlbumAccess(AlbumAccess accessRequest) async {
    final body = accessRequest.toJson();
    final response = await http.post(Uri.parse(apiUrl), body: body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return AlbumAccessRequestResult.success;
    } else if (response.statusCode == 403) {
      return AlbumAccessRequestResult.blocked;
    } else {
      return AlbumAccessRequestResult.error;
    }
  }
}

final albumAccessRepository = Provider<AlbumAccessRepository>((ref) => AlbumAccessRepository());
