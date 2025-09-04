import 'dart:math' as math;

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:immich_mobile/domain/models/timeline.model.dart';
import 'package:immich_mobile/presentation/widgets/timeline/timeline.widget.dart';
import 'package:immich_mobile/presentation/widgets/timeline/timeline.state.dart';
import 'package:immich_mobile/providers/infrastructure/timeline.provider.dart';
import 'package:immich_mobile/providers/timeline/multiselect.provider.dart';

import 'timeline/segment/select_segment_builder.dart';
import 'timeline/select_timeline.widget.dart';

@RoutePage()
class AddPhotosPage extends ConsumerWidget {
  const AddPhotosPage({super.key});

  // check drift_search_page for example on overriding timeline provider, but we will still need a custom Timeline for main page
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: Scaffold(
        body: ProviderScope(
          overrides: [
            multiSelectProvider.overrideWith(
              () => MultiSelectNotifier(
                MultiSelectState(selectedAssets: {}, forceEnable: true, lockedSelectionAssets: {}),
              ),
            ),
          ],
          child: SelectTimeline(
            key: const Key("add-photos"),
            groupBy: GroupAssetsBy.none,
            appBar: null,
            //bottomSheet: null,
          ),
        ),
      ),
    );
  }
}
