import 'package:flutter/material.dart';
import 'package:immich_mobile/domain/models/album/album.model.dart';
import 'package:immich_mobile/presentation/widgets/images/thumbnail.widget.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class DSAlbumCard extends StatelessWidget {
  final RemoteAlbum album;
  final VoidCallback? onTap;
  final VoidCallback? onMenuTap;

  const DSAlbumCard({super.key, required this.album, this.onTap, this.onMenuTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(8),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Container(
                height: 200,
                width: double.infinity,
                child: Stack(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: double.infinity,
                      child: album.thumbnailAssetId != null
                          ? Thumbnail.remote(remoteId: album.thumbnailAssetId!)
                          : Container(
                              color: Colors.grey,
                              child: const Center(
                                child: Icon(Icons.photo_album_rounded, size: 100, color: Colors.white),
                              ),
                            ),
                    ),

                    // Top-right menu button
                    Positioned(
                      top: 16,
                      right: 16,
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2)),
                          ],
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.more_vert, color: Colors.black54, size: 20),
                          onPressed: onMenuTap,
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${album.name[0].toUpperCase()}${album.name.substring(1)}',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.black87),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${album.assetCount} photos',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (album.isShared) const Icon(FontAwesomeIcons.userGroup, color: Colors.black, size: 14),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
