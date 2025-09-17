import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:immich_mobile/domain/models/album/album.model.dart';
import 'package:immich_mobile/domain/models/asset/base_asset.model.dart';
import 'package:immich_mobile/domain/services/remote_album.service.dart';
import 'package:immich_mobile/extensions/build_context_extensions.dart';
import 'package:immich_mobile/extensions/translate_extensions.dart';
import 'package:immich_mobile/models/albums/album_search.model.dart';
import 'package:immich_mobile/presentation/widgets/images/thumbnail.widget.dart';
import 'package:immich_mobile/providers/infrastructure/album.provider.dart';
import 'package:immich_mobile/providers/infrastructure/current_album.provider.dart';
import 'package:immich_mobile/providers/timeline/multiselect.provider.dart';
import 'package:immich_mobile/providers/user.provider.dart';
import 'package:immich_mobile/providers/api.provider.dart';
import 'package:immich_mobile/utils/album_filter.utils.dart';
// ignore: import_rule_openapi
import 'package:openapi/api.dart';
import 'package:immich_mobile/widgets/common/immich_toast.dart';
import 'package:sliver_tools/sliver_tools.dart';

import '../../../design_system/ds_searchbar.dart';
import '../../../routing/router.dart';

typedef AlbumSelectorCallback = void Function(RemoteAlbum album);

class AlbumSelector extends ConsumerStatefulWidget {
  final AlbumSelectorCallback onAlbumSelected;
  final Function? onKeyboardExpanded;

  const AlbumSelector({super.key, required this.onAlbumSelected, this.onKeyboardExpanded});

  @override
  ConsumerState<AlbumSelector> createState() => _AlbumSelectorState();
}

class _AlbumSelectorState extends ConsumerState<AlbumSelector> {
  final searchController = TextEditingController();
  final searchFocusNode = FocusNode();
  List<RemoteAlbum> sortedAlbums = [];
  List<RemoteAlbum> shownAlbums = [];

  AlbumFilter filter = AlbumFilter(query: "", mode: QuickFilterMode.all);
  AlbumSort sort = AlbumSort(mode: RemoteAlbumSortMode.lastModified, isReverse: true);

