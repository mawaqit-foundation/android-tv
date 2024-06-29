import 'dart:async';
import 'dart:developer';
import 'dart:math' show Random;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mawaqit/src/data/repository/quran/recite_impl.dart';
import 'package:mawaqit/src/domain/model/quran/audio_file_model.dart';
import 'package:mawaqit/src/domain/model/quran/moshaf_model.dart';
import 'package:mawaqit/src/domain/model/quran/surah_model.dart';
import 'package:mawaqit/src/state_management/quran/recite/quran_audio_player_state.dart';

import 'package:mawaqit/src/helpers/connectivity_provider.dart';

import '../../../models/address_model.dart';

class QuranAudioPlayer extends AsyncNotifier<QuranAudioPlayerState> {
  final AudioPlayer audioPlayer = AudioPlayer();
  late ConcatenatingAudioSource playlist;
  int index = 0;
  List<SurahModel> localSuwar = [];
  late StreamSubscription<int?> currentIndexSubscription;

  @override
  QuranAudioPlayerState build() {
    ref.onDispose(() {
      audioPlayer.dispose();
      currentIndexSubscription.cancel();
      log('quran: QuranAudioPlayer: disposed');
    });
    log('quran: QuranAudioPlayer: build');

    return QuranAudioPlayerState(
      playerState: AudioPlayerState.stopped,
      audioPlayer: audioPlayer,
      position: Duration.zero,
      reciterName: '',
      surahName: '',
      currentDownloadAudio: -1,
    );
  }

  void initialize({
    required MoshafModel moshaf,
    required SurahModel surah,
    required List<SurahModel> suwar,
    required String reciterId,
    required String riwayahId,
  }) async {
    log('quran: QuranAudioPlayer: play audio: ${surah.name}, url ${surah.getSurahUrl(moshaf.server)}');
    try {
      final audioRepository = await ref.read(reciteImplProvider.future);
      log('quran: QuranAudioPlayer: play download audio: ${suwar}');
      List<AudioSource> audioSources = [];

      for (var s in suwar) {
        bool isDownloaded = await audioRepository.isSurahDownloaded(
          reciterId: reciterId,
          riwayahId: riwayahId,
          surahNumber: s.id,
        );
        ref.read(connectivityProvider.notifier).checkInternetConnection();

        if (isDownloaded) {
          String localPath = await audioRepository.getLocalSurahPath(
            reciterId: reciterId,
            surahNumber: surah.id.toString(),
            riwayahId: riwayahId,
          );
          audioSources.add(AudioSource.uri(Uri.file(localPath)));
          log('quran: QuranAudioPlayer: isDownload: ${surah.name}, path: ${localPath}');
        } else if (ref.read(connectivityProvider).hasValue &&
            ref.read(connectivityProvider).value == ConnectivityStatus.connected) {
          audioSources.add(AudioSource.uri(Uri.parse(s.getSurahUrl(moshaf.server))));
          log('quran: QuranAudioPlayer: isDownload: ${surah.name}, url: ${s.getSurahUrl(moshaf.server)}');
        }
      }
      log('quran: QuranAudioPlayer: audio_source ${audioSources}');
      playlist = ConcatenatingAudioSource(
        children: audioSources,
      );
      index = suwar.indexOf(surah);
      localSuwar = suwar;
      await audioPlayer.setAudioSource(playlist, initialIndex: index);
      log('quran: QuranAudioPlayer: initialized ${surah.name}, url ${surah.getSurahUrl(moshaf.server)}');
      currentIndexSubscription = audioPlayer.currentIndexStream.listen((index) {
        log('quran: QuranAudioPlayer: currentIndexStream called');
        final index = audioPlayer.currentIndex ?? 0;
        state = AsyncData(
          state.value!.copyWith(
            surahName: localSuwar[index].name,
            playerState: AudioPlayerState.playing,
            reciterName: moshaf.name,
          ),
        );
      });
    } catch (e, s) {
      state = AsyncError(e, s);
    }
  }

  Future<void> play() async {
    state = AsyncData(
      state.value!.copyWith(
        playerState: AudioPlayerState.playing,
      ),
    );
    await audioPlayer.play();
  }

  Future<void> pause() async {
    state = AsyncData(
      state.value!.copyWith(
        playerState: AudioPlayerState.paused,
      ),
    );
    await audioPlayer.pause();
  }

  Future<void> stop() async {
    await audioPlayer.stop();
    state = AsyncData(
      state.value!.copyWith(
        playerState: AudioPlayerState.stopped,
      ),
    );
  }

  Future<void> seekTo(Duration position) async {
    try {
      await audioPlayer.seek(position);
      state = AsyncData(
        state.value!.copyWith(
          position: position,
        ),
      );
    } catch (e, s) {
      state = AsyncError(e, s);
    }
  }

