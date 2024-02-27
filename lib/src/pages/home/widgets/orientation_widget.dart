import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mawaqit/src/services/app_update_manager.dart';
import 'package:mawaqit/src/services/user_preferences_manager.dart';
import 'package:provider/provider.dart';

abstract class StatelessOrientationWidget extends ConsumerStatefulWidget {
  const StatelessOrientationWidget({super.key});

  @override
  createState() => _StatelessOrientationWidgetState();

  Widget buildLandscape(BuildContext context);

  Widget buildPortrait(BuildContext context) => buildLandscape(context);
}

class _StatelessOrientationWidgetState extends ConsumerState<StatelessOrientationWidget> {
  @override
  void initState() {
    // ref.read(appUpdateManagerProvider.notifier).scheduleUpdate();
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    final userPrefs = context.watch<UserPreferencesManager>();

    if (userPrefs.calculatedOrientation == Orientation.portrait) {
      return widget.buildPortrait(context);
    } else {
      return widget.buildLandscape(context);
    }
  }
}

class OrientationWidget extends StatelessOrientationWidget {
  const OrientationWidget({
    Key? key,
    required this.landScapeBuilder,
    this.portraitBuilder,
  }) : super(key: key);

  final Widget Function(BuildContext context) landScapeBuilder;
  final Widget Function(BuildContext context)? portraitBuilder;

  @override
  Widget buildLandscape(BuildContext context) => landScapeBuilder(context);

  @override
  Widget buildPortrait(BuildContext context) => (portraitBuilder ?? landScapeBuilder)(context);
}
