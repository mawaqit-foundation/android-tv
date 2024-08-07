import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mawaqit/src/data/data_source/quran/recite_remote_data_source.dart';
import 'package:mawaqit/src/data/data_source/quran/reciter_local_data_source.dart';

import 'package:mawaqit/src/domain/model/quran/reciter_model.dart';

import 'package:mawaqit/src/domain/repository/quran/recite_repository.dart';

class ReciteImpl implements ReciteRepository {
  final ReciteRemoteDataSource _remoteDataSource;
  final ReciteLocalDataSource _localDataSource;

  ReciteImpl(this._remoteDataSource, this._localDataSource);

  @override
  Future<List<ReciterModel>> getRecitersBySurah({
    required int surahId,
    required String language,
  }) async {
    try {
      final reciters = await _remoteDataSource.getReciters(
        language: language,
      );
      await _localDataSource.saveRecitersBySurah(reciters, surahId);
      return _filterBySurahId(reciters, surahId);
    } catch (e) {
      final reciters = await _localDataSource.getReciterBySurah(surahId);
      return reciters ?? [];
    }
  }

  Future<List<ReciterModel>> getAllReciters({required String language}) async {
    try {
      final reciters = await _remoteDataSource.getReciters(
        language: language,
      );
      await _localDataSource.saveReciters(reciters);
      return reciters;
    } catch (e) {
      final reciters = await _localDataSource.getReciters();
      return reciters;
    }
  }

  /// there are multiple mushafs for each reciter and each mushaf has a list of surahs check if the surah is in the list of surahs
  List<ReciterModel> _filterBySurahId(List<ReciterModel> reciters, int surahId) {
    return reciters.where((reciter) {
      return reciter.moshaf.any((moshaf) {
        return moshaf.surahList.contains(surahId);
      });
    }).toList();
  }
}

final reciteImplProvider = FutureProvider<ReciteImpl>((ref) async {
  final remoteDataSource = ref.read(reciteRemoteDataSourceProvider);
  final localDataSource = await ref.read(reciteLocalDataSourceProvider.future);
  return ReciteImpl(remoteDataSource, localDataSource);
});
