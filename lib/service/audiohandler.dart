import 'dart:async';

import 'package:audio_service/audio_service.dart';
// import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';

import '../shared/helpers.dart';

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
  StreamSubscription? _subPlayState;
  StreamSubscription? _subCurrIndex;
  StreamSubscription? _subPlayEvent;

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
    _handlePlayStateChange();
    _handleCurrIndexChange();
    _handlePlayEventChange();
  }

  Future<void> dispose() async {
    await _subDuration?.cancel();
    await _subPlayState?.cancel();
    await _subCurrIndex?.cancel();
    await _subPlayEvent?.cancel();
    await _player.stop();
    await _player.dispose();
  }

  void _handleDurationChange() {
    _subDuration = _player.durationStream.listen((Duration? duration) {
      final index = _player.currentIndex;
      final sequence = _player.sequence;
      if (index != null && sequence != null && index < sequence.length) {
        final item = sequence[index].tag as MediaItem;
        mediaItem.add(item.copyWith(duration: duration));
      }
    });
  }

  void _handlePlayStateChange() {
    // subscribe to playerStateStream
    _subPlayState = _player.playerStateStream.listen((PlayerState state) async {
      logDebug('playerState: ${state.playing}  ${state.processingState}');
      if (state.processingState == ProcessingState.ready) {
        // about to start playing or just paused
      } else if (state.processingState == ProcessingState.completed) {
        // NOTE (playing, completed) may or MAY NOT be followed by (not playing, complted)
        if (state.playing && queue.value.isNotEmpty) {
          logDebug('handlePlayStateChange.end of the queue');
          await stop();
          // clear queue
          if (queue.value.isNotEmpty) {
            await clearQueue();
          }
        }
      }
    });
  }

  void _handleCurrIndexChange() {
    _subCurrIndex = _player.currentIndexStream.listen((int? index) {
      /*
      logDebug('handleCurIndex.index: $index');
      final sequence = _player.sequence;
      if (sequence != null) {
        // update the queue with the sequence
        queue.add(sequence.map((s) => s.tag as MediaItem).toList());
      }
      */
    });
  }

  void _handlePlayEventChange() {
    _subPlayEvent = _player.playbackEventStream.listen((PlaybackEvent event) {},
        onError: (Object e, StackTrace st) {
      if (e is PlatformException) {
        logError('PlatformException: ${e.code} ${e.message} ${e.details}');
      } else if (e is PlayerException) {
        logError('PlayerException: ${e.code} ${e.message} ${e.details}');
      } else {
        logError('Unknown Error: $e');
      }
      _showError();
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
  Duration get position => _player.position;
  Duration get duration => _player.duration ?? Duration.zero;
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  Stream<PlaybackEvent> get playbackEventStream => _player.playbackEventStream;

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
    // logDebug('playMediaItem: $mediaItem');
    // Note: we  handle only the section in the current book
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
    logDebug('skipToQueueItem: $index');
    final qval = queue.value;
    // validate index
    if (index >= 0 && index < qval.length) {
      // always start at the beginning of the chapter
      await _player.seek(Duration.zero, index: index);
      mediaItem.add(qval[index]);
    } else {
      // invalid index range => better to stop in this situation
      if (_player.playing) {
        logError('invalid index requested: stop');
        await stop();
      }
      // probably end of the queue
      if (index == qval.length) {
        logDebug('skipToQueueItem.end of the queue');
        // clear queue
        await clearQueue();
      }
    }
  }

  UriAudioSource _mediaItemToAudioSource(MediaItem mediaItem) =>
      AudioSource.uri(Uri.parse(mediaItem.id), tag: mediaItem);

  List<MediaItem> get _queueFromAudioSource =>
      _player.audioSource is ConcatenatingAudioSource
          ? (_player.audioSource as ConcatenatingAudioSource)
              .children
              .map((s) => (s as UriAudioSource).tag as MediaItem)
              .toList()
          : <MediaItem>[];

  @override
  Future<void> addQueueItems(List<MediaItem> mediaItems) async {
    // logDebug('addQueueItems: $mediaItems');
    await (_player.audioSource as ConcatenatingAudioSource)
        .addAll(mediaItems.map((m) => _mediaItemToAudioSource(m)).toList());
    // broadcast change
    final qval = queue.value..addAll(mediaItems);
    queue.add(qval);
  }

  Future<void> clearQueue() async {
    logDebug('===>handler.clearQueue currentIndex: ${_player.currentIndex}');
    // this may not work
    // await (_player.audioSource as ConcatenatingAudioSource).clear();
    // in such cases, use this
    await _player.setAudioSource(ConcatenatingAudioSource(children: []));
    queue.add([]);
    mediaItem.add(null);
    logDebug('<===handler.clearQueue currentIndex: ${_player.currentIndex}');
  }

  Future<void> setAudioSource(List<IndexedAudioSource> audioSources,
      {int initialIndex = 0, int initialPosition = 0}) async {
    // clear cache regardless of the source type
    // try {
    //   await AudioPlayer.clearAssetCache();
    // } catch (e) {
    //   logError(e.toString());
    // }

    await _player.setAudioSource(
      ConcatenatingAudioSource(children: audioSources),
      // preload: false,
      // initialIndex: sectionIdx,
      // initialPosition: initPosition,
    );

    queue.add(_queueFromAudioSource);

    // final mediaItems = audioSources.map((s) => s.tag as MediaItem).toList();
    // await setQueue(mediaItems);
    // skip to the section
    await skipToQueueItem(initialIndex);
    // seek position
    await seek(Duration(seconds: initialPosition));
  }

  void _showError() {
    // TODO: https://stackoverflow.com/questions/59787163/how-do-i-show-dialog-anywhere-in-the-app-without-context
    // showDialog(context: context, builder: builder);
  }
}