  @override
  void initState() {
    super.initState();

    // Load albums when component mounts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(remoteAlbumProvider.notifier).refresh();
    });

    searchController.addListener(() {
      onSearch(searchController.text, filter.mode);
    });

    searchFocusNode.addListener(() {
      if (searchFocusNode.hasFocus) {
        widget.onKeyboardExpanded?.call();
      }
    });
  }

  void onSearch(String searchTerm, QuickFilterMode filterMode) {
    final userId = ref.watch(currentUserProvider)?.id;
    filter = filter.copyWith(query: searchTerm, userId: userId, mode: filterMode);

    filterAlbums();
  }

  Future<void> onRefresh() async {
    await ref.read(remoteAlbumProvider.notifier).refresh();
  }

  void changeFilter(QuickFilterMode mode) {
    setState(() {
      filter = filter.copyWith(mode: mode);
    });

    filterAlbums();
  }

  Future<void> changeSort(AlbumSort sort) async {
    setState(() {
      this.sort = sort;
    });

    await sortAlbums();
  }

  void clearSearch() {
    setState(() {
      filter = filter.copyWith(mode: QuickFilterMode.all, query: null);
      searchController.clear();
    });

    filterAlbums();
  }

  Future<void> sortAlbums() async {
    final albumState = ref.read(remoteAlbumProvider);
    final sorted = await ref
        .read(remoteAlbumProvider.notifier)
        .sortAlbums(albumState.albums, sort.mode, isReverse: sort.isReverse);

    setState(() {
      sortedAlbums = sorted;
    });

    // we need to re-filter the albums after sorting
    // so shownAlbums gets updated
    filterAlbums();
  }

  Future<void> filterAlbums() async {
    if (filter.query == null) {
      setState(() {
        shownAlbums = sortedAlbums;
      });

      return;
    }

    final filteredAlbums = ref
        .read(remoteAlbumProvider.notifier)
        .searchAlbums(sortedAlbums, filter.query!, filter.userId, filter.mode);

    setState(() {
      shownAlbums = filteredAlbums;
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(currentUserProvider)?.id;

    // Watch the provider to trigger rebuilds when albums change
    ref.watch(remoteAlbumProvider);

    // refilter and sort when albums change
    ref.listen(remoteAlbumProvider.select((state) => state.albums), (_, _) async {
      await sortAlbums();
    });

    return MultiSliver(
      children: [
        DSSearchBar(
          searchController: searchController,
          searchFocusNode: searchFocusNode,
          onSearch: onSearch,
          filterMode: filter.mode,
          onClearSearch: clearSearch,
        ),
        _QuickFilterButtonRow(
          filterMode: filter.mode,
          onChangeFilter: changeFilter,
          onSearch: onSearch,
          searchController: searchController,
        ),

        _AlbumGrid(albums: shownAlbums, userId: userId, onAlbumSelected: widget.onAlbumSelected),
      ],
    );
  }
}

class _SortButton extends ConsumerStatefulWidget {
  const _SortButton(this.onSortChanged);

  final Future<void> Function(AlbumSort) onSortChanged;

  @override
  ConsumerState<_SortButton> createState() => _SortButtonState();
}

class _SortButtonState extends ConsumerState<_SortButton> {
  RemoteAlbumSortMode albumSortOption = RemoteAlbumSortMode.lastModified;
  bool albumSortIsReverse = true;
  bool isSorting = false;

  Future<void> onMenuTapped(RemoteAlbumSortMode sortMode) async {
    final selected = albumSortOption == sortMode;
    // Switch direction
    if (selected) {
      setState(() {
        albumSortIsReverse = !albumSortIsReverse;
        isSorting = true;
      });
    } else {
      setState(() {
        albumSortOption = sortMode;
        isSorting = true;
      });
    }

    await widget.onSortChanged.call(AlbumSort(mode: albumSortOption, isReverse: albumSortIsReverse));

    setState(() {
      isSorting = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      style: MenuStyle(
        elevation: const WidgetStatePropertyAll(1),
        shape: WidgetStateProperty.all(
          const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(24))),
        ),
        padding: const WidgetStatePropertyAll(EdgeInsets.all(4)),
      ),
      consumeOutsideTap: true,
      menuChildren: RemoteAlbumSortMode.values
          .map(
            (sortMode) => MenuItemButton(
              leadingIcon: albumSortOption == sortMode
                  ? albumSortIsReverse
                        ? Icon(
                            Icons.keyboard_arrow_down,
                            color: albumSortOption == sortMode
                                ? context.colorScheme.onPrimary
                                : context.colorScheme.onSurface,
                          )
                        : Icon(
                            Icons.keyboard_arrow_up_rounded,
                            color: albumSortOption == sortMode
                                ? context.colorScheme.onPrimary
                                : context.colorScheme.onSurface,
                          )
                  : const Icon(Icons.abc, color: Colors.transparent),
              onPressed: () => onMenuTapped(sortMode),
              style: ButtonStyle(
                padding: WidgetStateProperty.all(const EdgeInsets.fromLTRB(16, 16, 32, 16)),
                backgroundColor: WidgetStateProperty.all(
                  albumSortOption == sortMode ? context.colorScheme.primary : Colors.transparent,
                ),
                shape: WidgetStateProperty.all(
                  const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(24))),
                ),
              ),
              child: Text(
                sortMode.key.t(context: context),
                style: context.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: albumSortOption == sortMode
                      ? context.colorScheme.onPrimary
                      : context.colorScheme.onSurface.withAlpha(185),
                ),
              ),
            ),
          )
          .toList(),
      builder: (context, controller, child) {
        return GestureDetector(
          onTap: () {
            if (controller.isOpen) {
              controller.close();
            } else {
              controller.open();
            }
          },
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 5),
                child: albumSortIsReverse
                    ? const Icon(Icons.keyboard_arrow_down)
                    : const Icon(Icons.keyboard_arrow_up_rounded),
              ),
              Text(
                albumSortOption.key.t(context: context),
                style: context.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: context.colorScheme.onSurface.withAlpha(225),
                ),
              ),
              isSorting
                  ? SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: context.colorScheme.onSurface.withAlpha(225),
                      ),
                    )
                  : const SizedBox.shrink(),
            ],
          ),
        );
      },
    );
  }
}

class _QuickFilterButtonRow extends StatelessWidget {
  const _QuickFilterButtonRow({
    required this.filterMode,
    required this.onChangeFilter,
    required this.onSearch,
    required this.searchController,
  });

