import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import '../constants/app_constants.dart';

class AudioManager {
  static final AudioManager _instance = AudioManager._internal();
  factory AudioManager() => _instance;
  AudioManager._internal();

  static AudioPlayer? _audioPlayer;
  static bool _isPlaying = false;
  static bool _isPaused = false;
  static String? _currentAudioUrl;
  static Duration _currentPosition = Duration.zero;
  static Duration _totalDuration = Duration.zero;
  static double _volume = 1.0;
  static double _playbackSpeed = 1.0;

  // Stream controllers for reactive updates
  static final StreamController<bool> _playingStateController =
  StreamController<bool>.broadcast();
  static final StreamController<Duration> _positionController =
  StreamController<Duration>.broadcast();
  static final StreamController<Duration> _durationController =
  StreamController<Duration>.broadcast();
  static final StreamController<String?> _urlController =
  StreamController<String?>.broadcast();
  static final StreamController<PlayerState> _playerStateController =
  StreamController<PlayerState>.broadcast();

  // Getters
  static bool get isPlaying => _isPlaying;
  static bool get isPaused => _isPaused;
  static String? get currentAudioUrl => _currentAudioUrl;
  static Duration get currentPosition => _currentPosition;
  static Duration get totalDuration => _totalDuration;
  static double get volume => _volume;
  static double get playbackSpeed => _playbackSpeed;

  // Streams
  static Stream<bool> get playingStateStream => _playingStateController.stream;
  static Stream<Duration> get positionStream => _positionController.stream;
  static Stream<Duration> get durationStream => _durationController.stream;
  static Stream<String?> get urlStream => _urlController.stream;
  static Stream<PlayerState> get playerStateStream => _playerStateController.stream;

  /// AudioPlayer'ı başlat
  static Future<void> _initializePlayer() async {
    if (_audioPlayer == null) {
      _audioPlayer = AudioPlayer();
      _setupPlayerListeners();
    }
  }

  /// Player event listener'larını ayarla
  static void _setupPlayerListeners() {
    if (_audioPlayer == null) return;

    // Player state changes
    _audioPlayer!.onPlayerStateChanged.listen((state) {
      _playerStateController.add(state);

      switch (state) {
        case PlayerState.playing:
          _isPlaying = true;
          _isPaused = false;
          break;
        case PlayerState.paused:
          _isPlaying = false;
          _isPaused = true;
          break;
        case PlayerState.stopped:
        case PlayerState.completed:
          _isPlaying = false;
          _isPaused = false;
          _currentAudioUrl = null;
          _currentPosition = Duration.zero;
          _urlController.add(null);
          break;
        default:
          break;
      }

      _playingStateController.add(_isPlaying);
    });

    // Position changes
    _audioPlayer!.onPositionChanged.listen((position) {
      _currentPosition = position;
      _positionController.add(position);
    });

    // Duration changes
    _audioPlayer!.onDurationChanged.listen((duration) {
      _totalDuration = duration;
      _durationController.add(duration);
    });
  }

  /// Ses dosyasını oynat
  static Future<void> playAudio(
      String audioUrl,
      VoidCallback? onComplete, {
        bool autoPlay = true,
        double? startPosition,
      }) async {
    try {
      await _initializePlayer();

      // Eğer aynı ses çalınıyorsa ve sadece pause durumundaysa resume et
      if (_currentAudioUrl == audioUrl && _isPaused) {
        await resumeAudio();
        return;
      }

      // Eğer aynı ses çalınıyorsa durdur
      if (_isPlaying && _currentAudioUrl == audioUrl) {
        await pauseAudio();
        return;
      }

      // Önceki sesi durdur
      if (_isPlaying) {
        await stopAudio();
      }

      _currentAudioUrl = audioUrl;
      _urlController.add(audioUrl);

      if (autoPlay) {
        await _audioPlayer!.play(UrlSource(audioUrl));

        if (startPosition != null) {
          await _audioPlayer!.seek(Duration(seconds: startPosition.toInt()));
        }
      } else {
        await _audioPlayer!.setSource(UrlSource(audioUrl));
      }

      // Completion callback'i ayarla
      if (onComplete != null) {
        _audioPlayer!.onPlayerStateChanged.listen((state) {
          if (state == PlayerState.completed) {
            onComplete();
          }
        });
      }

    } catch (e) {
      debugPrint('Audio playback error: $e');
      _handlePlaybackError(e);
    }
  }

