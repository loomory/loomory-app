import 'package:flutter/material.dart';
import 'package:immich_mobile/extensions/build_context_extensions.dart';
import 'package:immich_mobile/presentation/widgets/timeline/segment.model.dart';

import 'insta_asset_viewer.dart';
// Unchanged so far but we might want to customize the segment header
import '../header.widget.dart';

class InstaSegment extends Segment {
  const InstaSegment({
    required super.firstIndex,
    required super.lastIndex,
    required super.startOffset,
    required super.endOffset,
    required super.firstAssetIndex,
    required super.bucket,
    required super.headerExtent,
    required super.spacing,
    required super.header,
  });

  @override
  double indexToLayoutOffset(int index) {
    return 0; // Not used in insta layout
  }

  @override
  int getMinChildIndexForScrollOffset(double scrollOffset) {
    return 0; // Not used in insta layout
  }

  @override
  int getMaxChildIndexForScrollOffset(double scrollOffset) {
    return 0; // Not used in insta layout
  }

  @override
  Widget builder(BuildContext context, int index) {
    // Tweak header layout later, takes up too much space now maybe do instagram style with small date under photo?
    return Column(
      children: [
        TimelineHeader(bucket: bucket, header: header, height: headerExtent, assetOffset: firstAssetIndex),

        SizedBox(
          height: context.width,
          child: InstaAssetViewer(
            key: UniqueKey(),
            initialIndex: firstAssetIndex,
            assetsInSegment: (lastIndex - firstAssetIndex) + 1,
          ),
        ),
      ],
    );
  }
}
