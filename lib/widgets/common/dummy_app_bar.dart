import 'package:flutter/material.dart';

// Dummy app bar we pass to timeline for now so the Immich one is not being displayed.
class DummySliverAppBar extends StatelessWidget {
  const DummySliverAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverAnimatedOpacity(duration: Durations.medium1, opacity: 0, sliver: SliverAppBar(toolbarHeight: 0));
  }
}
