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
    Set<BaseAsset> lockedSelectionAssets = const {},
    List<PageRouteInfo>? children,
  }) : super(
         AssetSelectionTimelineRoute.name,
         args: AssetSelectionTimelineRouteArgs(
           key: key,
           lockedSelectionAssets: lockedSelectionAssets,
         ),
         initialChildren: children,
       );

  static const String name = 'AssetSelectionTimelineRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<AssetSelectionTimelineRouteArgs>(
        orElse: () => const AssetSelectionTimelineRouteArgs(),
      );
      return AssetSelectionTimelinePage(
        key: args.key,
        lockedSelectionAssets: args.lockedSelectionAssets,
      );
    },
  );
}

class AssetSelectionTimelineRouteArgs {
  const AssetSelectionTimelineRouteArgs({
    this.key,
    this.lockedSelectionAssets = const {},
  });

  final Key? key;

  final Set<BaseAsset> lockedSelectionAssets;

  @override
  String toString() {
    return 'AssetSelectionTimelineRouteArgs{key: $key, lockedSelectionAssets: $lockedSelectionAssets}';
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
/// [RemoteAlbumPage]
class RemoteAlbumRoute extends PageRouteInfo<RemoteAlbumRouteArgs> {
  RemoteAlbumRoute({
    Key? key,
    required RemoteAlbum album,
    List<PageRouteInfo>? children,
  }) : super(
         RemoteAlbumRoute.name,
         args: RemoteAlbumRouteArgs(key: key, album: album),
         initialChildren: children,
       );

  static const String name = 'RemoteAlbumRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<RemoteAlbumRouteArgs>();
      return RemoteAlbumPage(key: args.key, album: args.album);
    },
  );
}

class RemoteAlbumRouteArgs {
  const RemoteAlbumRouteArgs({this.key, required this.album});

  final Key? key;

  final RemoteAlbum album;

  @override
  String toString() {
    return 'RemoteAlbumRouteArgs{key: $key, album: $album}';
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
