import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:music_player/music_player.dart';
import 'package:music_player/src/player/music_player.dart';

import 'internal/serialization.dart';

/// MusicPlayer for UI interaction.
class MusicPlayer extends Player {
  final log = Logger('MusicPlayer');

  static const _uiChannel = MethodChannel("tech.soit.quiet/player.ui");

  static MusicPlayer? _player;

  MusicPlayer._internal() : super() {
    _uiChannel.setMethodCallHandler(_handleRemoteCall);
    final Future<bool?> initResult = _uiChannel.invokeMethod("init");
    _initCompleter.complete(initResult);

    _queue.addListener(notifyListeners);
    _playMode.addListener(notifyListeners);
    _playbackState.addListener(notifyListeners);
    _metadata.addListener(notifyListeners);
  }

  factory MusicPlayer() {
    if (_player == null) {
      _player = MusicPlayer._internal();
    }
    return _player!;
  }

  void setPlayQueue(PlayQueue queue) {
    _uiChannel.invokeMethod("setPlayQueue", queue.toMap());
  }

  Future<MusicMetadata> getNextMusic(MusicMetadata anchor) async {
    final Map map = await _uiChannel.invokeMethod("getNext", anchor.toMap());
    return MusicMetadata.fromMap(map);
  }

  Future<MusicMetadata> getPreviousMusic(MusicMetadata metadata) async {
    final Map map =
        await _uiChannel.invokeMethod("getPrevious", metadata.toMap());
    return MusicMetadata.fromMap(map);
  }

  @override
  ValueListenable<PlayQueue> get queueListenable => _queue;

  @override
  ValueListenable<PlaybackState> get playbackStateListenable => _playbackState;

  @override
  ValueListenable<PlayMode> get playModeListenable => _playMode;

  @override
  ValueListenable<MusicMetadata?> get metadataListenable => _metadata;

  final ValueNotifier<PlayQueue> _queue = ValueNotifier(PlayQueue.empty());
  final ValueNotifier<PlaybackState> _playbackState =
      ValueNotifier(PlaybackState.none());
  final ValueNotifier<PlayMode> _playMode = ValueNotifier(PlayMode.sequence);
  final ValueNotifier<MusicMetadata?> _metadata = ValueNotifier(null);

  Future<dynamic> _handleRemoteCall(MethodCall call) async {
    log.fine("on MethodCall: ${call.method} args = ${call.arguments}");
    switch (call.method) {
      case 'onPlaybackStateChanged':
        _playbackState.value = createPlaybackState(call.arguments);
        break;
      case 'onMetadataChanged':
        _metadata.value = MusicMetadata.fromMap(call.arguments);
        break;
      case 'onPlayQueueChanged':
        _queue.value = PlayQueue.fromMap(call.arguments);
        break;
      case 'onPlayModeChanged':
        _playMode.value = PlayMode(call.arguments as int?);
        break;
      default:
        throw UnimplementedError();
    }
  }

  TransportControls transportControls = TransportControls(_uiChannel);

  Completer<bool?> _initCompleter = Completer();

  void insertToNext(MusicMetadata metadata) {
    _uiChannel.invokeMethod("insertToNext", metadata.toMap());
  }

  void playWithQueue(PlayQueue playQueue, {MusicMetadata? metadata}) {
    setPlayQueue(playQueue);
    if (playQueue.isEmpty) {
      return;
    }
    metadata = metadata ?? playQueue.queue.first;
    log.fine("playFromMediaId : ${metadata.mediaId}");
    transportControls.playFromMediaId(metadata.mediaId);
  }

  void removeMusicItem(MusicMetadata metadata) {}

  /// Check whether music service already running.
  Future<bool?> isMusicServiceAvailable() {
    return _initCompleter.future;
  }
}

class MusicPlayerValue {
  final PlayQueue queue;

  final PlayMode playMode;

  final PlaybackState playbackState;

  final MusicMetadata? metadata;

  MusicPlayerValue({
    required this.queue,
    this.playMode = PlayMode.sequence,
    this.metadata,
    this.playbackState = const PlaybackState.none(),
  });

  static final _empty = MusicPlayerValue(
    queue: PlayQueue.empty(),
    playMode: PlayMode.sequence,
    metadata: null,
    playbackState: PlaybackState.none(),
  );

  factory MusicPlayerValue.none() {
    return _empty;
  }
}
