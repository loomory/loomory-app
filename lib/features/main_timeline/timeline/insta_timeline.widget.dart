import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:immich_mobile/domain/models/setting.model.dart';
import 'package:immich_mobile/domain/models/timeline.model.dart';
import 'package:immich_mobile/domain/utils/event_stream.dart';
import 'package:immich_mobile/extensions/asyncvalue_extensions.dart';
import 'package:immich_mobile/extensions/build_context_extensions.dart';
import 'package:immich_mobile/presentation/widgets/action_buttons/download_status_floating_button.widget.dart';
import 'package:immich_mobile/presentation/widgets/bottom_sheet/general_bottom_sheet.widget.dart';
import 'segment/insta_segment_builder.dart';
import 'package:immich_mobile/presentation/widgets/timeline/segment.model.dart';
import 'package:immich_mobile/presentation/widgets/timeline/timeline.state.dart';
import 'package:immich_mobile/providers/infrastructure/setting.provider.dart';
import 'package:immich_mobile/providers/infrastructure/timeline.provider.dart';
import 'package:immich_mobile/providers/timeline/multiselect.provider.dart';
import 'package:immich_mobile/widgets/common/immich_sliver_app_bar.dart';

// This provider watches the buckets from the timeline service & args and serves the segments.
// It should be used only after the timeline service and timeline args provider is overridden
final timelineSegmentProvider = StreamProvider.autoDispose<List<Segment>>((ref) async* {
  final args = ref.watch(timelineArgsProvider);
  final spacing = args.spacing;
  final groupBy = args.groupBy ?? GroupAssetsBy.values[ref.watch(settingsProvider).get(Setting.groupAssetsBy)];

  final timelineService = ref.watch(timelineServiceProvider);
  yield* timelineService.watchBuckets().map((buckets) {
    return InstaSegmentBuilder(buckets: buckets, spacing: spacing, groupBy: groupBy).generate();
  });
}, dependencies: [timelineServiceProvider, timelineArgsProvider]);

class InstaTimeline extends StatelessWidget {
  const InstaTimeline({
    super.key,
    this.topSliverWidget,
    this.topSliverWidgetHeight,
    this.showStorageIndicator = false,
    this.withStack = false,
    this.appBar = const ImmichSliverAppBar(floating: true, pinned: false, snap: false),
    this.bottomSheet = const GeneralBottomSheet(minChildSize: 0.23),
    this.groupBy,
    this.withScrubber = true,
    this.snapToMonth = true,
  });

  final Widget? topSliverWidget;
  final double? topSliverWidgetHeight;
  final bool showStorageIndicator;
  final Widget? appBar;
  final Widget? bottomSheet;
  final bool withStack;
  final GroupAssetsBy? groupBy;
  final bool withScrubber;
  final bool snapToMonth;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      floatingActionButton: const DownloadStatusFloatingButton(),
      body: LayoutBuilder(
        builder: (_, constraints) => ProviderScope(
          overrides: [
            timelineArgsProvider.overrideWith(
              (ref) => TimelineArgs(
                maxWidth: constraints.maxWidth,
                maxHeight: constraints.maxHeight,
                columnCount: ref.watch(settingsProvider.select((s) => s.get(Setting.tilesPerRow))),
                showStorageIndicator: showStorageIndicator,
                withStack: withStack,
                groupBy: groupBy,
              ),
            ),
          ],
          child: _SliverTimeline(
            topSliverWidget: topSliverWidget,
            topSliverWidgetHeight: topSliverWidgetHeight,
            appBar: appBar,
            bottomSheet: bottomSheet,
            withScrubber: withScrubber,
          ),
        ),
      ),
    );
  }
}

class _SliverTimeline extends ConsumerStatefulWidget {
  const _SliverTimeline({
    this.topSliverWidget,
    this.topSliverWidgetHeight,
    this.appBar,
    this.bottomSheet,
    this.withScrubber = true,
  });

  final Widget? topSliverWidget;
  final double? topSliverWidgetHeight;
  final Widget? appBar;
  final Widget? bottomSheet;
  final bool withScrubber;

  @override
  ConsumerState createState() => _SliverTimelineState();
}

class _SliverTimelineState extends ConsumerState<_SliverTimeline> {
  final _scrollController = ScrollController();
  StreamSubscription? _eventSubscription;

