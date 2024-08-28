import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mawaqit/src/data/data_source/quran/download_quran_remote_data_source.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mawaqit/src/const/constants.dart';
import 'package:mawaqit/src/domain/error/quran_exceptions.dart';
import 'package:mawaqit/src/helpers/quran_path_helper.dart';
import 'package:mawaqit/src/state_management/quran/reading/quran_reading_state.dart';
import 'package:mawaqit/src/helpers/directory_helper.dart';

class MockDio extends Mock implements Dio {}
class MockQuranPathHelper extends Mock implements QuranPathHelper {}
class MockResponse<T> extends Mock implements Response<T> {}
class MockDirectoryHelper extends Mock implements DirectoryHelper {}
class MockCancelToken extends Mock implements CancelToken {}

void main() {
  late DownloadQuranRemoteDataSource dataSource;
  late MockDio mockDio;
  late MockQuranPathHelper mockQuranPathHelper;
  late MockCancelToken mockCancelToken;

  setUp(() {
    mockDio = MockDio();
    mockQuranPathHelper = MockQuranPathHelper();
    mockCancelToken = MockCancelToken();
    dataSource = DownloadQuranRemoteDataSource(
      dio: mockDio,
      quranPathHelper: mockQuranPathHelper,
      cancelToken: mockCancelToken,
    );
  });

  group('DownloadQuranRemoteDataSource', ()
  {
    group('getRemoteQuranVersion', () {
      test('returns correct version for Hafs', () async {
        final mockResponse = MockResponse<Map<String, dynamic>>();
        when(() => mockResponse.data).thenReturn({'hafsfileName': 'hafs-v1.2.3.zip'});
        when(() => mockDio.get(QuranConstant.quranMoshafConfigJsonUrl))
            .thenAnswer((_) async => mockResponse);

        final result = await dataSource.getRemoteQuranVersion(moshafType: MoshafType.hafs);

        expect(result, '1.2.3');
        verify(() => mockDio.get(QuranConstant.quranMoshafConfigJsonUrl)).called(1);
      });

      test('returns correct version for Warsh', () async {
        final mockResponse = MockResponse<Map<String, dynamic>>();
        when(() => mockResponse.data).thenReturn({'warshFileName': 'warsh-v2.3.4.zip'});
        when(() => mockDio.get(QuranConstant.quranMoshafConfigJsonUrl))
            .thenAnswer((_) async => mockResponse);

        final result = await dataSource.getRemoteQuranVersion(moshafType: MoshafType.warsh);

        expect(result, '2.3.4');
        verify(() => mockDio.get(QuranConstant.quranMoshafConfigJsonUrl)).called(1);
      });

      test('throws FetchRemoteQuranVersionException on network error', () async {
        when(() => mockDio.get(QuranConstant.quranMoshafConfigJsonUrl))
            .thenThrow(DioException(requestOptions: RequestOptions(), type: DioExceptionType.connectionTimeout));

        expect(
              () => dataSource.getRemoteQuranVersion(moshafType: MoshafType.hafs),
          throwsA(isA<FetchRemoteQuranVersionException>()),
        );
      });

      test('throws FetchRemoteQuranVersionException on invalid response', () async {
        final mockResponse = MockResponse<Map<String, dynamic>>();
        when(() => mockResponse.data).thenReturn({'invalidKey': 'invalid-value'});
        when(() => mockDio.get(QuranConstant.quranMoshafConfigJsonUrl))
            .thenAnswer((_) async => mockResponse);

        expect(
              () => dataSource.getRemoteQuranVersion(moshafType: MoshafType.hafs),
          throwsA(isA<FetchRemoteQuranVersionException>()),
        );
      });
    });

    group('downloadQuranWithProgress', () {
      test('downloads file successfully', () async {
        const version = '1.2.3';
        const moshafType = MoshafType.hafs;
        final expectedUrl = '${QuranConstant.kQuranZipBaseUrl}hafs-v$version.zip';

        when(() => mockQuranPathHelper.getQuranZipFilePath(version))
            .thenReturn('/path/to/quran.zip');
        when(() => mockQuranPathHelper.quranDirectoryPath)
            .thenReturn('/path/to/quran');
        when(() =>
            mockDio.download(
              expectedUrl,
              '/path/to/quran.zip',
              onReceiveProgress: any(named: 'onReceiveProgress'),
              cancelToken: any(named: 'cancelToken'),
            )).thenAnswer((_) async => MockResponse());

        await dataSource.downloadQuranWithProgress(
          version: version,
          moshafType: moshafType,
        );

        verify(() =>
            mockDio.download(
              expectedUrl,
              '/path/to/quran.zip',
              onReceiveProgress: any(named: 'onReceiveProgress'),
              cancelToken: any(named: 'cancelToken'),
            )).called(1);
      });

      test('throws CancelDownloadException when cancelled', () async {
        const version = '1.2.3';
        const moshafType = MoshafType.hafs;

        when(() => mockQuranPathHelper.getQuranZipFilePath(version))
            .thenReturn('/path/to/quran.zip');
        when(() =>
            mockDio.download(
              any(),
              any(),
              onReceiveProgress: any(named: 'onReceiveProgress'),
              cancelToken: any(named: 'cancelToken'),
            )).thenThrow(DioException(
          type: DioExceptionType.cancel,
          requestOptions: RequestOptions(),
        ));
        when(() => mockQuranPathHelper.quranZipDirectoryPath)
            .thenReturn('/path/to/zip');
        when(() => mockQuranPathHelper.quranDirectoryPath)
            .thenReturn('/path/to/quran');

        expect(
              () =>
              dataSource.downloadQuranWithProgress(
                version: version,
                moshafType: moshafType,
              ),
          throwsA(isA<CancelDownloadException>()),
        );
      });

      test('throws UnknownException on unexpected error', () async {
        const version = '1.2.3';
        const moshafType = MoshafType.hafs;

        when(() => mockQuranPathHelper.getQuranZipFilePath(version))
            .thenReturn('/path/to/quran.zip');
        when(() =>
            mockDio.download(
              any(),
              any(),
              onReceiveProgress: any(named: 'onReceiveProgress'),
              cancelToken: any(named: 'cancelToken'),
            )).thenThrow(Exception('Unexpected error'));
        when(() => mockQuranPathHelper.quranZipDirectoryPath)
            .thenReturn('/path/to/zip');
        when(() => mockQuranPathHelper.quranDirectoryPath)
            .thenReturn('/path/to/quran');

        expect(
              () =>
              dataSource.downloadQuranWithProgress(
                version: version,
                moshafType: moshafType,
              ),
          throwsA(isA<UnknownException>()),
        );
      });

      test('calls onReceiveProgress with correct progress', () async {
        const version = '1.2.3';
        const moshafType = MoshafType.hafs;
        final expectedUrl = '${QuranConstant.kQuranZipBaseUrl}hafs-v$version.zip';
        double? lastReportedProgress;

        when(() => mockQuranPathHelper.getQuranZipFilePath(version))
            .thenReturn('/path/to/quran.zip');
        when(() => mockQuranPathHelper.quranDirectoryPath)
            .thenReturn('/path/to/quran');
        when(() =>
            mockDio.download(
              expectedUrl,
              '/path/to/quran.zip',
              onReceiveProgress: any(named: 'onReceiveProgress'),
              cancelToken: any(named: 'cancelToken'),
            )).thenAnswer((invocation) async {
          final onReceiveProgress = invocation.namedArguments[#onReceiveProgress] as Function(int, int)?;
          onReceiveProgress?.call(50, 100); // Simulate 50% progress
          return MockResponse();
        });

        await dataSource.downloadQuranWithProgress(
          version: version,
          moshafType: moshafType,
          onReceiveProgress: (progress) => lastReportedProgress = progress,
        );

        expect(lastReportedProgress, 50.0);
      });
    });

    test('cancelDownload cancels the current download', () {
      dataSource.cancelDownload();
      verify(() => mockCancelToken.cancel()).called(1);
    });
  });
}
