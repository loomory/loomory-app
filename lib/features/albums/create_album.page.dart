import 'package:auto_route/auto_route.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:immich_mobile/domain/models/asset/base_asset.model.dart';
import 'package:immich_mobile/domain/models/timeline.model.dart';
import 'package:immich_mobile/extensions/build_context_extensions.dart';
import 'package:immich_mobile/extensions/translate_extensions.dart';
import 'package:immich_mobile/providers/infrastructure/album.provider.dart';
import 'package:immich_mobile/providers/infrastructure/current_album.provider.dart';
import 'package:immich_mobile/providers/timeline/multiselect.provider.dart';
import 'package:loomory/design_system/ds_input_field.dart';

import '../../design_system/ds_select_timeline.dart';
import '../add_photos/repository/local_assets.dart';

// Create a provider for all assets using your exist (can't add local assets right now, investigate)
final allAssetsProvider = FutureProvider<List<BaseAsset>>((ref) async {
  final repository = ref.watch(localAssetRepository);
  final localAssets = await repository.getAllLocalAssets();
  return localAssets.cast<BaseAsset>();
});

@RoutePage()
class CreateAlbumPage extends HookConsumerWidget {
  const CreateAlbumPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final albumTitleController = useTextEditingController();
    final albumTitleTextFieldFocusNode = useFocusNode();
    final addButtonEnabled = useState(false);

    final localAssetsAsync = ref.watch(allAssetsProvider);
    return localAssetsAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stack) => Scaffold(body: Center(child: Text('Error loading assets: $error'))),
      data: (assets) => SafeArea(
        child: ProviderScope(
          overrides: [
            multiSelectProvider.overrideWith(
              () => MultiSelectNotifier(
                MultiSelectState(selectedAssets: {}, forceEnable: true, lockedSelectionAssets: {}),
              ),
            ),
            // Right now, only Immich assets are possible to add to album so use normal timeline
            // timelineServiceProvider.overrideWith((ref) {
            //   final timelineService = ref.watch(timelineFactoryProvider).fromAssets(assets);
            //   ref.onDispose(timelineService.dispose);
            //   return timelineService;
            // }),
          ],
          child: Consumer(
            builder: (context, ref, child) {
              return CupertinoPageScaffold(
                navigationBar: CupertinoNavigationBar(
                  backgroundColor: context.scaffoldBackgroundColor,
                  middle: const Text('create_album').t(),
                  leading: CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: Icon(CupertinoIcons.back),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                  trailing: CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: addButtonEnabled.value
                        ? () {
                            final selectedAssets = ref.read(multiSelectProvider).selectedAssets;
                            createAlbum(albumTitleController.value.text, selectedAssets, ref);
                            context.pop();
                          }
                        : null,
                    child: Icon(CupertinoIcons.add),
                  ),
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: DSInputField(
                        controller: albumTitleController,
                        placeholder: "Album name",
                        focusNode: albumTitleTextFieldFocusNode,
                        onTapOutside: (_) => albumTitleTextFieldFocusNode.unfocus(),
                        onSubmitted: (_) => albumTitleTextFieldFocusNode.unfocus(),
                        onEditingComplete: () => albumTitleTextFieldFocusNode.unfocus(),
                        onChanged: (final albumName) {
                          if (albumName.isNotEmpty) {
                            if (addButtonEnabled.value == false) {
                              addButtonEnabled.value = true;
                            }
                          } else {
                            if (addButtonEnabled.value) {
                              addButtonEnabled.value = false;
                            }
                          }
                        },
                      ),
                    ),
                    Expanded(
                      child: DSTimeline(key: const Key("create-album"), groupBy: GroupAssetsBy.none, appBar: null),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> createAlbum(String title, Set<BaseAsset> selectedAssets, WidgetRef ref) async {
    // This wont work, we can only create Albums with remote assets, so if an asset is local
    // we would first have to do the upload then sync?
    // This is likely why Immich does not allow this, they only show remote assets when building albums
    final album = await ref
        .watch(remoteAlbumProvider.notifier)
        .createAlbum(
          title: title,
          assetIds: selectedAssets.map((asset) {
            final remoteAsset = asset as RemoteAsset;
            return remoteAsset.id;
          }).toList(),
        );

    if (album != null) {
      ref.read(currentRemoteAlbumProvider.notifier).setAlbum(album);
    }
  }
}
