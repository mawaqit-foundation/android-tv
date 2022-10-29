import 'package:flutter/material.dart';
import 'package:mawaqit/const/resource.dart';
import 'package:mawaqit/generated/l10n.dart';

class AdhanSubScreen extends StatelessWidget {
  const AdhanSubScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Expanded(
          child: Center(
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 10, horizontal: 40),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: LinearGradient(
                  // transform: GradientRotation(pi / 2),
                  begin: Alignment(0, 0),
                  end: Alignment(0, 1),
                  colors: [
                    theme.primaryColor,
                    theme.primaryColor.withOpacity(0),
                  ],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    child: Text(
                      S.of(context).alAdhan,
                      style: theme.textTheme.displayMedium?.copyWith(fontWeight: FontWeight.w500),
                    ),
                  ),
                  Text(
                    "الأذان",
                    style: theme.textTheme.displaySmall,
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: Image.asset(R.ASSETS_ICON_ADHAN_ICON_PNG),
        ),
      ],
    );
  }
}