  /// Ses oynatmayı duraklat
  static Future<void> pauseAudio() async {
    try {
      if (_audioPlayer != null && _isPlaying) {
        await _audioPlayer!.pause();
      }
    } catch (e) {
      debugPrint('Audio pause error: $e');
    }
  }

  /// Ses oynatmaya devam et
  static Future<void> resumeAudio() async {
    try {
      if (_audioPlayer != null && _isPaused) {
        await _audioPlayer!.resume();
      }
    } catch (e) {
      debugPrint('Audio resume error: $e');
    }
  }

  /// Ses oynatmayı durdur
  static Future<void> stopAudio() async {
    try {
      if (_audioPlayer != null) {
        await _audioPlayer!.stop();
        _isPlaying = false;
        _isPaused = false;
        _currentAudioUrl = null;
        _currentPosition = Duration.zero;
        _playingStateController.add(false);
        _urlController.add(null);
      }
    } catch (e) {
      debugPrint('Audio stop error: $e');
    }
  }

  /// Belirli bir pozisyona git
  static Future<void> seekTo(Duration position) async {
    try {
      if (_audioPlayer != null) {
        await _audioPlayer!.seek(position);
      }
    } catch (e) {
      debugPrint('Audio seek error: $e');
    }
  }

  /// Ses seviyesini ayarla (0.0 - 1.0)
  static Future<void> setVolume(double volume) async {
    try {
      if (_audioPlayer != null && volume >= 0.0 && volume <= 1.0) {
        _volume = volume;
        await _audioPlayer!.setVolume(volume);
      }
    } catch (e) {
      debugPrint('Audio volume error: $e');
    }
  }

  /// Oynatma hızını ayarla (0.5 - 2.0)
  static Future<void> setPlaybackSpeed(double speed) async {
    try {
      if (_audioPlayer != null && speed >= 0.5 && speed <= 2.0) {
        _playbackSpeed = speed;
        await _audioPlayer!.setPlaybackRate(speed);
      }
    } catch (e) {
      debugPrint('Audio playback speed error: $e');
    }
  }

  /// Geri sar (10 saniye)
  static Future<void> seekBackward({int seconds = 10}) async {
    final newPosition = _currentPosition - Duration(seconds: seconds);
    final targetPosition = newPosition < Duration.zero ? Duration.zero : newPosition;
    await seekTo(targetPosition);
  }

  /// İleri sar (10 saniye)
  static Future<void> seekForward({int seconds = 10}) async {
    final newPosition = _currentPosition + Duration(seconds: seconds);
    final targetPosition = newPosition > _totalDuration ? _totalDuration : newPosition;
    await seekTo(targetPosition);
  }

  /// Oynatma durumunu toggle et
  static Future<void> togglePlayback() async {
    if (_isPlaying) {
      await pauseAudio();
    } else if (_isPaused) {
      await resumeAudio();
    }
  }

  /// Progress yüzdesi al (0.0 - 1.0)
  static double get progress {
    if (_totalDuration.inMilliseconds <= 0) return 0.0;
    return _currentPosition.inMilliseconds / _totalDuration.inMilliseconds;
  }

  /// Kalan süreyi al
  static Duration get remainingTime {
    return _totalDuration - _currentPosition;
  }

  /// Formatlanmış pozisyon string'i
  static String get formattedPosition {
    return _formatDuration(_currentPosition);
  }

  /// Formatlanmış toplam süre string'i
  static String get formattedDuration {
    return _formatDuration(_totalDuration);
  }

  /// Formatlanmış kalan süre string'i
  static String get formattedRemainingTime {
    return _formatDuration(remainingTime);
  }

  /// Duration'ı formatla (mm:ss)
  static String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Oynatma hatasını ele al
  static void _handlePlaybackError(dynamic error) {
    _isPlaying = false;
    _isPaused = false;
    _currentAudioUrl = null;
    _playingStateController.add(false);
    _urlController.add(null);

    // Error handling burada genişletilebilir
    debugPrint('Playback error handled: $error');
  }

  /// Audio buffer'ını temizle
  static Future<void> clearBuffer() async {
    try {
      if (_audioPlayer != null) {
        await _audioPlayer!.stop();
        await _audioPlayer!.dispose();
        _audioPlayer = null;
        await _initializePlayer();
      }
    } catch (e) {
      debugPrint('Clear buffer error: $e');
    }
  }

