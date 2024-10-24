import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mawaqit/i18n/l10n.dart';
import 'package:mawaqit/src/pages/quran/reading/widget/quran_floating_action_buttons.dart';
import 'package:mawaqit/src/pages/quran/widget/reading/quran_reading_widgets.dart';
import 'package:mawaqit/src/pages/quran/widget/reading/quran_surah_selector.dart';

import 'package:mawaqit/src/services/user_preferences_manager.dart';
import 'package:mawaqit/src/state_management/quran/download_quran/download_quran_notifier.dart';
import 'package:mawaqit/src/state_management/quran/download_quran/download_quran_state.dart';
import 'package:mawaqit/src/state_management/quran/reading/auto_reading/auto_reading_notifier.dart';
import 'package:mawaqit/src/state_management/quran/reading/auto_reading/auto_reading_state.dart';
import 'package:mawaqit/src/state_management/quran/reading/quran_reading_notifer.dart';

import 'package:mawaqit/src/pages/quran/widget/download_quran_popup.dart';
import 'package:mawaqit/src/state_management/quran/reading/quran_reading_state.dart';
import 'package:provider/provider.dart' as provider;

import 'package:sizer/sizer.dart';

import 'package:mawaqit/src/pages/quran/widget/reading/quran_reading_page_selector.dart';

class QuranReadingScreen extends ConsumerStatefulWidget {
  const QuranReadingScreen({super.key});

  @override
  ConsumerState createState() => _QuranReadingScreenState();
}

