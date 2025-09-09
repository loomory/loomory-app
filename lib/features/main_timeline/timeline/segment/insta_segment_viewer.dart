import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:immich_mobile/domain/models/asset/base_asset.model.dart';
import 'package:immich_mobile/domain/models/timeline.model.dart';
import 'package:immich_mobile/domain/utils/event_stream.dart';
import 'package:immich_mobile/extensions/build_context_extensions.dart';
import 'package:immich_mobile/extensions/scroll_extensions.dart';
import 'package:immich_mobile/presentation/widgets/asset_viewer/asset_stack.provider.dart';
import 'package:immich_mobile/presentation/widgets/asset_viewer/asset_viewer.state.dart';
import 'package:immich_mobile/presentation/widgets/asset_viewer/video_viewer.widget.dart';
import 'package:immich_mobile/presentation/widgets/images/image_provider.dart';
import 'package:immich_mobile/presentation/widgets/images/thumbnail.widget.dart';
import 'package:immich_mobile/providers/asset_viewer/is_motion_video_playing.provider.dart';
import 'package:immich_mobile/providers/asset_viewer/video_player_controls_provider.dart';
import 'package:immich_mobile/providers/asset_viewer/video_player_value_provider.dart';
import 'package:immich_mobile/providers/cast.provider.dart';
import 'package:immich_mobile/providers/infrastructure/asset_viewer/current_asset.provider.dart';
import 'package:immich_mobile/providers/infrastructure/timeline.provider.dart';
import 'package:immich_mobile/widgets/common/immich_loading_indicator.dart';
import 'package:immich_mobile/widgets/photo_view/photo_view.dart';
import 'package:immich_mobile/widgets/photo_view/photo_view_gallery.dart';
import 'package:platform/platform.dart';

// Our Instagram like SegmentViewer. A Segment in this layout is a day or a month depending on groupBy.
// Each Segment contains one or more Assets that we can scroll horizontally within the Segment.
class InstaSegmentViewer extends ConsumerStatefulWidget {
  final int initialIndex;
  final int assetsInSegment;
  final Platform? platform;
  final int? heroOffset;

  const InstaSegmentViewer({
    super.key,
    required this.initialIndex,
    required this.assetsInSegment,
    this.platform,
    this.heroOffset,
  });

  @override
  ConsumerState createState() => _SegmentViewerState();
}

class _SegmentViewerState extends ConsumerState<InstaSegmentViewer> {
  static final _dummyListener = ImageStreamListener((image, _) => image.dispose());
  late PageController pageController;
  // PhotoViewGallery takes care of disposing it's controllers
  PhotoViewControllerBase? viewController;
  StreamSubscription? reloadSubscription;

  late Platform platform;
  late final int heroOffset;
  late PhotoViewControllerValue initialPhotoViewState;
  bool? hasDraggedDown;
  bool isSnapping = false;
  bool blockGestures = false;
  bool assetReloadRequested = false;
  double? initialScale;
  int totalAssets = 0;
  int stackIndex = 0;
  BuildContext? scaffoldContext;
  Map<String, GlobalKey> videoPlayerKeys = {};

  // Delayed operations that should be cancelled on disposal
  final List<Timer> _delayedOperations = [];

  ImageStream? _prevPreCacheStream;
  ImageStream? _nextPreCacheStream;