  void dispose() {
    audioPlayer.dispose();
    state = AsyncData(
      state.value!.copyWith(
        playerState: AudioPlayerState.stopped,
      ),
    );
  }

  Future<void> seekToNext() async {
    try {
      if (audioPlayer.hasNext) {
        await audioPlayer.seekToNext();
        await _updatePlayerState();
        log('quran: QuranAudioPlayer: seekToNext called');
      }
    } catch (e, s) {
      log('quran: QuranAudioPlayer: seekToNext error: $e');
      state = AsyncError(e, s);
    }
  }

  Future<void> seekToPrevious() async {
    try {
      if (audioPlayer.hasPrevious) {
        await audioPlayer.seekToPrevious();
        await _updatePlayerState();
        log('quran: QuranAudioPlayer: seekToPrevious called');
      }
    } catch (e, s) {
      log('quran: QuranAudioPlayer: seekToPrevious error: $e');
      state = AsyncError(e, s);
    }
  }

  Future<void> _updatePlayerState() async {
    final index = audioPlayer.currentIndex ?? 0;
    final duration = audioPlayer.duration;
    final position = audioPlayer.position;

    state = AsyncData(
      state.value!.copyWith(
        surahName: localSuwar[index].name,
        playerState: audioPlayer.playing ? AudioPlayerState.playing : AudioPlayerState.paused,
        position: position,
      ),
    );
  }

  Future<void> shuffle() async {
    state = await AsyncValue.guard(() async {
      final bool isShuffled = !state.value!.isShuffled;
      await audioPlayer.setShuffleModeEnabled(isShuffled);
      return state.value!.copyWith(
        isShuffled: isShuffled,
      );
    });
  }

  Future<void> repeat() async {
    state = await AsyncValue.guard(() async {
      final isRepeating = !state.value!.isRepeating;
      if (isRepeating) {
        await audioPlayer.setLoopMode(LoopMode.one);
      } else {
        await audioPlayer.setLoopMode(LoopMode.off);
      }
      return state.value!.copyWith(
        isRepeating: isRepeating,
        downloadState: DownloadState.notDownloaded,
      );
    });
  }

  Future<void> downloadAudio({
    required String reciterId,
    required String riwayahId,
    required int surahId,
    required String url,
  }) async {
    final audioRepository = await ref.read(reciteImplProvider.future);
    final audioFileModel = AudioFileModel(
      reciterId,
      riwayahId,
      surahId.toString(),
      url,
    );

    state = AsyncData(
      state.value!.copyWith(
        downloadState: DownloadState.downloading,
        currentDownloadAudio: surahId,
      ),
    );

    try {
      final filePath = await audioRepository.downloadAudio(audioFileModel, (progress) {
        state = AsyncData(
          state.value!.copyWith(
            downloadProgress: progress.toInt(),
            downloadedIndex: surahId,
            downloadState: DownloadState.downloading,
          ),
        );
      });

      getDownloadedSurahByReciterAndRiwayah(
        riwayahId: riwayahId,
        reciterId: reciterId,
      );

      state = AsyncData(
        state.value!.copyWith(
          downloadedIndex: surahId,
          downloadState: DownloadState.downloaded,
          currentDownloadAudio: null,
        ),
      );
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }

  Future<void> getDownloadedSurahByReciterAndRiwayah({
    required String reciterId,
    required String riwayahId,
  }) async {
    final audioRepository = await ref.read(reciteImplProvider.future);
    state = AsyncLoading();
    state = await AsyncValue.guard(() async {
      final downloadedAudioList = await audioRepository.getDownloadedSurahByReciterAndRiwayah(
        reciterId: reciterId,
        riwayahId: riwayahId,
      );
      return state.value!.copyWith(
        downloadedAudio: downloadedAudioList,
      );
    });
  }

  Future<void> playLocalAudio({
    required String reciterId,
    required String riwayahId,
    required String surahId,
  }) async {
    final audioRepository = await ref.read(reciteImplProvider.future);
    final audioFileModel = AudioFileModel(
      reciterId,
      riwayahId,
      surahId,
      '',
    );

    state = AsyncLoading();
    try {
      final filePath = await audioRepository.getAudioPath(audioFileModel);
      await audioPlayer.setFilePath(filePath);
      await audioPlayer.play();

      state = AsyncData(
        state.value!.copyWith(
          downloadState: DownloadState.notDownloaded,
        ),
      );
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }

  Stream<Duration> get positionStream => audioPlayer.positionStream;
}

final quranPlayerNotifierProvider =
    AsyncNotifierProvider<QuranAudioPlayer, QuranAudioPlayerState>(QuranAudioPlayer.new);
