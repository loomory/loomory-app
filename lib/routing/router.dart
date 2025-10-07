import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:immich_mobile/domain/models/album/album.model.dart';
import 'package:immich_mobile/domain/models/asset/base_asset.model.dart';
import 'package:immich_mobile/providers/api.provider.dart';
import 'package:immich_mobile/providers/gallery_permission.provider.dart';
import 'package:immich_mobile/routing/auth_guard.dart';
import 'package:immich_mobile/routing/backup_permission_guard.dart';
import 'package:immich_mobile/routing/duplicate_guard.dart';
import 'package:immich_mobile/routing/gallery_guard.dart';
import 'package:immich_mobile/routing/locked_guard.dart';
import 'package:immich_mobile/services/api.service.dart';
import 'package:immich_mobile/services/local_auth.service.dart';
import 'package:immich_mobile/services/secure_storage.service.dart';
import 'package:immich_mobile/domain/services/timeline.service.dart';

// All pages that can have a route must be in /pages and then imported here
import '../features/common/splash_screen.page.dart';
import '../features/common/tab_shell.page.dart';
import '../features/common/asset_viewer.page.dart';
import '../features/login/login.page.dart';
import '../features/login/change_password.page.dart';
import '../features/main_timeline/main_timeline.page.dart';
import '../features/add_photos/add_photos.page.dart';
import '../features/add_options/placeholder.page.dart';
import '../features/albums/albums.page.dart';
import '../features/albums/album_asset_selection.page.dart';
import '../features/albums/create_album.page.dart';
import '../features/album_access/request_album_access.page.dart';
import '../features/album_access/album_access.page.dart';

// This is old timeline and must be removed when beta timeline can be selected from the start
import '../features/legacy/tab_controller.page.dart';
import '../features/legacy/photos.page.dart';
import '../features/legacy/change_experience.page.dart';

part 'router.gr.dart';

final appRouterProvider = Provider(
  (ref) => AppRouter(
    ref.watch(apiServiceProvider),
    ref.watch(galleryPermissionNotifier.notifier),
    ref.watch(secureStorageServiceProvider),
    ref.watch(localAuthServiceProvider),
  ),
);

@AutoRouterConfig(replaceInRouteName: 'Page,Route', generateForDir: ['lib/features/', 'lib/widgets/'])
class AppRouter extends RootStackRouter {
  late final AuthGuard _authGuard;
  late final DuplicateGuard _duplicateGuard;
  late final BackupPermissionGuard _backupPermissionGuard;
  late final LockedGuard _lockedGuard;
  late final GalleryGuard _galleryGuard;

  AppRouter(
    ApiService apiService,
    GalleryPermissionNotifier galleryPermissionNotifier,
    SecureStorageService secureStorageService,
    LocalAuthService localAuthService,
  ) {
    _authGuard = AuthGuard(apiService);
    _duplicateGuard = const DuplicateGuard();
    _lockedGuard = LockedGuard(apiService, secureStorageService, localAuthService);
    _backupPermissionGuard = BackupPermissionGuard(galleryPermissionNotifier);
    _galleryGuard = const GalleryGuard();
  }

  @override
  RouteType get defaultRouteType => const RouteType.material();

