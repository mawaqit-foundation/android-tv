import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mawaqit/i18n/l10n.dart';
import 'package:mawaqit/src/state_management/quran/quran/quran_notifier.dart';
import 'package:mawaqit/src/state_management/quran/reading/quran_reading_notifer.dart';
import 'package:sizer/sizer.dart';

void showSurahSelector(BuildContext context, int currentPage, ScrollController gridScrollController) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(
          S.of(context).surahSelector,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        content: Container(
          width: double.maxFinite,
          height: MediaQuery.of(context).size.height * 0.8,
          child: Consumer(
            builder: (context, ref, _) {
              final suwarState = ref.watch(quranReadingNotifierProvider);
              return suwarState.when(
                loading: () => Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text('Error: $err')),
                data: (quranState) {
                  final suwar = quranState.suwar;
                  return GridView.builder(
                    controller: gridScrollController,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      childAspectRatio: 2.5 / 1,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: suwar.length,
                    itemBuilder: (BuildContext context, int index) {
                      final surah = suwar[index];
                      final page = surah.startPage % 2 == 0 ? surah.startPage - 1 : surah.startPage;
                      return InkWell(
                        autofocus:  index == 0,
                        onTap: () {
                          ref.read(quranReadingNotifierProvider.notifier).updatePage(page);
                          Navigator.of(context).pop();
                        },
                        child: Container(
                          height: 40,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6.0),
                            border: Border.all(
                              color: Theme.of(context).dividerColor,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            "${surah.id}- ${surah.name}",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.normal,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      );
    },
  );
}
