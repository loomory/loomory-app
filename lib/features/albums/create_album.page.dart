import 'package:auto_route/auto_route.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:immich_mobile/domain/models/timeline.model.dart';
import 'package:immich_mobile/extensions/build_context_extensions.dart';
import 'package:immich_mobile/extensions/translate_extensions.dart';
import 'package:immich_mobile/providers/infrastructure/timeline.provider.dart';
import 'package:immich_mobile/providers/timeline/multiselect.provider.dart';

import 'package:loomory/design_system/ds_input_field.dart';

import '../../design_system/ds_select_timeline.dart';
import '../../services/album_ext.service.dart';
import '../../repositories/local_assets.dart';
import '../../providers/album_ext.provider.dart';

@RoutePage()
class CreateAlbumPage extends HookConsumerWidget {
  const CreateAlbumPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final albumTitleController = useTextEditingController();
    final albumTitleTextFieldFocusNode = useFocusNode();
    final addButtonEnabled = useState(false);

    final allAssetsAsync = ref.watch(allAssetsProvider);
    return allAssetsAsync.when(
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
            // Use our local timeline that shows everything both remote and local assets
            timelineServiceProvider.overrideWith((ref) {
              final timelineService = ref.watch(timelineFactoryProvider).fromAssets(assets);
              ref.onDispose(timelineService.dispose);
              return timelineService;
            }),
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
                            ref
                                .read(albumExtProvider.notifier)
                                .createAlbum(albumTitleController.value.text, selectedAssets);

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
}
