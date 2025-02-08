import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mawaqit/i18n/AppLanguage.dart';
import 'package:mawaqit/i18n/l10n.dart';
import 'package:mawaqit/src/models/mosqueConfig.dart';
import 'package:mawaqit/src/pages/home/sub_screens/IqamaaCountDownSubScreen.dart';
import 'package:mawaqit/src/pages/home/sub_screens/normal_home.dart';
import 'package:mawaqit/src/services/mosque_manager.dart';
import 'package:mawaqit/src/services/user_preferences_manager.dart';
import 'package:mawaqit/src/helpers/RelativeSizes.dart';
import 'package:mawaqit/src/themes/UIShadows.dart';
import 'package:mawaqit/src/pages/home/widgets/WeatherWidget.dart';
import 'package:mawaqit/src/pages/home/widgets/offline_widget.dart';
import 'package:mawaqit/src/pages/home/widgets/salah_items/responsive_mini_salah_bar_widget.dart';
import 'package:mawaqit/src/pages/home/widgets/salah_items/responsive_mini_salah_bar_turkish_widget.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart' as provider;
import 'package:sizer/sizer.dart';

import 'mocks.dart';


/// A simple wrapper to help simulate a screen that ends when onDone is called.
class TestWrapper extends StatefulWidget {
  final Widget child;

  const TestWrapper({Key? key, required this.child}) : super(key: key);

  @override
  _TestWrapperState createState() => _TestWrapperState();
}

class _TestWrapperState extends State<TestWrapper> {
  bool finished = false;

  void finish() {
    setState(() {
      finished = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    // When finished, show an empty container with key 'finished'
    return finished ? Container(key: const Key('finished')) : widget.child;
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  TestWidgetsFlutterBinding.ensureInitialized();

  group('IqamaaCountDownSubScreen Tests', () {
    late MockMosqueManager mockMosqueManager;
    late MockAppLanguage mockAppLanguage;
    late MockUserPreferencesManager mockUserPreferencesManager;

    setUp(() {
      // Create new mock instances for every test.
      mockMosqueManager = MockMosqueManager();
      mockAppLanguage = MockAppLanguage();
      mockUserPreferencesManager = MockUserPreferencesManager();

      // Default behaviors for the mocks.
      when(() => mockMosqueManager.times).thenReturn(FakeTimes());

      when(()=> mockUserPreferencesManager.hijriAdjustments).thenReturn(0);
      registerFallbackValue(FakeMawaqitHijriCalendar());
    });

    testWidgets('When iqamaFullScreenCountdown is false, IqamaaCountDownSubScreen returns NormalHomeSubScreen',
        (WidgetTester tester) async {
      // Set mosque config to not show full screen countdown.
      when(() => mockMosqueManager.mosqueConfig).thenReturn(FakeMosqueConfigNoFullScreen());
      when(() => mockMosqueManager.times).thenReturn(FakeTimes());

      await tester.binding.setSurfaceSize(const Size(800, 600)); // Add this line

      await tester.pumpWidget(
        riverpod.ProviderScope(
          child: provider.MultiProvider(
            providers: [
              provider.ChangeNotifierProvider<MosqueManager>.value(value: mockMosqueManager),
              provider.ChangeNotifierProvider<AppLanguage>.value(value: mockAppLanguage),
              provider.ChangeNotifierProvider<UserPreferencesManager>.value(value: mockUserPreferencesManager),
            ],
            child: MaterialApp(
              home: SizedBox(
                width: 800,
                height: 600,
                child: createWidgetForTesting(child: const IqamaaCountDownSubScreen()),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      // Expect that NormalHomeSubScreen is displayed instead.
      expect(find.byType(NormalHomeSubScreen), findsOneWidget);
    });

    testWidgets('IqamaaCountDownSubScreen displays countdown and calls onDone', (WidgetTester tester) async {
      // Set mosque config to show full screen countdown.
      when(() => mockMosqueManager.mosqueConfig).thenReturn(FakeMosqueConfigFullScreen());

      bool onDoneCalled = false;

      // Use TestWrapper to capture the onDone callback.
      final testWrapperKey = GlobalKey<_TestWrapperState>();

      final testWidget = TestWrapper(
        key: testWrapperKey,
        child: IqamaaCountDownSubScreen(
          onDone: () {
            onDoneCalled = true;
            testWrapperKey.currentState?.finish();
          },
          // currentSalahIndex defaults to 0
        ),
      );

      await tester.pumpWidget(
        riverpod.ProviderScope(
          child: provider.MultiProvider(
            providers: [
              provider.ChangeNotifierProvider<MosqueManager>.value(value: mockMosqueManager),
              provider.ChangeNotifierProvider<AppLanguage>.value(value: mockAppLanguage),
              provider.ChangeNotifierProvider<UserPreferencesManager>.value(value: mockUserPreferencesManager),
            ],
            child: createWidgetForTesting(child: testWidget),
          ),
        ),
      );

      // Initially, we expect the countdown text (with tr.iqamaIn) to be present.
      expect(find.textContaining('iqama'), findsOneWidget);

      // Pump enough time for the onDone callback to be called.
      await tester.pump(Duration(seconds: 2));
      await tester.pumpAndSettle();

      expect(onDoneCalled, isTrue);
      // The TestWrapper should now display the finished container.
      expect(find.byKey(const Key('finished')), findsOneWidget);
    });
  });
}
