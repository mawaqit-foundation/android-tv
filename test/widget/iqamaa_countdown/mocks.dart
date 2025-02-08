import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:flutter_test/flutter_test.dart';
import 'package:mawaqit/i18n/AppLanguage.dart';
import 'package:mawaqit/src/models/announcement.dart';
import 'package:mawaqit/src/models/calendar/MawaqitHijriCalendar.dart';
import 'package:mawaqit/src/models/flash.dart';
import 'package:mawaqit/src/models/mosque.dart';
import 'package:mawaqit/src/models/mosqueConfig.dart';
import 'package:mawaqit/src/models/times.dart';
import 'package:mawaqit/src/services/mosque_manager.dart';
import 'package:mawaqit/src/services/user_preferences_manager.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart' as provider;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:sizer/sizer.dart';

/// Fake for Times: provides fixed prayer times and needed properties.
class FakeTimes extends Fake implements Times {
  @override
  List<String> dayTimesStrings(DateTime date, {bool salahOnly = true}) => [
    "00:00", // extra imsak time
    "05:00",
    "12:00",
    "15:00",
    "18:00",
    "20:00",
    "22:00",
  ];

  @override
  List<String> dayIqamaStrings(DateTime date) => [
    "05:10",
    "12:10",
    "15:10",
    "18:10",
    "20:10",
  ];

  @override
  bool get isTurki => false;

  @override
  int get imsakNbMinBeforeFajr => 10;

  @override
  int get hijriAdjustment => 0;

  @override
  String? get jumua => "12:00";

  // Add these missing getters:
  @override
  String? get jumua2 => "12:30";

  @override
  String? get jumua3 => "13:00";

  @override
  bool get jumuaAsDuhr => false;
}

/// Fake for MosqueConfig: provides fixed configuration values.
class FakeMosqueConfig extends Fake implements MosqueConfig {
  @override
  bool get iqamaMoreImportant => false;

  @override
  String get hadithLang => 'ar';

  @override
  String get timeDisplayFormat => '24'; // can be "12" if preferred

  @override
  List<String> get duaAfterPrayerShowTimes => ["10", "10", "10", "10", "10"];

  @override
  bool get iqamaEnabled => false;

  @override
  int get jumuaTimeout => 30;

  @override
  bool get duaAfterPrayerEnabled => false;
}

/// Mock for MosqueManager
class MockMosqueManager extends Mock implements MosqueManager {
  @override
  Mosque get mosque => FakeMosque();

  // Fixed test time: 2:30 PM on January 1, 2025.
  final fixedTime = DateTime(2025, 1, 1, 14, 30);
  final List<DateTime> _prayerTimes = [
    DateTime(2025, 1, 1, 5, 0), // Fajr
    DateTime(2025, 1, 1, 12, 0), // Dhuhr
    DateTime(2025, 1, 1, 15, 0), // Asr
    DateTime(2025, 1, 1, 18, 0), // Maghrib
    DateTime(2025, 1, 1, 20, 0), // Isha
  ];

  final List<DateTime> _iqamaTimes = [
    DateTime(2025, 1, 1, 5, 10),
    DateTime(2025, 1, 1, 12, 10),
    DateTime(2025, 1, 1, 15, 10),
    DateTime(2025, 1, 1, 18, 10),
    DateTime(2025, 1, 1, 20, 10),
  ];

  @override
  List<String> get salahNames => ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];

  @override
  String getSalahNameByIndex(int index, BuildContext context) => salahNames[index];

  @override
  bool isDisableHadithBetweenSalah() => false;

  @override
  bool adhanVoiceEnable([int? salahIndex]) => true;

  @override
  int get salahIndex => 2; // Using Asr

  @override
  bool get isImsakEnabled => true;

  @override
  bool get isShurukTime => false;

  @override
  String getShurukInString(BuildContext context) => "Shuruk in 01:30";

  @override
  String? getShurukTimeString([DateTime? date]) => "06:00";

  @override
  bool get typeIsMosque => true;

  @override
  bool isEidFirstDay(int? hijriAdjustment) => false;

  @override
  bool showEid(int? hijriAdjustment) => false;

  @override
  List<DateTime> actualTimes([DateTime? date]) => _prayerTimes;

  @override
  List<DateTime> actualIqamaTimes([DateTime? date]) => _iqamaTimes;

  @override
  int nextIqamaIndex() => 2;

  @override
  int nextSalahIndex() => 2;

  @override
  int nextSalahAfterIqamaIndex() => 2;

  @override
  Duration nextSalahAfter() => Duration(hours: 2, minutes: 30);

  @override
  Duration nextIqamaaAfter() => Duration(minutes: 15);

  @override
  Duration get currentSalahDuration => Duration(minutes: 10);

  @override
  String get imsak => "04:50";

  @override
  DateTime mosqueDate() => fixedTime;

  @override
  TimeOfDay mosqueTimeOfDay() => TimeOfDay.fromDateTime(fixedTime);

  @override
  bool get useTomorrowTimes => false;

  @override
  List<String> timesOfDay(DateTime date, {bool forceActualDuhr = false}) => [
        "05:00",
        "12:00",
        "15:00",
        "18:00",
        "20:00",
      ];

  @override
  List<String> get todayTimes => timesOfDay(fixedTime);

  @override
  List<String> get tomorrowTimes => timesOfDay(fixedTime.add(Duration(days: 1)));

  @override
  List<String> iqamasOfDay(DateTime date) => [
        "05:10",
        "12:10",
        "15:10",
        "18:10",
        "20:10",
      ];

  @override
  DateTime nextFridayDate([DateTime? now]) {
    now ??= fixedTime;
    return now.add(Duration(days: (DateTime.friday - now.weekday + 7) % 7));
  }

  @override
  DateTime activeJumuaaDate([DateTime? now]) => DateTime(2025, 1, 3, 12, 0);

  @override
  bool isJumuaOrJumua2EmptyOrNull() => false;

  @override
  bool isShortIqamaDuration(int salahIndex) => false;

  @override
  bool jumuaaWorkflowTime() => false;

  @override
  bool salahWorkflow() => false;

  @override
  List<Announcement> activeAnnouncements(bool enableVideos) => [];

  @override
  Color getColorTheme() => Colors.blue;
}