  final QuickFilterMode filterMode;
  final void Function(QuickFilterMode) onChangeFilter;
  final void Function(String, QuickFilterMode) onSearch;
  final TextEditingController searchController;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverToBoxAdapter(
        child: Wrap(
          spacing: 4,
          runSpacing: 4,
          children: [
            _QuickFilterButton(
              label: 'all'.tr(),
              isSelected: filterMode == QuickFilterMode.all,
              onTap: () {
                onChangeFilter(QuickFilterMode.all);
                onSearch(searchController.text, QuickFilterMode.all);
              },
            ),
            _QuickFilterButton(
              label: 'my_albums'.tr(),
              isSelected: filterMode == QuickFilterMode.myAlbums,
              onTap: () {
                onChangeFilter(QuickFilterMode.myAlbums);
                onSearch(searchController.text, QuickFilterMode.myAlbums);
              },
            ),
            _QuickFilterButton(
              label: 'shared_with_me'.tr(),
              isSelected: filterMode == QuickFilterMode.sharedWithMe,
              onTap: () {
                onChangeFilter(QuickFilterMode.sharedWithMe);
                onSearch(searchController.text, QuickFilterMode.sharedWithMe);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickFilterButton extends StatelessWidget {
  const _QuickFilterButton({required this.isSelected, required this.onTap, required this.label});

  final bool isSelected;
  final VoidCallback onTap;
  final String label;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.all(isSelected ? context.colorScheme.primary : Colors.transparent),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: const BorderRadius.all(Radius.circular(20)),
            side: BorderSide(color: context.colorScheme.onSurface.withAlpha(25), width: 1),
          ),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? context.colorScheme.onPrimary : context.colorScheme.onSurface,
          fontSize: 14,
        ),
      ),
    );
  }
}

class _AlbumGrid extends StatelessWidget {
  const _AlbumGrid({required this.albums, required this.userId, required this.onAlbumSelected});

  final List<RemoteAlbum> albums;
  final String? userId;
  final AlbumSelectorCallback onAlbumSelected;

  @override
  Widget build(BuildContext context) {
    if (albums.isEmpty) {
      return const SliverToBoxAdapter(
        child: Center(
          child: Padding(padding: EdgeInsets.all(20.0), child: Text('No albums found')),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 250,
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
          childAspectRatio: .7,
        ),
        delegate: SliverChildBuilderDelegate((context, index) {
          final album = albums[index];
          return _GridAlbumCard(album: album, userId: userId, onAlbumSelected: onAlbumSelected);
        }, childCount: albums.length),
      ),
    );
  }
}

class _GridAlbumCard extends ConsumerWidget {
  const _GridAlbumCard({required this.album, required this.userId, required this.onAlbumSelected});

