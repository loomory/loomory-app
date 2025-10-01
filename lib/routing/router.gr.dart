// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

part of 'router.dart';

/// generated route for
/// [AddPhotosPage]
class AddPhotosRoute extends PageRouteInfo<void> {
  const AddPhotosRoute({List<PageRouteInfo>? children})
    : super(AddPhotosRoute.name, initialChildren: children);

  static const String name = 'AddPhotosRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const AddPhotosPage();
    },
  );
}

/// generated route for
/// [AlbumsPage]
class AlbumsRoute extends PageRouteInfo<void> {
  const AlbumsRoute({List<PageRouteInfo>? children})
    : super(AlbumsRoute.name, initialChildren: children);

  static const String name = 'AlbumsRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const AlbumsPage();
    },
  );
}

/// generated route for
/// [AssetSelectionTimelinePage]
class AssetSelectionTimelineRoute
    extends PageRouteInfo<AssetSelectionTimelineRouteArgs> {
  AssetSelectionTimelineRoute({
    Key? key,
    required RemoteAlbum album,
    Set<BaseAsset> lockedSelectionAssets = const {},
    List<PageRouteInfo>? children,
  }) : super(
         AssetSelectionTimelineRoute.name,
         args: AssetSelectionTimelineRouteArgs(
           key: key,
           album: album,
           lockedSelectionAssets: lockedSelectionAssets,
         ),
         initialChildren: children,
       );

  static const String name = 'AssetSelectionTimelineRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<AssetSelectionTimelineRouteArgs>();
      return AssetSelectionTimelinePage(
        key: args.key,
        album: args.album,
        lockedSelectionAssets: args.lockedSelectionAssets,
      );
    },
  );
}

class AssetSelectionTimelineRouteArgs {
  const AssetSelectionTimelineRouteArgs({
    this.key,
    required this.album,
    this.lockedSelectionAssets = const {},
  });

  final Key? key;

  final RemoteAlbum album;

  final Set<BaseAsset> lockedSelectionAssets;

  @override
  String toString() {
    return 'AssetSelectionTimelineRouteArgs{key: $key, album: $album, lockedSelectionAssets: $lockedSelectionAssets}';
  }
}

/// generated route for
/// [AssetViewerPage]
class AssetViewerRoute extends PageRouteInfo<AssetViewerRouteArgs> {
  AssetViewerRoute({
    Key? key,
    required int initialIndex,
    required TimelineService timelineService,
    int? heroOffset,
    List<PageRouteInfo>? children,
  }) : super(
         AssetViewerRoute.name,
         args: AssetViewerRouteArgs(
           key: key,
           initialIndex: initialIndex,
           timelineService: timelineService,
           heroOffset: heroOffset,
         ),
         initialChildren: children,
       );

  static const String name = 'AssetViewerRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<AssetViewerRouteArgs>();
      return AssetViewerPage(
        key: args.key,
        initialIndex: args.initialIndex,
        timelineService: args.timelineService,
        heroOffset: args.heroOffset,
      );
    },
  );
}

class AssetViewerRouteArgs {
  const AssetViewerRouteArgs({
    this.key,
    required this.initialIndex,
    required this.timelineService,
    this.heroOffset,
  });

  final Key? key;

  final int initialIndex;

  final TimelineService timelineService;

  final int? heroOffset;

  @override
  String toString() {
    return 'AssetViewerRouteArgs{key: $key, initialIndex: $initialIndex, timelineService: $timelineService, heroOffset: $heroOffset}';
  }
}

/// generated route for
/// [ChangeExperiencePage]
class ChangeExperienceRoute extends PageRouteInfo<ChangeExperienceRouteArgs> {
  ChangeExperienceRoute({
    Key? key,
    required bool switchingToBeta,
    List<PageRouteInfo>? children,
  }) : super(
         ChangeExperienceRoute.name,
         args: ChangeExperienceRouteArgs(
           key: key,
           switchingToBeta: switchingToBeta,
         ),
         initialChildren: children,
       );

  static const String name = 'ChangeExperienceRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<ChangeExperienceRouteArgs>();
      return ChangeExperiencePage(
        key: args.key,
        switchingToBeta: args.switchingToBeta,
      );
    },
  );
}

class ChangeExperienceRouteArgs {
  const ChangeExperienceRouteArgs({this.key, required this.switchingToBeta});

  final Key? key;

  final bool switchingToBeta;