/// Mock for AppLanguage
class MockAppLanguage extends Mock implements AppLanguage {
  @override
  bool isArabic() => true;

  @override
  Locale get appLocal => const Locale('ar', ''); // Add this getter
}

/// Mock for UserPreferencesManager
class MockUserPreferencesManager extends Mock implements UserPreferencesManager {
  @override
  Orientation get calculatedOrientation => Orientation.landscape;

  @override
  void addListener(VoidCallback listener) {}

  @override
  void removeListener(VoidCallback listener) {}

  @override
  bool get hasListeners => false;
}

/// Setup method for platform channel mocks (if needed)
void setupPathProviderMocks() {
  const MethodChannel channel = MethodChannel('plugins.flutter.io/path_provider');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
    channel,
    (MethodCall call) async {
      if (call.method == 'getApplicationSupportDirectory') {
        return '/tmp';
      }
      return null;
    },
  );
}

Widget createWidgetForTesting({required Widget child}) {
  return Sizer(
    builder: (context, orientation, deviceType) {
      return MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: child,
      );
    },
  );
}

class FakeMosqueConfigWithDuaEnabled extends Fake implements MosqueConfig {
  @override
  bool get iqamaMoreImportant => false;

  @override
  String get hadithLang => 'ar';

  @override
  String get timeDisplayFormat => '24';

  @override
  List<String> get duaAfterPrayerShowTimes => ["10", "10", "10", "10", "10"];

  @override
  bool get iqamaEnabled => false;

  @override
  int get jumuaTimeout => 30;

  // This config returns true for duaAfterPrayerEnabled.
  @override
  bool get duaAfterPrayerEnabled => true;
}

class FakeMosqueConfigFullScreen extends Fake implements MosqueConfig {
  @override
  bool get iqamaFullScreenCountdown => true;

  @override
  bool get iqamaMoreImportant => false;

  @override
  String get hadithLang => 'ar';

  @override
  String get timeDisplayFormat => '24';

  @override
  List<String> get duaAfterPrayerShowTimes => ["10", "10", "10", "10", "10"];

  @override
  bool get iqamaEnabled => false;

  @override
  int get jumuaTimeout => 30;

  @override
  bool get duaAfterPrayerEnabled => false;

  // Add this getter to satisfy WeatherWidget requirements.
  @override
  String get temperatureUnit => '°C';
}

class FakeMosqueConfigNoFullScreen extends Fake implements MosqueConfig {
  @override
  bool get iqamaFullScreenCountdown => false;

  @override
  bool get iqamaMoreImportant => false;

  @override
  String get hadithLang => 'ar';

  @override
  String get timeDisplayFormat => '24';

  @override
  List<String> get duaAfterPrayerShowTimes => ["10", "10", "10", "10", "10"];

  @override
  bool get iqamaEnabled => false;

  @override
  int get jumuaTimeout => 30;

  @override
  bool get duaAfterPrayerEnabled => false;

  @override
  String get temperatureUnit => '°C';

  @override
  bool get showLogo => true;

  @override
  bool get temperatureEnabled => false;
}

class FakeMosque extends Fake implements Mosque {
  @override
  int get id => 1;

  @override
  String? get uuid => 'test-uuid';

  @override
  String get name => 'Test Mosque';

  @override
  String? get type => 'MOSQUE';

  @override
  String? get label => 'Test Label';

  @override
  String? get email => 'test@example.com';

  @override
  String? get phone => '0123456789';

  @override
  String? get url => 'https://example.com';

  @override
  String? get image => 'https://example.com/image.png';

  @override
  String? get logo => 'https://example.com/logo.png';

  @override
  String? get interiorPicture => 'https://example.com/interior.png';

  @override
  String? get exteriorPicture => 'https://example.com/exterior.png';

  @override
  String? get countryCode => 'EG';

  @override
  String? get site => 'Test Site';

  @override
  String? get association => 'Test Association';

  @override
  String? get localisation => 'Test Localisation';

  @override
  num? get longitude => 31.2357;

  @override
  num? get latitude => 30.0444;

  @override
  String? get closed => 'false';

  @override
  bool? get womenSpace => true;

  @override
  bool? get janazaPrayer => true;

  @override
  bool? get aidPrayer => true;

  @override
  bool? get childrenCourses => false;

  @override
  bool? get adultCourses => false;

  @override
  bool? get ramadanMeal => true;

  @override
  bool? get handicapAccessibility => true;

  @override
  bool? get ablutions => true;

  @override
  bool? get parking => true;

  @override
  String? get otherInfo => 'Additional Info';

  @override
  String? get flashMessage => 'Flash Message';

  @override
  Flash? get flash => null;

  @override
  String? get streamUrl => 'https://example.com/stream';

  @override
  List<Object?> get props => [id]; // Equatable: only id is used for equality.
}

class FakeMawaqitHijriCalendar extends Fake implements MawaqitHijriCalendar {
  @override
  int get islamicMonth => 1; // or any test value

  @override
  int get islamicDate => 1; // or any test value

// Add additional getters if necessary.
}
