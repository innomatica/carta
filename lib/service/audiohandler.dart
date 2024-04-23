import 'dart:async';
import 'dart:developer';

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
// import 'package:rxdart/rxdart.dart';

// import '../logic/cartabloc.dart';
// import '../model/cartabook.dart';
// import '../shared/helpers.dart';

const fastForwardInterval = Duration(seconds: 30);
const rewindInterval = Duration(seconds: 30);

Future<CartaAudioHandler> createAudioHandler() async {
  return await AudioService.init(
    builder: () => CartaAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.innomatic.carta.channel.audio',
      androidNotificationChannelName: 'Carta playback',
      androidNotificationOngoing: true,
      // this will keep the foreground on during pause
      // check: https://pub.dev/packages/audio_service
      // androidStopForegroundOnPause: false,
      androidStopForegroundOnPause: true,
      androidNotificationIcon: 'drawable/app_icon',
      fastForwardInterval: fastForwardInterval,
      rewindInterval: rewindInterval,
    ),
  );
}

// https://pub.dev/packages/audio_service
class CartaAudioHandler extends BaseAudioHandler
    with QueueHandler, SeekHandler {
  final _player = AudioPlayer();
  // late final CartaBloc _logic;
  StreamSubscription? _subDuration;
  StreamSubscription? _subPlyState;

  CartaAudioHandler() {
    _init();
  }

  Future<void> _init() async {
    // expose _player.playbackEvent stream as plabackState stream
    _player.playbackEventStream.map(_transformEvent).pipe(playbackState);
    // start with empty list of audio source
    await _player.setAudioSource(ConcatenatingAudioSource(children: []));
    queue.add([]);
    // stream subscriptions
    _handleDurationChange();
    _handlePlyStateChange();
  }

  Future<void> dispose() async {
    await _subDuration?.cancel();
    await _subPlyState?.cancel();
    await _player.stop();
    await _player.dispose();
  }

  void _handleDurationChange() {
    _subDuration = _player.durationStream.listen((Duration? duration) {
      final index = _player.currentIndex;
      final qval = queue.value;
      if (index != null && index >= 0 && index < qval.length) {
        final item = qval[index];
        // broadcast updated mediaItem
        mediaItem.add(item.copyWith(duration: duration));
      }
    });
  }

  void _handlePlyStateChange() {
    // subscribe to playerStateStream
    _subPlyState = _player.playerStateStream.listen((PlayerState state) async {
      // log('playerState: ${state.playing}  ${state.processingState}');
      if (state.processingState == ProcessingState.ready) {
        if (state.playing == false) {
          // about to start playing or paused
          final item = mediaItem.value;
          if (item != null) {
            // keep the current position
            item.extras!['seekPos'] = _player.position.inSeconds;
            // report change
            mediaItem.add(item);
          }
        }
      } else if (state.processingState == ProcessingState.completed) {
        // NOTE (playing, completed) may or MAY NOT be followed by (not playing, complted)
        if (state.playing) {
          // log('end of the queue');
          await pause();
          // clear queue
          if (queue.value.isNotEmpty) {
            await clearQueue();
          }
        }
      }
    });
  }

  // Transform a just_audio event into an audio_service state.
  // https://github.com/ryanheise/audio_service/blob/minor/audio_service/example/lib/main.dart
  PlaybackState _transformEvent(PlaybackEvent event) {
    return PlaybackState(
      controls: [
        MediaControl.rewind,
        if (_player.playing) MediaControl.pause else MediaControl.play,
        MediaControl.stop,
        MediaControl.fastForward,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 3],
      processingState: const {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[_player.processingState]!,
      playing: _player.playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: event.currentIndex,
    );
  }

  // expose player properties
  bool get playing => _player.playing;
  Duration get duration => _player.duration ?? Duration.zero;
  Duration get position => _player.position;
  Stream<Duration> get positionStream => _player.positionStream;

  // @override
  // Future<void> pause() async {
  //   log('handler.pause');
  //   await _updateBookmark();
  //   await _player.pause();
  // }
  // @override
  // Future<void> stop() async {
  //   log('handler.stop');
  //   await _updateBookmark();
  //   await _player.stop();
  // }

  @override
  Future<void> play() => _player.play();
  @override
  Future<void> pause() => _player.pause();
  @override
  Future<void> stop() => _player.stop();

  @override
  Future<void> setSpeed(double speed) => _player.setSpeed(speed);

  @override
  Future<void> playMediaItem(MediaItem mediaItem) async {
    // log('playMediaItem: $mediaItem');
    // assume that the audioSource is already set
    final audioSource = _player.audioSource as ConcatenatingAudioSource;
    // find the index of the item in the source list
    final index = audioSource.children
        .indexWhere((c) => (c as UriAudioSource).tag.id == mediaItem.id);
    // skip to the index
    await skipToQueueItem(index);
    _player.play();
  }

  // SeekHandler implements fastForward, rewind, seekForward, seekBackward
  @override
  Future<void> seek(Duration position) => _player.seek(position);

  // QueueHandler implements skipToNext, skipToPrevious
  @override
  Future<void> skipToQueueItem(int index) async {
    final sequence = _player.sequence;
    // validate index
    if (sequence != null) {
      if (sequence.isNotEmpty && index >= 0 && index < sequence.length) {
        // await _player.seek(Duration.zero, index: index);
      } else if (index == sequence.length) {
        if (_player.playing) {
          await stop();
        }
        // clear queue
        await clearQueue();
      }
    }
  }

  UriAudioSource _mediaItemToAudioSource(MediaItem mediaItem) =>
      AudioSource.uri(Uri.parse(mediaItem.id), tag: mediaItem);

  // @override
  // Future<void> addQueueItem(MediaItem mediaItem) async {
  // }

  @override
  Future<void> addQueueItems(List<MediaItem> mediaItems) async {
    (_player.audioSource as ConcatenatingAudioSource)
        .addAll(mediaItems.map((m) => _mediaItemToAudioSource(m)).toList());
    // broadcast change
    final qval = queue.value..addAll(mediaItems);
    queue.add(qval);
  }

  Future<void> clearQueue() async {
    final audioSource = _player.audioSource as ConcatenatingAudioSource;
    // then clear the queue
    await audioSource.clear();
    queue.add([]);
    mediaItem.add(null);
  }

  Future<void> setQueue(List<MediaItem> mediaItems) async {
    await clearQueue();
    await addQueueItems(mediaItems);
  }

  // Emit bookId and sectionIdx of currently playing book
  // Stream<PlayingBookState?> get playingBookStateStream {
  //   return Rx.combineLatest2<bool, SequenceState?, PlayingBookState?>(
  //     _player.playingStream,
  //     _player.sequenceStateStream,
  //     (isPlaying, sequenceState) {
  //       if (isPlaying && sequenceState?.currentSource?.tag != null) {
  //         final tag = sequenceState?.currentSource?.tag;
  //         return PlayingBookState(
  //           bookId: tag.extras['bookId'],
  //           sectionIdx: tag.extras['sectionIdx'],
  //         );
  //       }
  //       return null;
  //     },
  //   );
  // }

  // Check https://github.com/suragch/audio_video_progress_bar/
  // for the example
  // Stream<DurationState> get durationStateStream {
  //   return Rx.combineLatest2<Duration, PlaybackEvent, DurationState>(
  //     _player.positionStream,
  //     _player.playbackEventStream,
  //     (position, playbackEvent) => DurationState(
  //       progress: position,
  //       buffered: playbackEvent.bufferedPosition,
  //       total: playbackEvent.duration,
  //     ),
  //   );
  // }
}

// class DurationState {
//   final Duration progress;
//   final Duration buffered;
//   final Duration? total;

//   const DurationState({
//     required this.progress,
//     required this.buffered,
//     this.total,
//   });
// }

// class PlayingBookState {
//   final String bookId;
//   final int sectionIdx;

//   const PlayingBookState({
//     required this.bookId,
//     required this.sectionIdx,
//   });

//   @override
//   String toString() {
//     return {
//       "bookId": bookId,
//       "sectionIdx": sectionIdx,
//     }.toString();
//   }
// }
