// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

part of 'router.dart';

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
