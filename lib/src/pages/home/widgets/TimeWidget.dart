import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:intl/intl.dart';
import 'package:mawaqit/src/helpers/mawaqit_icons_icons.dart';
import 'package:mawaqit/src/services/mosque_manager.dart';
import 'package:mawaqit/src/themes/UIShadows.dart';
import 'package:provider/provider.dart';

class HomeTimeWidget extends StatefulWidget {
  const HomeTimeWidget({Key? key}) : super(key: key);

  @override
  State<HomeTimeWidget> createState() => _HomeTimeWidgetState();
}

class _HomeTimeWidgetState extends State<HomeTimeWidget> {
  // Future<void> openAzhanScreen(BuildContext context) async {
  //   await Navigator.push(
  //     context,
  //     AlertScreen(
  //       title: "Al Adan",
  //       subTitle: "الأذان",
  //       icon: Image.asset('assets/icon/adhan_icon.png'),
  //     ).buildRoute(),
  //   );
  //
  //   Navigator.push(context, AfterAdanHadith().buildRoute());
  // }
  //
  // void openIqamaaScreen(BuildContext context) {
  //   Navigator.push(
  //     context,
  //     MaterialPageRoute(
  //       builder: (context) => AlertScreen(
  //         title: "Al Iqama",
  //         subTitle: "الاقامه",
  //         duration: Duration(seconds: 5),
  //         icon: Image.asset('assets/icon/iqama_icon.png'),
  //       ),
  //     ),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    final mosqueManager = context.watch<MosqueManager>();

    return StreamBuilder(
      stream: Stream.periodic(Duration(seconds: 1)),
      builder: (context, snapShot) {
        final now = mosqueManager.mosqueDate();

        final nextSalahIndex = mosqueManager.nextSalahIndex();
        var nextSalahTime = mosqueManager.actualTimes()[nextSalahIndex].difference(now);

        // in case of fajr of the next day
        if (nextSalahTime < Duration.zero) {
          nextSalahTime = nextSalahTime + Duration(days: 1);
        }

        var hijriDate = HijriCalendar.fromDate(now.add(Duration(
          days: mosqueManager.times!.hijriAdjustment,
        )));

        if (mosqueManager.times!.hijriDateForceTo30) {
          hijriDate.hDay = 30;
        }

        return Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(.70),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                color: Color(0xb34e2b81),
                padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                child: Column(
                  children: [
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: DateFormat('HH:mm').format(now),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 50,
                              shadows: kHomeTextShadow,
                              letterSpacing: 1,
                            ),
                          ),
                          TextSpan(
                            text: ':${DateFormat('ss').format(now)}',
                            style: TextStyle(
                              color: Colors.white54,
                              fontWeight: FontWeight.bold,
                              fontSize: 50,
                              shadows: kHomeTextShadow,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 30,
                      child: AnimatedTextKit(
                        pause: Duration(seconds: 0),
                        isRepeatingAnimation: true,
                        repeatForever: true,
                        displayFullTextOnTap: true,
                        animatedTexts: [
                          FadeAnimatedText(
                            DateFormat("EEE, MMM dd, yyyy").format(mosqueManager.mosqueDate()),
                            duration: Duration(seconds: 6),
                            fadeInEnd: .1,
                            fadeOutBegin: .9,
                            textStyle: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              shadows: kHomeTextShadow,
                              letterSpacing: .5,
                            ),
                          ),
                          FadeAnimatedText(
                            hijriDate.format(
                              hijriDate.hYear,
                              hijriDate.hMonth,
                              hijriDate.hDay,
                              "dd MMMM yyyy",
                            ),
                            duration: Duration(seconds: 4),
                            fadeInEnd: .1,
                            fadeOutBegin: .9,
                            textStyle: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              shadows: kHomeTextShadow,
                              letterSpacing: .5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(MawaqitIcons.icon_adhan),
                    SizedBox(width: 10),
                    Text(
                      [
                        "${mosqueManager.salahName(mosqueManager.nextSalahIndex())} in ",
                        if (nextSalahTime.inMinutes > 0)
                          "${nextSalahTime.inHours.toString().padLeft(2, '0')}:${(nextSalahTime.inMinutes % 60).toString().padLeft(2, '0')} ",
                        if (nextSalahTime.inMinutes == 0)
                          "${(nextSalahTime.inSeconds % 60).toString().padLeft(2, '0')} Sec",
                      ].join(),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        height: 2,
                        shadows: kHomeTextShadow,
                      ),
                    ),
                    SizedBox(width: 10),
                    Icon(MawaqitIcons.icon_adhan),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// '12'.toint();