  final RemoteAlbum album;
  final String? userId;
  final AlbumSelectorCallback onAlbumSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => onAlbumSelected(album),
      child: Card(
        elevation: 0,
        color: context.colorScheme.surfaceBright,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(Radius.circular(16)),
          side: BorderSide(color: context.colorScheme.onSurface.withAlpha(25), width: 1),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(16)),
          child: Stack(
            children: [
              SizedBox(
                width: double.infinity,
                child: album.thumbnailAssetId != null
                    ? Thumbnail.remote(remoteId: album.thumbnailAssetId!)
                    : Container(
                        color: Colors.grey,
                        child: Center(child: const Icon(Icons.photo_album_rounded, size: 100, color: Colors.white)),
                      ),
              ),
              Align(
                alignment: Alignment.bottomLeft,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Text(
                    '${album.name[0].toUpperCase()}${album.name.substring(1)}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  onPressed: () async {
                    await showCupertinoModalPopup<String>(
                      context: context,
                      builder: (context) => CupertinoActionSheet(
                        title: Text(
                          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
                          '${album.name[0].toUpperCase()}${album.name.substring(1)}',
                        ),
                        actions: [
                          CupertinoActionSheetAction(
                            onPressed: () async {
                              Navigator.pop(context);
                              final albumAssets = await ref.read(remoteAlbumProvider.notifier).getAssets(album.id);

                              final _ = await context.pushRoute<Set<BaseAsset>>(
                                AssetSelectionTimelineRoute(album: album, lockedSelectionAssets: albumAssets.toSet()),
                              );
                              await ref.read(remoteAlbumProvider.notifier).refresh();
                            },
                            child: Text("Add photos to album"),
                          ),
                          CupertinoActionSheetAction(
                            onPressed: () => {
                              Navigator.pop(context),

                              // TODO route to invites
                            },
                            child: Text("Invite collaborators"),
                          ),
                          CupertinoActionSheetAction(
                            onPressed: () => {
                              Navigator.pop(context),
                              // create link
                            },
                            child: Text("Create sharing link"),
                          ),
                          CupertinoActionSheetAction(
                            isDestructiveAction: true,
                            onPressed: () async {
                              await deleteAlbum(context, ref, album);
                              Navigator.pop(context);
                            },
                            child: Text("Delete album"),
                          ),
                        ],
                        cancelButton: CupertinoActionSheetAction(
                          onPressed: () => Navigator.pop(context),
                          child: Text("Cancel"),
                        ),
                      ),
                    );
                  },
                  icon: Icon(color: Colors.white, Icons.more_vert_sharp),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> deleteAlbum(BuildContext context, WidgetRef ref, RemoteAlbum album) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('delete_album'.t(context: context)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('album_delete_confirmation'.t(context: context, args: {'album': album.name})),
              const SizedBox(height: 8),
              Text('album_delete_confirmation_description'.t(context: context)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('cancel'.t(context: context)),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
              child: Text('delete_album'.t(context: context)),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        await ref.read(remoteAlbumProvider.notifier).deleteAlbum(album.id);
      } catch (e) {
        ImmichToast.show(
          context: context,
          msg: 'album_viewer_appbar_share_err_delete'.t(context: context),
          toastType: ToastType.error,
        );
      }
    }
  }
}

// TODO Don't think we need this here, creating new album will be done with the + button,
class AddToAlbumHeader extends ConsumerWidget {
  const AddToAlbumHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Future<void> onCreateAlbum() async {
      final newAlbum = await ref
          .read(remoteAlbumProvider.notifier)
          .createAlbum(
            title: "Untitled Album",
            assetIds: ref.read(multiSelectProvider).selectedAssets.map((e) => (e as RemoteAsset).id).toList(),
          );

      if (newAlbum == null) {
        ImmichToast.show(context: context, toastType: ToastType.error, msg: 'errors.failed_to_create_album'.tr());
        return;
      }

      ref.read(currentRemoteAlbumProvider.notifier).setAlbum(newAlbum);
      ref.read(multiSelectProvider.notifier).reset();
      //context.pushRoute(RemoteAlbumRoute(album: newAlbum));
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverToBoxAdapter(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("add_to_album", style: context.textTheme.titleSmall).tr(),
            TextButton.icon(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), // remove internal padding
                minimumSize: const Size(0, 0), // allow shrinking
                tapTargetSize: MaterialTapTargetSize.shrinkWrap, // remove extra height
              ),
              onPressed: onCreateAlbum,
              icon: Icon(Icons.add, color: context.primaryColor),
              label: Text(
                "common_create_new_album",
                style: TextStyle(color: context.primaryColor, fontWeight: FontWeight.bold, fontSize: 14),
              ).tr(),
            ),
          ],
        ),
      ),
    );
  }
}

/// Efficiently refreshes a single album from the server to get updated metadata (like thumbnailAssetId)
/// This is much more efficient than doing a full remote sync when we only need to update one album
Future<void> refreshSingleAlbum(WidgetRef ref, String albumId) async {
  try {
    // Get the API service to fetch album info directly
    final apiService = ref.read(apiServiceProvider);
    final albumsApi = apiService.albumsApi;

    // Get the remote album repository
    final remoteAlbumRepo = ref.read(remoteAlbumRepository);

    // Fetch the updated album from the API
    final updatedAlbumDto = await albumsApi.getAlbumInfo(albumId);
    if (updatedAlbumDto != null) {
      // Convert to RemoteAlbum manually (since extension is private)
      final remoteAlbum = RemoteAlbum(
        id: updatedAlbumDto.id,
        name: updatedAlbumDto.albumName,
        ownerId: updatedAlbumDto.owner.id,
        description: updatedAlbumDto.description,
        createdAt: updatedAlbumDto.createdAt,
        updatedAt: updatedAlbumDto.updatedAt,
        thumbnailAssetId: updatedAlbumDto.albumThumbnailAssetId,
        isActivityEnabled: updatedAlbumDto.isActivityEnabled,
        order: updatedAlbumDto.order == AssetOrder.asc ? AlbumAssetOrder.asc : AlbumAssetOrder.desc,
        assetCount: updatedAlbumDto.assetCount,
        ownerName: updatedAlbumDto.owner.name,
        isShared: updatedAlbumDto.albumUsers.length > 2,
      );

      await remoteAlbumRepo.update(remoteAlbum);

      // Refresh the provider state to trigger UI updates
      await ref.read(remoteAlbumProvider.notifier).refresh();
    }
  } catch (e) {
    debugPrint("Failed to refresh single album: $e");
    // Fallback to full refresh if single album refresh fails
    await ref.read(remoteAlbumProvider.notifier).refresh();
  }
}