  @override
  void initState() {
    super.initState();
    pageController = PageController(initialPage: 0);
    platform = widget.platform ?? const LocalPlatform();
    totalAssets = widget.assetsInSegment;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _onAssetChanged(0);
    });
    reloadSubscription = EventStream.shared.listen(_onEvent);
    heroOffset = widget.heroOffset ?? TabsRouterScope.of(context)?.controller.activeIndex ?? 0;
  }

  @override
  void dispose() {
    pageController.dispose();
    _cancelTimers();
    reloadSubscription?.cancel();
    _prevPreCacheStream?.removeListener(_dummyListener);
    _nextPreCacheStream?.removeListener(_dummyListener);
    super.dispose();
  }

  Color get backgroundColor {
    final opacity = ref.read(assetViewerProvider.select((s) => s.backgroundOpacity));
    return Colors.black.withAlpha(opacity);
  }

  void _cancelTimers() {
    for (final timer in _delayedOperations) {
      timer.cancel();
    }
    _delayedOperations.clear();
  }

  ImageStream _precacheImage(BaseAsset asset) {
    final provider = getFullImageProvider(asset, size: context.sizeData);
    return provider.resolve(ImageConfiguration.empty)..addListener(_dummyListener);
  }

  // The relativeIndex is the page number in the horizontal page controller, it always starts at 0
  // To get the actual Immich index, we need widget.initialIndex (the first index in this groupBy) + relativeIndex (page number)
  void _onAssetChanged(int relativeIndex) async {
    // Validate index bounds and try to get asset, loading buffer if needed
    final timelineService = ref.read(timelineServiceProvider);
    final absoluteIndex = widget.initialIndex + relativeIndex;
    final asset = await timelineService.getAssetAsync(absoluteIndex);

    if (asset == null) {
      return;
    }

    // Always holds the current asset from the timeline
    ref.read(assetViewerProvider.notifier).setAsset(asset);
    // The currentAssetNotifier actually holds the current asset that is displayed
    // which could be stack children as well
    ref.read(currentAssetNotifier.notifier).setAsset(asset);
    if (asset.isVideo || asset.isMotionPhoto) {
      ref.read(videoPlaybackValueProvider.notifier).reset();
      ref.read(videoPlayerControlsProvider.notifier).pause();
    }

    unawaited(ref.read(timelineServiceProvider).preCacheAssets(absoluteIndex));
    _cancelTimers();
    // This will trigger the pre-caching of adjacent assets ensuring
    // that they are ready when the user navigates to them.
    final timer = Timer(Durations.medium4, () async {
      // Check if widget is still mounted before proceeding
      if (!mounted) return;

      final (prevAsset, nextAsset) = await (
        timelineService.getAssetAsync(absoluteIndex - 1),
        timelineService.getAssetAsync(absoluteIndex + 1),
      ).wait;
      if (!mounted) return;
      _prevPreCacheStream?.removeListener(_dummyListener);
      _nextPreCacheStream?.removeListener(_dummyListener);
      _prevPreCacheStream = prevAsset != null ? _precacheImage(prevAsset) : null;
      _nextPreCacheStream = nextAsset != null ? _precacheImage(nextAsset) : null;
    });
    _delayedOperations.add(timer);

    _handleCasting(asset);
  }

  void _handleCasting(BaseAsset asset) {
    if (!ref.read(castProvider).isCasting) return;

    // hide any casting snackbars if they exist
    context.scaffoldMessenger.hideCurrentSnackBar();

    // send image to casting if the server has it
    if (asset.hasRemote) {
      final remoteAsset = asset as RemoteAsset;

      ref.read(castProvider.notifier).loadMedia(remoteAsset, false);
    } else {
      // casting cannot show local assets
      context.scaffoldMessenger.clearSnackBars();

      if (ref.read(castProvider).isCasting) {
        ref.read(castProvider.notifier).stop();
        context.scaffoldMessenger.showSnackBar(
          SnackBar(
            duration: const Duration(seconds: 2),
            content: Text(
              "local_asset_cast_failed".tr(),
              style: context.textTheme.bodyLarge?.copyWith(color: context.primaryColor),
            ),
          ),
        );
      }
    }
  }

  void _onPageBuild(PhotoViewControllerBase controller) {
    viewController ??= controller;
  }

  void _onPageChanged(int index, PhotoViewControllerBase? controller) {
    _onAssetChanged(index);
    viewController = controller;
  }

  void _onTapDown(_, __, ___) {
    ref.read(assetViewerProvider.notifier).toggleControls();
  }

  void _onEvent(Event event) {
    if (event is TimelineReloadEvent) {
      _onTimelineReloadEvent();
      return;
    }

    if (event is ViewerReloadAssetEvent) {
      assetReloadRequested = true;
      return;
    }
  }

  void _onTimelineReloadEvent() {
    totalAssets = widget.assetsInSegment;
    if (totalAssets == 0) {
      context.maybePop();
      return;
    }

    if (assetReloadRequested) {
      assetReloadRequested = false;
      _onAssetReloadEvent();
      return;
    }
  }

  void _onAssetReloadEvent() async {
    final relativeIndex = pageController.page?.round() ?? 0;
    final timelineService = ref.read(timelineServiceProvider);
    final absoluteIndex = widget.initialIndex + relativeIndex;
    final newAsset = await timelineService.getAssetAsync(absoluteIndex);

    if (newAsset == null) {
      return;
    }

    final currentAsset = ref.read(currentAssetNotifier);
    // Do not reload / close the bottom sheet if the asset has not changed
    if (newAsset.heroTag == currentAsset?.heroTag) {
      return;
    }

    setState(() {
      _onAssetChanged(pageController.page!.round());
    });
  }

  Widget _placeholderBuilder(BuildContext ctx, ImageChunkEvent? progress, int index) {
    return const Center(child: ImmichLoadingIndicator());
  }

  void _onScaleStateChanged(PhotoViewScaleState scaleState) {
    if (scaleState != PhotoViewScaleState.initial) {
      ref.read(videoPlayerControlsProvider.notifier).pause();
    }
  }

  void _onLongPress(_, __, ___) {
    ref.read(isPlayingMotionVideoProvider.notifier).playing = true;
  }

  PhotoViewGalleryPageOptions _assetBuilder(BuildContext ctx, int relativeIndex) {
    scaffoldContext ??= ctx;
    final timelineService = ref.read(timelineServiceProvider);
    final absoluteIndex = widget.initialIndex + relativeIndex;
    final asset = timelineService.getAssetSafe(absoluteIndex);

    // If asset is not available in buffer, return a placeholder
    if (asset == null) {
      return PhotoViewGalleryPageOptions.customChild(
        heroAttributes: PhotoViewHeroAttributes(tag: 'loading_$absoluteIndex'),
        child: Container(
          width: ctx.width,
          height: ctx.height,
          color: backgroundColor,
          child: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    // Here we have the Asset so we know if it is a photo/video/favourite
    BaseAsset displayAsset = asset;
    final stackChildren = ref.read(stackChildrenNotifier(asset)).valueOrNull;
    if (stackChildren != null && stackChildren.isNotEmpty) {
      displayAsset = stackChildren.elementAt(ref.read(assetViewerProvider.select((s) => s.stackIndex)));
    }

    return _imageBuilder(ctx, displayAsset);
    // For now, like Apple, don't show moving video automatically in the timeline,
    // you must tap the placeholder image to start the video.
    // This hides the issue with Immich video_viewer.widget autostarting videos.
    //return _imageBuilder(ctx, displayAsset);
    final isPlayingMotionVideo = ref.read(isPlayingMotionVideoProvider);
    if (displayAsset.isImage && !isPlayingMotionVideo) {
      return _imageBuilder(ctx, displayAsset);
    }

    return _videoBuilder(ctx, displayAsset);
  }

  PhotoViewGalleryPageOptions _imageBuilder(BuildContext ctx, BaseAsset asset) {
    final size = ctx.sizeData;
    return PhotoViewGalleryPageOptions(
      key: ValueKey(asset.heroTag),
      //disableScaleGestures: true,
      imageProvider: getFullImageProvider(asset, size: size),
      heroAttributes: PhotoViewHeroAttributes(tag: '${asset.heroTag}_$heroOffset'),
      filterQuality: FilterQuality.high,
      tightMode: true,
      onTapDown: _onTapDown,
      onLongPressStart: asset.isMotionPhoto ? _onLongPress : null,
      errorBuilder: (_, __, ___) => Container(
        width: size.width,
        height: size.height,
        color: backgroundColor,
        child: Thumbnail.fromAsset(asset: asset, fit: BoxFit.contain),
      ),
    );
  }

  GlobalKey _getVideoPlayerKey(String id) {
    videoPlayerKeys.putIfAbsent(id, () => GlobalKey());
    return videoPlayerKeys[id]!;
  }

  PhotoViewGalleryPageOptions _videoBuilder(BuildContext ctx, BaseAsset asset) {
    return PhotoViewGalleryPageOptions.customChild(
      onTapDown: _onTapDown,
      heroAttributes: PhotoViewHeroAttributes(tag: '${asset.heroTag}_$heroOffset'),
      filterQuality: FilterQuality.high,
      maxScale: 1.0,
      basePosition: Alignment.center,
      child: SizedBox(
        width: ctx.width,
        height: ctx.height,
        child: NativeVideoViewer(
          key: _getVideoPlayerKey(asset.heroTag),
          asset: asset,
          image: Image(
            key: ValueKey(asset),
            image: getFullImageProvider(asset, size: ctx.sizeData),
            fit: BoxFit.contain,
            height: ctx.height,
            width: ctx.width,
            alignment: Alignment.center,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Rebuild the widget when the asset viewer state changes
    // Using multiple selectors to avoid unnecessary rebuilds for other state changes
    ref.watch(assetViewerProvider.select((s) => s.backgroundOpacity));
    ref.watch(assetViewerProvider.select((s) => s.stackIndex));
    ref.watch(isPlayingMotionVideoProvider);
    // final currentAsset = ref.watch(currentAssetNotifier);
    print("rebuild");
    // print("CurrentAsset ${currentAsset.hashCode}");
    // Listen for casting changes and send initial asset to the cast provider
    ref.listen(castProvider.select((value) => value.isCasting), (_, isCasting) async {
      if (!isCasting) return;

      final asset = ref.read(currentAssetNotifier);
      if (asset == null) return;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleCasting(asset);
      });
    });

    return Stack(
      children: [
        PhotoViewGallery.builder(
          gaplessPlayback: true,
          loadingBuilder: _placeholderBuilder,
          pageController: pageController,
          scrollPhysics: platform.isIOS
              ? const FastScrollPhysics() // Use bouncing physics for iOS
              : const FastClampingScrollPhysics(), // Use heavy physics for Android
          itemCount: totalAssets,
          onPageChanged: _onPageChanged,
          onPageBuild: _onPageBuild,
          scaleStateChangedCallback: _onScaleStateChanged,
          builder: _assetBuilder,
          backgroundDecoration: BoxDecoration(color: backgroundColor),
          enablePanAlways: true,
        ),
        // if (currentAsset?.isFavorite == true)
        //   Center(
        //     child: Text("FAV", style: TextStyle(color: Colors.pink)),
        //   ),
      ],
    );
  }
}
