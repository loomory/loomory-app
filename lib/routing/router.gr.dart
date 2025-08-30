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
