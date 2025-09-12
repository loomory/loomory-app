import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:immich_mobile/domain/models/asset/base_asset.model.dart';
import 'package:immich_mobile/domain/models/timeline.model.dart';
import 'package:immich_mobile/providers/infrastructure/timeline.provider.dart';
import 'package:immich_mobile/providers/timeline/multiselect.provider.dart';

import 'repository/local_assets.dart';
import 'timeline/select_timeline.widget.dart';

// Create a provider for local-only assets using your existing repository
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
      data: (assets) => SafeArea(
        child: Scaffold(
          body: ProviderScope(
            overrides: [
              multiSelectProvider.overrideWith(
                () => MultiSelectNotifier(
                  MultiSelectState(selectedAssets: {}, forceEnable: true, lockedSelectionAssets: {}),
                ),
              ),
              timelineServiceProvider.overrideWith((ref) {
                final timelineService = ref.watch(timelineFactoryProvider).fromAssets(assets);
                ref.onDispose(timelineService.dispose);
                return timelineService;
              }),
            ],
            child: SelectTimeline(
              // TODO is this even needed, in create album we use the normal Timeline and it is ok?
              key: const Key("add-photos"),
              groupBy: GroupAssetsBy.none,
              appBar: null,
              //bottomSheet: null,
            ),
          ),
        ),
      ),
    );
  }
  // Widget build(BuildContext context, WidgetRef ref) {
  //   return ProviderScope(
  //     overrides: [
  //       multiSelectProvider.overrideWith(
  //         () => MultiSelectNotifier(MultiSelectState(selectedAssets: {}, forceEnable: true, lockedSelectionAssets: {})),
  //       ),
  //       timelineServiceProvider.overrideWith((ref) {
  //         final user = ref.watch(currentUserProvider);
  //         if (user == null) {
  //           throw Exception('User must be logged in to access asset selection timeline');
  //         }

  //         final timelineService = ref.watch(timelineFactoryProvider).remoteAssets(user.id);
  //         ref.onDispose(timelineService.dispose);
  //         return timelineService;
  //       }),
  //     ],
  //     child: const Timeline(),
  //   );
}
