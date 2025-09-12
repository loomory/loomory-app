import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

// Placeholder route for the + sign in the bottom nav bar. Does nothing.
@RoutePage()
class PlaceholderPage extends ConsumerWidget {
  const PlaceholderPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container();
  }
}
