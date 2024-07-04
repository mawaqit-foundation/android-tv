import 'dart:developer';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mawaqit/src/state_management/quran/quran/quran_state.dart';

import 'package:mawaqit/src/data/repository/quran/quran_impl.dart';

import 'package:mawaqit/src/module/shared_preference_module.dart';

import 'package:mawaqit/src/helpers/language_helper.dart';

import 'package:mawaqit/src/domain/model/quran/moshaf_model.dart';

class QuranNotifier extends AsyncNotifier<QuranState> {
  @override
  build() => QuranState();

  /// [getSuwarByLanguage] get the list of surwars by language
  ///
  /// [languageCode] is the language code of the surwars
  Future<void> getSuwarByLanguage({
    String languageCode = 'en',
  }) async {
    state = AsyncLoading();
    state = await AsyncValue.guard(() async {
      final quranRepository = await ref.read(quranRepositoryProvider.future);
      final sharedPreference = await ref.read(sharedPreferenceModule.future);
      final languageCode = sharedPreference.getString('language_code') ?? 'en';
      // return boolean if the languages has locale
      final mappedLanguage = LanguageHelper.mapLocaleWithQuran(languageCode);
      log('quran: QuranNotifier: getSuwarByLanguage: languageCode: $languageCode');
      final suwar = await quranRepository.getSuwarByLanguage(languageCode: mappedLanguage);
      return state.value!.copyWith(suwar: suwar);
    });
  }

  Future<void> getSuwarByReciter({
    String languageCode = 'en',
    required MoshafModel selectedMoshaf,
  }) async {
    state = AsyncLoading();
    state = await AsyncValue.guard(() async {
      final quranRepository = await ref.read(quranRepositoryProvider.future);
      final sharedPreference = await ref.read(sharedPreferenceModule.future);
      final languageCode = sharedPreference.getString('language_code') ?? 'en';
      // return boolean if the languages has locale
      final mappedLanguage = LanguageHelper.mapLocaleWithQuran(languageCode);
      final suwar = await quranRepository.getSuwarByLanguage(languageCode: mappedLanguage);
      final filteredSuwar = suwar.where((element) => selectedMoshaf.surahList.contains(element.id)).toList();
      return state.value!.copyWith(suwar: filteredSuwar);
    });
  }
}

final quranNotifierProvider = AsyncNotifierProvider<QuranNotifier, QuranState>(QuranNotifier.new);