  @override
  late final List<AutoRoute> routes = [
    AutoRoute(page: SplashScreenRoute.page, initial: true),
    // AutoRoute(page: PermissionOnboardingRoute.page, guards: [_authGuard, _duplicateGuard]),
    AutoRoute(page: LoginRoute.page, guards: [_duplicateGuard]),

    //AutoRoute(page: ChangePasswordRoute.page),
    CustomRoute(
      page: TabControllerRoute.page,
      guards: [_authGuard, _duplicateGuard],
      children: [
        AutoRoute(page: PhotosRoute.page, guards: [_authGuard, _duplicateGuard]),
      ],
      transitionsBuilder: TransitionsBuilders.fadeIn,
    ),

    CustomRoute(
      page: TabShellRoute.page,
      guards: [_authGuard, _duplicateGuard],
      children: [
        AutoRoute(page: MainTimelineRoute.page, guards: [_authGuard, _duplicateGuard]),
        // Must match in tab_shell routes when changed
        AutoRoute(page: MainTimelineRoute.page, guards: [_authGuard, _duplicateGuard]),
        AutoRoute(page: PlaceholderRoute.page, guards: [_authGuard, _duplicateGuard]),
        //AutoRoute(page: DriftSearchRoute.page, guards: [_authGuard, _duplicateGuard], maintainState: false),
        // AutoRoute(page: DriftLibraryRoute.page, guards: [_authGuard, _duplicateGuard]),
        AutoRoute(page: AlbumsRoute.page, guards: [_authGuard, _duplicateGuard]),
      ],
      transitionsBuilder: TransitionsBuilders.fadeIn,
    ),

    AutoRoute(page: AddPhotosRoute.page, guards: [_authGuard, _duplicateGuard]),

    // CustomRoute(
    //   page: GalleryViewerRoute.page,
    //   guards: [_authGuard, _galleryGuard],
    //   transitionsBuilder: CustomTransitionsBuilders.zoomedPage,
    // ),
    // AutoRoute(page: BackupControllerRoute.page, guards: [_authGuard, _duplicateGuard, _backupPermissionGuard]),
    // AutoRoute(page: AllPlacesRoute.page, guards: [_authGuard, _duplicateGuard]),
    // AutoRoute(page: CreateAlbumRoute.page, guards: [_authGuard, _duplicateGuard]),
    // AutoRoute(page: EditImageRoute.page),
    // AutoRoute(page: CropImageRoute.page),
    // AutoRoute(page: FilterImageRoute.page),
    // CustomRoute(
    //   page: FavoritesRoute.page,
    //   guards: [_authGuard, _duplicateGuard],
    //   transitionsBuilder: TransitionsBuilders.slideLeft,
    // ),
    // AutoRoute(page: AllVideosRoute.page, guards: [_authGuard, _duplicateGuard]),
    // AutoRoute(page: AllMotionPhotosRoute.page, guards: [_authGuard, _duplicateGuard]),
    // AutoRoute(page: RecentlyTakenRoute.page, guards: [_authGuard, _duplicateGuard]),
    // CustomRoute(
    //   page: AlbumAssetSelectionRoute.page,
    //   guards: [_authGuard, _duplicateGuard],
    //   transitionsBuilder: TransitionsBuilders.slideBottom,
    // ),
    // CustomRoute(
    //   page: AlbumSharedUserSelectionRoute.page,
    //   guards: [_authGuard, _duplicateGuard],
    //   transitionsBuilder: TransitionsBuilders.slideBottom,
    // ),
    // AutoRoute(page: AlbumViewerRoute.page, guards: [_authGuard, _duplicateGuard]),
    // CustomRoute(
    //   page: AlbumAdditionalSharedUserSelectionRoute.page,
    //   guards: [_authGuard, _duplicateGuard],
    //   transitionsBuilder: TransitionsBuilders.slideBottom,
    // ),
    // AutoRoute(page: BackupAlbumSelectionRoute.page, guards: [_authGuard, _duplicateGuard]),
    // AutoRoute(page: AlbumPreviewRoute.page, guards: [_authGuard, _duplicateGuard]),
    // CustomRoute(
    //   page: FailedBackupStatusRoute.page,
    //   guards: [_authGuard, _duplicateGuard],
    //   transitionsBuilder: TransitionsBuilders.slideBottom,
    // ),
    // AutoRoute(page: SettingsRoute.page, guards: [_duplicateGuard]),
    // AutoRoute(page: SettingsSubRoute.page, guards: [_duplicateGuard]),
    // AutoRoute(page: AppLogRoute.page, guards: [_duplicateGuard]),
    // AutoRoute(page: AppLogDetailRoute.page, guards: [_duplicateGuard]),
    // CustomRoute(
    //   page: ArchiveRoute.page,
    //   guards: [_authGuard, _duplicateGuard],
    //   transitionsBuilder: TransitionsBuilders.slideLeft,
    // ),
    // CustomRoute(
    //   page: PartnerRoute.page,
    //   guards: [_authGuard, _duplicateGuard],
    //   transitionsBuilder: TransitionsBuilders.slideLeft,
    // ),
    // CustomRoute(page: FolderRoute.page, guards: [_authGuard], transitionsBuilder: TransitionsBuilders.fadeIn),
    // AutoRoute(page: PartnerDetailRoute.page, guards: [_authGuard, _duplicateGuard]),
    // AutoRoute(page: PersonResultRoute.page, guards: [_authGuard, _duplicateGuard]),
    // AutoRoute(page: AllPeopleRoute.page, guards: [_authGuard, _duplicateGuard]),
    // AutoRoute(page: MemoryRoute.page, guards: [_authGuard, _duplicateGuard]),
    // AutoRoute(page: MapRoute.page, guards: [_authGuard, _duplicateGuard]),
    // AutoRoute(page: AlbumOptionsRoute.page, guards: [_authGuard, _duplicateGuard]),
    // CustomRoute(
    //   page: TrashRoute.page,
    //   guards: [_authGuard, _duplicateGuard],
    //   transitionsBuilder: TransitionsBuilders.slideLeft,
    // ),
    // CustomRoute(
    //   page: SharedLinkRoute.page,
    //   guards: [_authGuard, _duplicateGuard],
    //   transitionsBuilder: TransitionsBuilders.slideLeft,
    // ),
    // AutoRoute(page: SharedLinkEditRoute.page, guards: [_authGuard, _duplicateGuard]),
    // CustomRoute(
    //   page: ActivitiesRoute.page,
    //   guards: [_authGuard, _duplicateGuard],
    //   transitionsBuilder: TransitionsBuilders.slideLeft,
    //   durationInMilliseconds: 200,
    // ),
    // CustomRoute(page: MapLocationPickerRoute.page, guards: [_authGuard, _duplicateGuard]),
    // AutoRoute(page: BackupOptionsRoute.page, guards: [_authGuard, _duplicateGuard]),
    // AutoRoute(page: HeaderSettingsRoute.page, guards: [_duplicateGuard]),
    // CustomRoute(
    //   page: PeopleCollectionRoute.page,
    //   guards: [_authGuard, _duplicateGuard],
    //   transitionsBuilder: TransitionsBuilders.slideLeft,
    // ),
    // CustomRoute(
    //   page: AlbumsRoute.page,
    //   guards: [_authGuard, _duplicateGuard],
    //   transitionsBuilder: TransitionsBuilders.slideLeft,
    // ),
    // CustomRoute(
    //   page: LocalAlbumsRoute.page,
    //   guards: [_authGuard, _duplicateGuard],
    //   transitionsBuilder: TransitionsBuilders.slideLeft,
    // ),
    // CustomRoute(
    //   page: PlacesCollectionRoute.page,
    //   guards: [_authGuard, _duplicateGuard],
    //   transitionsBuilder: TransitionsBuilders.slideLeft,
    // ),
    // AutoRoute(page: NativeVideoViewerRoute.page, guards: [_authGuard, _duplicateGuard]),
    // AutoRoute(page: ShareIntentRoute.page, guards: [_authGuard, _duplicateGuard]),
    // AutoRoute(page: LockedRoute.page, guards: [_authGuard, _lockedGuard, _duplicateGuard]),
    // AutoRoute(page: PinAuthRoute.page, guards: [_authGuard, _duplicateGuard]),
    // AutoRoute(page: FeatInDevRoute.page, guards: [_authGuard, _duplicateGuard]),
    // AutoRoute(page: LocalMediaSummaryRoute.page, guards: [_authGuard, _duplicateGuard]),
    // AutoRoute(page: RemoteMediaSummaryRoute.page, guards: [_authGuard, _duplicateGuard]),
    // AutoRoute(page: DriftBackupRoute.page, guards: [_authGuard, _duplicateGuard]),
    // AutoRoute(page: DriftBackupAlbumSelectionRoute.page, guards: [_authGuard, _duplicateGuard]),
    // AutoRoute(page: LocalTimelineRoute.page, guards: [_authGuard, _duplicateGuard]),
    // AutoRoute(page: MainTimelineRoute.page, guards: [_authGuard, _duplicateGuard]),
    // AutoRoute(page: RemoteAlbumRoute.page, guards: [_authGuard, _duplicateGuard]),
    AutoRoute(
      page: AssetViewerRoute.page,
      guards: [_authGuard, _duplicateGuard],
      type: RouteType.custom(
        customRouteBuilder: <T>(context, child, page) => PageRouteBuilder<T>(
          fullscreenDialog: page.fullscreenDialog,
          settings: page,
          pageBuilder: (_, __, ___) => child,
          opaque: false,
        ),
      ),
    ),
    // AutoRoute(page: DriftMemoryRoute.page, guards: [_authGuard, _duplicateGuard]),
    // AutoRoute(page: DriftFavoriteRoute.page, guards: [_authGuard, _duplicateGuard]),
    // AutoRoute(page: DriftTrashRoute.page, guards: [_authGuard, _duplicateGuard]),
    // AutoRoute(page: DriftArchiveRoute.page, guards: [_authGuard, _duplicateGuard]),
    // AutoRoute(page: DriftLockedFolderRoute.page, guards: [_authGuard, _lockedGuard, _duplicateGuard]),
    // AutoRoute(page: DriftVideoRoute.page, guards: [_authGuard, _duplicateGuard]),
    // AutoRoute(page: DriftLibraryRoute.page, guards: [_authGuard, _duplicateGuard]),
    AutoRoute(page: AssetSelectionTimelineRoute.page, guards: [_authGuard, _duplicateGuard]),
    // AutoRoute(page: DriftPartnerDetailRoute.page, guards: [_authGuard, _duplicateGuard]),
    // AutoRoute(page: DriftRecentlyTakenRoute.page, guards: [_authGuard, _duplicateGuard]),
    // AutoRoute(page: DriftLocalAlbumsRoute.page, guards: [_authGuard, _duplicateGuard]),
    AutoRoute(page: CreateAlbumRoute.page, guards: [_authGuard, _duplicateGuard]),
    AutoRoute(page: AlbumAccessRoute.page, guards: [_authGuard, _duplicateGuard]),
    AutoRoute(page: RequestAlbumAccessRoute.page, guards: [_authGuard, _duplicateGuard]),

    // AutoRoute(page: DriftPlaceRoute.page, guards: [_authGuard, _duplicateGuard]),
    // AutoRoute(page: DriftPlaceDetailRoute.page, guards: [_authGuard, _duplicateGuard]),
    // AutoRoute(page: DriftUserSelectionRoute.page, guards: [_authGuard, _duplicateGuard]),
    AutoRoute(page: ChangeExperienceRoute.page, guards: [_authGuard, _duplicateGuard]),
    // AutoRoute(page: DriftPartnerRoute.page, guards: [_authGuard, _duplicateGuard]),
    // AutoRoute(page: DriftUploadDetailRoute.page, guards: [_authGuard, _duplicateGuard]),
    // AutoRoute(page: BetaSyncSettingsRoute.page, guards: [_authGuard, _duplicateGuard]),
    // AutoRoute(page: DriftPeopleCollectionRoute.page, guards: [_authGuard, _duplicateGuard]),
    // AutoRoute(page: DriftPersonRoute.page, guards: [_authGuard]),
    // AutoRoute(page: DriftBackupOptionsRoute.page, guards: [_authGuard, _duplicateGuard]),
    // AutoRoute(page: DriftAlbumOptionsRoute.page, guards: [_authGuard, _duplicateGuard]),
    // AutoRoute(page: DriftMapRoute.page, guards: [_authGuard, _duplicateGuard]),
    // required to handle all deeplinks in deep_link.service.dart
    // auto_route_library#1722
    RedirectRoute(path: '*', redirectTo: '/'),
  ];
}
