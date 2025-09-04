import 'package:immich_mobile/domain/models/timeline.model.dart';
import 'insta_segment.model.dart';
import 'package:immich_mobile/presentation/widgets/timeline/segment.model.dart';
import 'package:immich_mobile/presentation/widgets/timeline/segment_builder.dart';

// Our insta segments are very different from the main timeline segments in Immich.
// For us, each segment corresponds to a time bucket so it is simpler.
// We do not have to care about dimensions, column count etc.

class InstaSegmentBuilder extends SegmentBuilder {
  const InstaSegmentBuilder({required super.buckets, super.spacing, super.groupBy});

  List<Segment> generate() {
    final segments = <Segment>[];
    //int firstIndex = 0;
    int assetIndex = 0;
    DateTime? previousDate;
    for (int i = 0; i < buckets.length; i++) {
      final bucket = buckets[i];

      final timelineHeader = switch (groupBy) {
        GroupAssetsBy.month => HeaderType.month,
        GroupAssetsBy.day || GroupAssetsBy.auto =>
          bucket is TimeBucket && bucket.date.month != previousDate?.month ? HeaderType.monthAndDay : HeaderType.day,
        GroupAssetsBy.none => HeaderType.none,
      };
      final headerExtent = SegmentBuilder.headerExtent(timelineHeader);

      segments.add(
        InstaSegment(
          firstIndex: assetIndex,
          // Last index is the actual index of the last image, not the next one
          // So if the first segment has one image, firstIndex==lastIndex==0
          lastIndex: assetIndex + bucket.assetCount - 1,
          startOffset: 0, // Not needed with insta layout
          endOffset: 0, // Not needed with insta layout
          firstAssetIndex: assetIndex,
          bucket: bucket,
          headerExtent: headerExtent,
          spacing: spacing,
          header: timelineHeader,
        ),
      );

      assetIndex += bucket.assetCount;
      if (bucket is TimeBucket) {
        previousDate = bucket.date;
      }
    }
    return segments;
  }
}
