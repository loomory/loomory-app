import 'package:flutter/material.dart';
import 'package:immich_mobile/extensions/build_context_extensions.dart';
import 'package:immich_mobile/presentation/widgets/timeline/segment.model.dart';

import 'insta_segment_viewer.dart';
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

  // Our "model" is quite different from the Immich one. In Immich each Asset is an individual photo,
  // while in our case, we do not render Assets here but Segments containing multiple Assets.
  // Due to this, we can have onTap detection, favorites etc here because this must be per Asset inside the Segment.
  @override
  Widget builder(BuildContext context, int index) {
    return Column(
      children: [
        // Tweak header layout later, takes up too much space now maybe do instagram style with small date under photo?
        TimelineHeader(bucket: bucket, header: header, height: headerExtent, assetOffset: firstAssetIndex),
        SizedBox(
          height: context.width,
          child: InstaSegmentViewer(
            // We must have unique keys here or bad things happen with the timeline, sluggish, crashing etc.
            // In contrast to the Immich timeline, one key represents a day/month, not an individual image
            key: UniqueKey(),
            initialIndex: firstAssetIndex,
            assetsInSegment: (lastIndex - firstAssetIndex) + 1,
          ),
        ),
      ],
    );
  }
}
