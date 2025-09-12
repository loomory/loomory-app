import 'package:auto_route/auto_route.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:immich_mobile/constants/enums.dart';
import 'package:immich_mobile/domain/models/asset/base_asset.model.dart';
import 'package:immich_mobile/domain/models/timeline.model.dart';
import 'package:immich_mobile/extensions/build_context_extensions.dart';
import 'package:immich_mobile/providers/infrastructure/action.provider.dart';
import 'package:immich_mobile/providers/infrastructure/timeline.provider.dart';
import 'package:immich_mobile/providers/timeline/multiselect.provider.dart';

import '../../design_system/ds_select_timeline.dart';
import 'repository/local_assets.dart';

// Provider for local-only assets i.e. photos on device not added yet.
final localOnlyAssetsProvider = FutureProvider<List<BaseAsset>>((ref) async {
  final repository = ref.watch(localAssetRepository);
  final localAssets = await repository.getLocalOnlyAssets();
  return localAssets.cast<BaseAsset>();
});

@RoutePage()
class AddPhotosPage extends ConsumerWidget {
  const AddPhotosPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localAssetsAsync = ref.watch(localOnlyAssetsProvider);

    return localAssetsAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stack) => Scaffold(body: Center(child: Text('Error loading assets: $error'))),
      data: (assets) => ProviderScope(
        overrides: [
          multiSelectProvider.overrideWith(
            () =>
                MultiSelectNotifier(MultiSelectState(selectedAssets: {}, forceEnable: true, lockedSelectionAssets: {})),
          ),
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
                middle: Text("${ref.watch(multiSelectProvider).selectedAssets.length}"),
                leading: CupertinoButton(
                  padding: EdgeInsets.zero,
                  child: Icon(CupertinoIcons.back),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
                trailing: CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: ref.watch(multiSelectProvider).selectedAssets.isNotEmpty
                      ? () async {
                          await ref.read(actionProvider.notifier).upload(ActionSource.timeline);
                          ref.read(multiSelectProvider.notifier).reset();
                          context.pop();
                        }
                      : null,
                  child: Icon(CupertinoIcons.add),
                ),
              ),
              child: DSTimeline(key: const Key("create-album"), groupBy: GroupAssetsBy.none, appBar: null),
            );
          },
        ),
      ),
    );
  }
}