class _QuranReadingScreenState extends ConsumerState<QuranReadingScreen> {
  late FocusNode _rightSkipButtonFocusNode;
  late FocusNode _leftSkipButtonFocusNode;
  late FocusNode _backButtonFocusNode;
  late FocusNode _switchQuranFocusNode;
  late FocusNode _switchQuranModeNode;
  late FocusNode _switchScreenViewFocusNode;
  late FocusNode _switchToPlayQuranFocusNode;
  late FocusNode _portraitModeBackButtonFocusNode;
  late FocusNode _portraitModeSwitchQuranFocusNode;
  late FocusNode _portraitModePageSelectorFocusNode;
  final ScrollController _gridScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initializeFocusNodes();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      ref.read(downloadQuranNotifierProvider);
      ref.read(quranReadingNotifierProvider);
    });
  }

  void _initializeFocusNodes() {
    _rightSkipButtonFocusNode = FocusNode(debugLabel: 'right_skip_node');
    _leftSkipButtonFocusNode = FocusNode(debugLabel: 'left_skip_node');
    _backButtonFocusNode = FocusNode(debugLabel: 'back_button_node');
    _switchQuranFocusNode = FocusNode(debugLabel: 'switch_quran_node');
    _switchQuranModeNode = FocusNode(debugLabel: 'switch_quran_mode_node');
    _switchScreenViewFocusNode = FocusNode(debugLabel: 'switch_screen_view_node');
    _portraitModeBackButtonFocusNode = FocusNode(debugLabel: 'portrait_mode_back_button_node');
    _portraitModeSwitchQuranFocusNode = FocusNode(debugLabel: 'portrait_mode_switch_quran_node');
    _portraitModePageSelectorFocusNode = FocusNode(debugLabel: 'portrait_mode_page_selector_node');
    _switchToPlayQuranFocusNode = FocusNode(debugLabel: 'switch_to_play_quran_node');
  }

  final ValueNotifier<bool> _isRotated = ValueNotifier(false);

  @override
  void dispose() {
    _disposeFocusNodes();
    _isRotated.dispose();
    super.dispose();
  }

  void _disposeFocusNodes() {
    _leftSkipButtonFocusNode.dispose();
    _rightSkipButtonFocusNode.dispose();
    _backButtonFocusNode.dispose();
    _switchQuranFocusNode.dispose();
    _switchScreenViewFocusNode.dispose();
    _portraitModeBackButtonFocusNode.dispose();
    _portraitModeSwitchQuranFocusNode.dispose();
    _portraitModePageSelectorFocusNode.dispose();
    _switchToPlayQuranFocusNode.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final quranReadingState = ref.watch(quranReadingNotifierProvider);
    final userPrefs = context.watch<UserPreferencesManager>();
    ref.listen(downloadQuranNotifierProvider, (previous, next) async {
      if (!next.hasValue || next.value is Success) {
        ref.invalidate(quranReadingNotifierProvider);
      }

      // don't show dialog for them
      if (next.hasValue &&
          (next.value is NoUpdate ||
              next.value is CheckingDownloadedQuran ||
              next.value is CheckingUpdate ||
              next.value is CancelDownload)) {
        return;
      }

      if (previous!.hasValue && previous.value != next.value) {
        // Perform an action based on the new status
      }

      if (!_isThereCurrentDialogShowing(context)) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => DownloadQuranDialog(),
        );
      }
    });

    _leftSkipButtonFocusNode.onKeyEvent = (node, event) => _handleSwitcherFocusGroupNode(node, event);
    _rightSkipButtonFocusNode.onKeyEvent = (node, event) => _handleSwitcherFocusGroupNode(node, event);
    _switchScreenViewFocusNode.onKeyEvent =
        (node, event) => _handlePageScrollDownFocusGroupNode(node, event, _isRotated.value);
    _portraitModePageSelectorFocusNode.onKeyEvent =
        (node, event) => _handlePageScrollDownFocusGroupNode(node, event, _isRotated.value);
    _switchQuranModeNode.onKeyEvent =
        (node, event) => _handlePageScrollDownFocusGroupNode(node, event, _isRotated.value);
    _portraitModeBackButtonFocusNode.onKeyEvent =
        (node, event) => _handlePageScrollUpFocusGroupNode(node, event, _isRotated.value);
    _portraitModeSwitchQuranFocusNode.onKeyEvent =
        (node, event) => _handlePageScrollUpFocusGroupNode(node, event, _isRotated.value);

    final autoReadingState = ref.watch(autoScrollNotifierProvider);

    return WillPopScope(
        onWillPop: () async {
          userPrefs.orientationLandscape = true;
          return true;
        },
        child: ValueListenableBuilder<bool>(
          valueListenable: _isRotated,
          builder: (context, value, child) {
            return quranReadingState.when(
              data: (state) => RotatedBox(
                quarterTurns: state.isRotated ? -1 : 0,
                child: SizedBox(
                  width: MediaQuery.of(context).size.height,
                  height: MediaQuery.of(context).size.width,
                  child: Scaffold(
                    backgroundColor: Colors.white,
                    floatingActionButtonLocation: _getFloatingActionButtonLocation(context),
                    floatingActionButton: QuranFloatingActionControls(
                      switchScreenViewFocusNode: _switchScreenViewFocusNode,
                      switchQuranModeNode: _switchQuranModeNode,
                      switchToPlayQuranFocusNode: _switchToPlayQuranFocusNode,
                    ),
                    body: _buildBody(quranReadingState, state.isRotated, userPrefs, autoReadingState),
                  ),
                ),
              ),
              loading: () => const CircularProgressIndicator(),
              error: (error, stack) => const Icon(Icons.error),
            );
          },
        ));
  }

  Widget _buildBody(
    AsyncValue<QuranReadingState> quranReadingState,
    bool isPortrait,
    UserPreferencesManager userPrefs,
    AutoScrollState autoScrollState,
  ) {
    final color = Theme.of(context).primaryColor;
    return quranReadingState.when(
      loading: () => Center(
        child: CircularProgressIndicator(
          color: color,
        ),
      ),
      error: (error, s) {
        final errorLocalized = S.of(context).error;
        return Center(child: Text('$errorLocalized: $error'));
      },
      data: (quranReadingState) {
        return Stack(
          children: [
            autoScrollState.isSinglePageView
                ? buildAutoScrollView(quranReadingState, ref, autoScrollState)
                : isPortrait
                    ? buildVerticalPageView(quranReadingState, ref)
                    : buildHorizontalPageView(quranReadingState, ref, context),
            if (!isPortrait) ...[
              buildRightSwitchButton(
                context,
                _rightSkipButtonFocusNode,
                () => _scrollPageList(ScrollDirection.forward, isPortrait),
              ),
              buildLeftSwitchButton(
                context,
                _leftSkipButtonFocusNode,
                () => _scrollPageList(ScrollDirection.reverse, isPortrait),
              ),
            ],
            buildPageNumberIndicator(
                quranReadingState, isPortrait, context, _portraitModePageSelectorFocusNode, _showPageSelector),
            buildMoshafSelector(
                isPortrait,
                context,
                isPortrait ? _portraitModeSwitchQuranFocusNode : _switchQuranFocusNode,
                _isThereCurrentDialogShowing(context)),
            buildBackButton(
                isPortrait, userPrefs, context, isPortrait ? _portraitModeBackButtonFocusNode : _backButtonFocusNode),
            isPortrait ? SizedBox() : buildShowSurah(quranReadingState),
          ],
        );
      },
    );
  }

  Align buildShowSurah(QuranReadingState quranReadingState) {
    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: EdgeInsets.only(top: 0.3.h),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              ref.read(quranReadingNotifierProvider.notifier).getAllSuwarPage();
              showSurahSelector(context, quranReadingState.currentPage);
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.4),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                quranReadingState.currentSurahName,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 8.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildAutoScrollView(
    QuranReadingState quranReadingState,
    WidgetRef ref,
    AutoScrollState autoScrollState,
  ) {
    return ListView.builder(
      controller: autoScrollState.scrollController,
      itemCount: quranReadingState.totalPages,
      itemBuilder: (context, index) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final pageHeight =
                constraints.maxHeight.isInfinite ? MediaQuery.of(context).size.height : constraints.maxHeight;
            return Container(
              width: constraints.maxWidth,
              height: pageHeight,
              child: quranReadingState.svgs[index],
            );
          },
        );
      },
    );
  }

  void _scrollPageList(ScrollDirection direction, isPortrait) {
    if (direction == ScrollDirection.forward) {
      ref.read(quranReadingNotifierProvider.notifier).previousPage(isPortrait: isPortrait);
    } else {
      ref.read(quranReadingNotifierProvider.notifier).nextPage(isPortrait: isPortrait);
    }
  }

  void _showPageSelector(BuildContext context, int totalPages, int currentPage, bool switcherScreen) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return QuranReadingPageSelector(
          isPortrait: switcherScreen,
          currentPage: currentPage,
          scrollController: _gridScrollController,
          totalPages: totalPages,
        );
      },
    );
  }

  FloatingActionButtonLocation _getFloatingActionButtonLocation(BuildContext context) {
    final TextDirection textDirection = Directionality.of(context);
    switch (textDirection) {
      case TextDirection.ltr:
        return FloatingActionButtonLocation.endFloat;
      case TextDirection.rtl:
        return FloatingActionButtonLocation.startFloat;
      default:
        return FloatingActionButtonLocation.endFloat;
    }
  }

  KeyEventResult _handleSwitcherFocusGroupNode(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        _rightSkipButtonFocusNode.requestFocus();
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        _leftSkipButtonFocusNode.requestFocus();
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        _backButtonFocusNode.requestFocus();
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        _switchQuranFocusNode.requestFocus();
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  KeyEventResult _handlePageScrollDownFocusGroupNode(FocusNode node, KeyEvent event, bool isPortrait) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowDown && isPortrait) {
        _scrollPageList(ScrollDirection.reverse, isPortrait);
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  KeyEventResult _handlePageScrollUpFocusGroupNode(FocusNode node, KeyEvent event, bool isPortrait) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        _scrollPageList(ScrollDirection.forward, isPortrait);

        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  bool _isThereCurrentDialogShowing(BuildContext context) => ModalRoute.of(context)?.isCurrent != true;
}