  ScrollPhysics? _scrollPhysics;

  @override
  void initState() {
    super.initState();
    _eventSubscription = EventStream.shared.listen(_onEvent);
    ref.listenManual(multiSelectProvider.select((s) => s.isEnabled), _onMultiSelectionToggled);
  }

  void _onEvent(Event event) {
    switch (event) {
      case ScrollToTopEvent():
        _scrollController.animateTo(0, duration: const Duration(milliseconds: 250), curve: Curves.easeInOut);
      case ScrollToDateEvent scrollToDateEvent:
        _scrollToDate(scrollToDateEvent.date);
      case TimelineReloadEvent():
        setState(() {});
      default:
        break;
    }
  }

  void _onMultiSelectionToggled(_, bool isEnabled) {
    EventStream.shared.emit(MultiSelectToggleEvent(isEnabled));
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _eventSubscription?.cancel();
    super.dispose();
  }

  void _scrollToDate(DateTime date) {
    final asyncSegments = ref.read(timelineSegmentProvider);
    asyncSegments.whenData((segments) {
      // Find the segment that contains assets from the target date
      final targetSegment = segments.firstWhereOrNull((segment) {
        if (segment.bucket is TimeBucket) {
          final segmentDate = (segment.bucket as TimeBucket).date;
          // Check if the segment date matches the target date (year, month, day)
          return segmentDate.year == date.year && segmentDate.month == date.month && segmentDate.day == date.day;
        }
        return false;
      });

      // If exact date not found, try to find the closest month
      final fallbackSegment =
          targetSegment ??
          segments.firstWhereOrNull((segment) {
            if (segment.bucket is TimeBucket) {
              final segmentDate = (segment.bucket as TimeBucket).date;
              return segmentDate.year == date.year && segmentDate.month == date.month;
            }
            return false;
          });

      if (fallbackSegment != null) {
        // Scroll to the segment with a small offset to show the header
        final targetOffset = fallbackSegment.startOffset - 50;
        _scrollController.animateTo(
          targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext _) {
    final asyncSegments = ref.watch(timelineSegmentProvider);
    final maxHeight = ref.watch(timelineArgsProvider.select((args) => args.maxHeight));
    final isSelectionMode = ref.watch(multiSelectProvider.select((s) => s.forceEnable));
    final isMultiSelectEnabled = ref.watch(multiSelectProvider.select((s) => s.isEnabled));

    return PopScope(
      canPop: !isMultiSelectEnabled,
      onPopInvokedWithResult: (_, __) {
        if (isMultiSelectEnabled) {
          ref.read(multiSelectProvider.notifier).reset();
        }
      },
      child: asyncSegments.widgetWhen(
        onData: (segments) {
          //final childCount = (segments.lastOrNull?.lastIndex ?? -1) + 1;

          // For Instagram-style layout, use a regular ListView instead of SliverList
          final timeline = ListView.builder(
            physics: _scrollPhysics,
            cacheExtent: maxHeight * 2,
            itemCount: segments.length,
            itemBuilder: (final context, final index) {
              if (index >= segments.length) return null;
              //final segment = segments.findByIndex(index);
              // A segment in the insta list contains all the photos for a day or a month depending on groupBy
              final segment = segments[index];
              return segment.builder(context, 0);
            },
          );

          return PrimaryScrollController(
            controller: _scrollController,
            child: Stack(
              children: [
                timeline,
                if (!isSelectionMode && isMultiSelectEnabled) ...[
                  const Positioned(top: 60, left: 25, child: _MultiSelectStatusButton()),
                  if (widget.bottomSheet != null) widget.bottomSheet!,
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MultiSelectStatusButton extends ConsumerWidget {
  const _MultiSelectStatusButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectCount = ref.watch(multiSelectProvider.select((s) => s.selectedAssets.length));
    return ElevatedButton.icon(
      onPressed: () => ref.read(multiSelectProvider.notifier).reset(),
      icon: Icon(Icons.close_rounded, color: context.colorScheme.onPrimary),
      label: Text(
        selectCount.toString(),
        style: context.textTheme.titleMedium?.copyWith(height: 2.5, color: context.colorScheme.onPrimary),
      ),
    );
  }
}
