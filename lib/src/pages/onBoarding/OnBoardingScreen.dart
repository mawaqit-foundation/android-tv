import 'package:dots_indicator/dots_indicator.dart';
import 'package:flutter/material.dart';
import 'package:mawaqit/src/helpers/AppRouter.dart';
import 'package:mawaqit/src/helpers/SharedPref.dart';
import 'package:mawaqit/src/pages/home/OfflineHomeScreen.dart';
import 'package:mawaqit/src/pages/mosque_search/MosqueSearch.dart';
import 'package:mawaqit/src/pages/onBoarding/widgets/onboarding_language_selector.dart';
import 'package:mawaqit/src/pages/onBoarding/widgets/MawaqitAboutWidget.dart';
import 'package:mawaqit/src/pages/onBoarding/widgets/OrientationWidget.dart';
import 'package:mawaqit/src/pages/onBoarding/widgets/onboarding_announcement_mode.dart';
import 'package:mawaqit/src/services/mosque_manager.dart';
import 'package:mawaqit/src/widgets/InfoWidget.dart';
import 'package:mawaqit/src/widgets/ScreenWithAnimation.dart';
import 'package:mawaqit/src/widgets/mawaqit_icon_button.dart';
import 'package:provider/provider.dart';

import '../../../i18n/l10n.dart';
import '../../widgets/mawaqit_back_icon_button.dart';
import 'widgets/onboarding_screen_type.dart';

class OnBoardingItem {
  final String animation;
  final Widget? widget;
  final bool enableNextButton;
  final bool enablePreviousButton;
  final bool Function()? skip;

  OnBoardingItem({
    required this.animation,
    this.widget,
    this.enableNextButton = true,
    this.enablePreviousButton = true,

    /// if item is skipped, it will be marked as done
    this.skip,
  });
}

class OnBoardingScreen extends StatefulWidget {
  const OnBoardingScreen();

  @override
  _OnBoardingScreenState createState() => _OnBoardingScreenState();
}

class _OnBoardingScreenState extends State<OnBoardingScreen> {
  final sharedPref = SharedPref();
  int currentScreen = 0;

  onDone() {
    sharedPref.save('boarding', 'true');
    AppRouter.pushReplacement(OfflineHomeScreen());
  }

  nextPage(int nextScreen) {
    while (true) {
      /// this is the last screen
      if (nextScreen >= onBoardingItems.length) return onDone();

      currentScreen = nextScreen;
      // if false or null, don't skip this screen
      if (onBoardingItems[currentScreen].skip?.call() != true) break;

      nextScreen++;
    }

    setState(() {});
  }

  previousPage(int previousScreen) {
    while (true) {
      currentScreen = previousScreen;
      // if false or null, don't skip this screen
      if (onBoardingItems[currentScreen].skip?.call() != true) break;

      previousScreen--;
    }

    setState(() {});
  }

  late final onBoardingItems = [
    OnBoardingItem(
      animation: 'language',
      widget: OnBoardingLanguageSelector(onSelect: () => nextPage(1)),
      enablePreviousButton: false,
    ),
    OnBoardingItem(
      animation: 'welcome',
      widget: OnBoardingOrientationWidget(onSelect: () => nextPage(2)),
    ),
    OnBoardingItem(
      animation: 'welcome',
      widget: OnBoardingMawaqitAboutWidget(onNext: () => nextPage(3)),
    ),
    OnBoardingItem(
      animation: 'search',
      widget: MosqueSearch(onDone: () => nextPage(4)),
      enableNextButton: false,
      enablePreviousButton: false,
    ),

    /// main screen or secondary screen (if user has already selected a mosque)
    OnBoardingItem(
      animation: 'search',
      widget: OnBoardingScreenType(onDone: () => nextPage(5)),
      enableNextButton: false,
      enablePreviousButton: false,
      skip: () => !context.read<MosqueManager>().typeIsMosque,
    ),

    /// Allow user to select between regular mode or announcement mode
    OnBoardingItem(
      animation: 'search',
      widget: OnBoardingAnnouncementScreens(onDone: () => nextPage(6)),
      enableNextButton: false,
      enablePreviousButton: false,
      skip: () => !context.read<MosqueManager>().typeIsMosque,
    ),
  ];

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final activePage = onBoardingItems[currentScreen];

    return WillPopScope(
      onWillPop: () async {
        if (currentScreen == 0) return true;

        setState(() => currentScreen--);
        return false;
      },
      child: SafeArea(
        child: Scaffold(
          body: ScreenWithAnimationWidget(
            animation: activePage.animation,
            child: activePage.widget ?? SizedBox(),
          ),
          bottomNavigationBar: Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
            // height: 80,
            child: Row(
              children: [
                VersionWidget(
                  style: TextStyle(
                    color: Theme.of(context)
                        .textTheme
                        .bodyText1
                        ?.color
                        ?.withOpacity(.5),
                  ),
                ),
                Spacer(flex: 2),
                DotsIndicator(
                  dotsCount: onBoardingItems.length,
                  position: currentScreen,
                  decorator: DotsDecorator(
                    size: const Size.square(9.0),
                    activeSize: const Size(21.0, 9.0),
                    activeShape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5.0)),
                    spacing: EdgeInsets.all(3),
                  ),
                ),
                Spacer(),
                if (activePage.enablePreviousButton)
                  MawaqitBackIconButton(
                    icon: Icons.arrow_back_rounded,
                    label: S.of(context).previous,
                    onPressed: () => previousPage(currentScreen - 1),
                  ),
                if (activePage.enableNextButton)
                  MawaqitIconButton(
                    icon: Icons.arrow_forward_rounded,
                    label: S.of(context).next,
                    onPressed: () => nextPage(currentScreen + 1),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
