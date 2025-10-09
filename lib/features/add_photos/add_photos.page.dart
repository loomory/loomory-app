import 'package:auto_route/auto_route.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:immich_mobile/constants/enums.dart';
import 'package:immich_mobile/domain/models/timeline.model.dart';
import 'package:immich_mobile/extensions/build_context_extensions.dart';
import 'package:immich_mobile/providers/infrastructure/action.provider.dart';
import 'package:immich_mobile/providers/infrastructure/timeline.provider.dart';
import 'package:immich_mobile/providers/timeline/multiselect.provider.dart';

import '../../design_system/ds_select_timeline.dart';
import '../../repositories/local_assets.dart';

@RoutePage()
class AddPhotosPage extends ConsumerWidget {
  const AddPhotosPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allAssetsAsync = ref.watch(allAssetsProvider);

    return allAssetsAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stack) => Scaffold(body: Center(child: Text('Error loading assets: $error'))),
      data: (assets) => ProviderScope(
        key: ValueKey(assets.length), // Force timeline recreation when asset count changes
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
