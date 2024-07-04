import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mawaqit/src/domain/model/quran/reciter_model.dart';

import 'package:mawaqit/src/const/constants.dart';
import 'package:mawaqit/src/module/dio_module.dart';

import 'package:mawaqit/src/domain/error/recite_exception.dart';

class ReciteRemoteDataSource {
  final Dio _dio;

  ReciteRemoteDataSource(this._dio);

  /// this is for getting the recitation types of each reciter
  Future<List<ReciterModel>> getReciters({
    required String language,
  }) async {
    try {
      final reciters = await _fetchReciters(
        language: language,
      );
      return reciters;
    } catch (e) {
      throw FetchRecitersBySurahException(e.toString());
    }
  }

  Future<List<ReciterModel>> _fetchReciters({
    required String language,
    int? reciterId,
    int? rewayaId,
    int? surahId,
    String? lastUpdatedDate,
  }) async {
    final response = await _dio.get(
      'reciters',
      queryParameters: {
        'language': language,
        if (reciterId != null) 'reciter': reciterId,
        if (rewayaId != null) 'rewaya': rewayaId,
        if (surahId != null) 'sura': surahId,
        if (lastUpdatedDate != null) 'last_updated_date': lastUpdatedDate,
      },
    );

    if (response.statusCode == 200) {
      final data = response.data;
      data['reciters'].forEach((reciter) {
        reciter['moshaf'].forEach((moshaf) {
          moshaf['surah_list'] = _convertSurahListToIntegers(moshaf['surah_list']);
        });
      });

      final reciters = List<ReciterModel>.from(data['reciters'].map((reciter) => ReciterModel.fromJson(reciter)));
      return reciters;
    } else {
      throw FetchRecitersFailedException('Failed to fetch reciters', 'FETCH_RECITERS_ERROR');
    }
  }

  static List<int> _convertSurahListToIntegers(String surahList) {
    return surahList.split(',').map(int.parse).toList();
  }
}

final reciteRemoteDataSourceProvider = Provider<ReciteRemoteDataSource>((ref) {
  final dio = ref.watch(
    dioProvider(
      DioProviderParameter(
        baseUrl: QuranConstant.kQuranBaseUrl,
        interceptor: LogInterceptor(
          requestBody: true,
          responseBody: true,
          logPrint: (l) => log('$l', name: 'API'),
        ),
      ),
    ),
  );
  return ReciteRemoteDataSource(dio.dio);
});
