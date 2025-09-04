import 'package:immich_mobile/domain/models/timeline.model.dart';
import 'package:immich_mobile/presentation/widgets/timeline/segment.model.dart';
import 'package:immich_mobile/presentation/widgets/timeline/segment_builder.dart';

import 'select_segment.model.dart';

// Our custom builder for selecting photos since we want them laid out in a filled grid regardless
// of the date and the main timeline does not support groupBy.none.
class SelectSegmentBuilder extends SegmentBuilder {
  final double tileHeight;
  final int columnCount;

  const SelectSegmentBuilder({
    required super.buckets,
    required this.tileHeight,
    required this.columnCount,
    super.spacing,
    super.groupBy,
  });

  // We want them laid out in filled rows, regardless of the date in the bucket
  List<Segment> generate() {
    final segments = <Segment>[];

    // Calculate total asset count
    var totalAssetCount = 0;
    for (int i = 0; i < buckets.length; i++) {
      totalAssetCount += buckets[i].assetCount;
    }

    if (totalAssetCount == 0) {
      return segments;
    }

    final numberOfRows = (totalAssetCount / columnCount).ceil();
    final segmentCount = numberOfRows; // No header, so no +1

    final segmentStartOffset = 0.0;
    final segmentEndOffset = (tileHeight * numberOfRows) + spacing * (numberOfRows - 1);

    // Create a combined bucket with all assets
    final combinedBucket = Bucket(assetCount: totalAssetCount);

    segments.add(
      SelectSegment(
        firstIndex: 0,
        lastIndex: segmentCount - 1,
        startOffset: segmentStartOffset,
        endOffset: segmentEndOffset,
        firstAssetIndex: 0,
        bucket: combinedBucket,
        tileHeight: tileHeight,
        columnCount: columnCount,
        headerExtent: 0,
        spacing: spacing,
        header: HeaderType.none,
      ),
    );

    return segments;
  }
}
