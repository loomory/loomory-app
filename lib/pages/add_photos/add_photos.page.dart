import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:immich_mobile/domain/models/timeline.model.dart';
import 'package:immich_mobile/presentation/widgets/memory/memory_lane.widget.dart';
import 'package:immich_mobile/presentation/widgets/timeline/timeline.widget.dart';
import 'package:immich_mobile/providers/infrastructure/memory.provider.dart';
import 'package:immich_mobile/providers/user.provider.dart';
import 'package:loomory/widgets/common/dummy_app_bar.dart';

@RoutePage()
class AddPhotosPage extends ConsumerWidget {
  const AddPhotosPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: Scaffold(
        body: Column(
          children: [
            ElevatedButton(
              onPressed: () => context.router.maybePop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue, // Change to desired color
              ),
              child: Text("back"),
            ),
            Expanded(
              child: Timeline(key: const Key("add-photos"), appBar: DummySliverAppBar(), groupBy: GroupAssetsBy.month),
            ),
          ],
        ),
      ),
    );
  }
}
