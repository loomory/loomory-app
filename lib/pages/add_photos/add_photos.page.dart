import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:immich_mobile/domain/models/timeline.model.dart';
import 'package:immich_mobile/presentation/widgets/timeline/timeline.widget.dart';

@RoutePage()
class AddPhotosPage extends ConsumerWidget {
  const AddPhotosPage({super.key});

  // check drift_search_page for example on overriding timeline provider, but we will still need a custom Timeline for main page
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
              child: Timeline(key: const Key("add-photos"), appBar: null, groupBy: GroupAssetsBy.none),
            ),
          ],
        ),
      ),
    );
  }
}