  /// Player'ı sıfırla
  static Future<void> reset() async {
    try {
      await stopAudio();
      _currentPosition = Duration.zero;
      _totalDuration = Duration.zero;
      _volume = 1.0;
      _playbackSpeed = 1.0;
      _positionController.add(Duration.zero);
      _durationController.add(Duration.zero);
    } catch (e) {
      debugPrint('Reset error: $e');
    }
  }

  /// Fade in ile ses başlat
  static Future<void> fadeIn({
    required String audioUrl,
    Duration fadeDuration = const Duration(seconds: 2),
    VoidCallback? onComplete,
  }) async {
    await setVolume(0.0);
    await playAudio(audioUrl, onComplete, autoPlay: true);

    // Gradual volume increase
    const steps = 20;
    const stepDuration = Duration(milliseconds: 100);

    for (int i = 1; i <= steps; i++) {
      await Future.delayed(stepDuration);
      await setVolume(i / steps);
    }
  }

  /// Fade out ile ses bitir
  static Future<void> fadeOut({
    Duration fadeDuration = const Duration(seconds: 2),
  }) async {
    if (!_isPlaying) return;

    const steps = 20;
    const stepDuration = Duration(milliseconds: 100);

    for (int i = steps; i >= 0; i--) {
      await Future.delayed(stepDuration);
      await setVolume(i / steps);
    }

    await stopAudio();
    await setVolume(1.0); // Reset volume
  }

  /// Playlist desteği için birden fazla URL oynat
  static Future<void> playPlaylist(
      List<String> audioUrls, {
        int startIndex = 0,
        bool loop = false,
        VoidCallback? onPlaylistComplete,
      }) async {
    if (audioUrls.isEmpty || startIndex >= audioUrls.length) return;

    int currentIndex = startIndex;

    Future<void> playNext() async {
      if (currentIndex < audioUrls.length) {
        await playAudio(
          audioUrls[currentIndex],
              () {
            currentIndex++;
            if (currentIndex >= audioUrls.length) {
              if (loop) {
                currentIndex = 0;
                playNext();
              } else {
                onPlaylistComplete?.call();
              }
            } else {
              playNext();
            }
          },
        );
      }
    }

    await playNext();
  }

  /// Audio çalmaya hazır mı kontrol et
  static bool get isReadyToPlay {
    return _audioPlayer != null;
  }

  /// Mevcut audio URL'sinin geçerli olup olmadığını kontrol et
  static Future<bool> validateCurrentUrl() async {
    if (_currentAudioUrl == null) return false;

    try {
      // Burada URL validation logic'i yazılabilir
      // Örneğin HTTP HEAD request ile kontrol
      return true;
    } catch (e) {
      return false;
    }
  }

  /// AudioManager'ı temizle ve kaynakları serbest bırak
  static Future<void> dispose() async {
    try {
      await _audioPlayer?.dispose();
      _audioPlayer = null;

      // Stream controller'ları kapat
      if (!_playingStateController.isClosed) {
        await _playingStateController.close();
      }
      if (!_positionController.isClosed) {
        await _positionController.close();
      }
      if (!_durationController.isClosed) {
        await _durationController.close();
      }
      if (!_urlController.isClosed) {
        await _urlController.close();
      }
      if (!_playerStateController.isClosed) {
        await _playerStateController.close();
      }

      // State'i sıfırla
      _isPlaying = false;
      _isPaused = false;
      _currentAudioUrl = null;
      _currentPosition = Duration.zero;
      _totalDuration = Duration.zero;
      _volume = 1.0;
      _playbackSpeed = 1.0;

    } catch (e) {
      debugPrint('AudioManager dispose error: $e');
    }
  }

  /// Debug bilgileri
  static Map<String, dynamic> getDebugInfo() {
    return {
      'isPlaying': _isPlaying,
      'isPaused': _isPaused,
      'currentUrl': _currentAudioUrl,
      'currentPosition': _currentPosition.inSeconds,
      'totalDuration': _totalDuration.inSeconds,
      'volume': _volume,
      'playbackSpeed': _playbackSpeed,
      'progress': progress,
      'hasPlayer': _audioPlayer != null,
    };
  }
}