  @override
  String toString() {
    return 'ChangeExperienceRouteArgs{key: $key, switchingToBeta: $switchingToBeta}';
  }
}

/// generated route for
/// [ChangePasswordPage]
class ChangePasswordRoute extends PageRouteInfo<void> {
  const ChangePasswordRoute({List<PageRouteInfo>? children})
    : super(ChangePasswordRoute.name, initialChildren: children);

  static const String name = 'ChangePasswordRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const ChangePasswordPage();
    },
  );
}

/// generated route for
/// [CreateAlbumPage]
class CreateAlbumRoute extends PageRouteInfo<void> {
  const CreateAlbumRoute({List<PageRouteInfo>? children})
    : super(CreateAlbumRoute.name, initialChildren: children);

  static const String name = 'CreateAlbumRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const CreateAlbumPage();
    },
  );
}

/// generated route for
/// [LoginPage]
class LoginRoute extends PageRouteInfo<void> {
  const LoginRoute({List<PageRouteInfo>? children})
    : super(LoginRoute.name, initialChildren: children);

  static const String name = 'LoginRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const LoginPage();
    },
  );
}

/// generated route for
/// [MainTimelinePage]
class MainTimelineRoute extends PageRouteInfo<void> {
  const MainTimelineRoute({List<PageRouteInfo>? children})
    : super(MainTimelineRoute.name, initialChildren: children);

  static const String name = 'MainTimelineRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const MainTimelinePage();
    },
  );
}

/// generated route for
/// [PhotosPage]
class PhotosRoute extends PageRouteInfo<void> {
  const PhotosRoute({List<PageRouteInfo>? children})
    : super(PhotosRoute.name, initialChildren: children);

  static const String name = 'PhotosRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const PhotosPage();
    },
  );
}

/// generated route for
/// [PlaceholderPage]
class PlaceholderRoute extends PageRouteInfo<void> {
  const PlaceholderRoute({List<PageRouteInfo>? children})
    : super(PlaceholderRoute.name, initialChildren: children);

  static const String name = 'PlaceholderRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const PlaceholderPage();
    },
  );
}

/// generated route for
/// [RequestAlbumAccessPage]
class RequestAlbumAccessRoute
    extends PageRouteInfo<RequestAlbumAccessRouteArgs> {
  RequestAlbumAccessRoute({
    Key? key,
    required String albumId,
    required String albumName,
    required String ownerId,
    List<PageRouteInfo>? children,
  }) : super(
         RequestAlbumAccessRoute.name,
         args: RequestAlbumAccessRouteArgs(
           key: key,
           albumId: albumId,
           albumName: albumName,
           ownerId: ownerId,
         ),
         initialChildren: children,
       );

  static const String name = 'RequestAlbumAccessRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<RequestAlbumAccessRouteArgs>();
      return RequestAlbumAccessPage(
        key: args.key,
        albumId: args.albumId,
        albumName: args.albumName,
        ownerId: args.ownerId,
      );
    },
  );
}

class RequestAlbumAccessRouteArgs {
  const RequestAlbumAccessRouteArgs({
    this.key,
    required this.albumId,
    required this.albumName,
    required this.ownerId,
  });

  final Key? key;

  final String albumId;

  final String albumName;

  final String ownerId;

  @override
  String toString() {
    return 'RequestAlbumAccessRouteArgs{key: $key, albumId: $albumId, albumName: $albumName, ownerId: $ownerId}';
  }
}

/// generated route for
/// [SplashScreenPage]
class SplashScreenRoute extends PageRouteInfo<void> {
  const SplashScreenRoute({List<PageRouteInfo>? children})
    : super(SplashScreenRoute.name, initialChildren: children);

  static const String name = 'SplashScreenRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const SplashScreenPage();
    },
  );
}

/// generated route for
/// [TabControllerPage]
class TabControllerRoute extends PageRouteInfo<void> {
  const TabControllerRoute({List<PageRouteInfo>? children})
    : super(TabControllerRoute.name, initialChildren: children);

  static const String name = 'TabControllerRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const TabControllerPage();
    },
  );
}

/// generated route for
/// [TabShellPage]
class TabShellRoute extends PageRouteInfo<void> {
  const TabShellRoute({List<PageRouteInfo>? children})
    : super(TabShellRoute.name, initialChildren: children);

  static const String name = 'TabShellRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const TabShellPage();
    },
  );
}
