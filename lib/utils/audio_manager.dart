import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

class AudioManager {
  static final AudioPlayer _audioPlayer = AudioPlayer();
  static bool _isPlaying = false;
  static String? _currentAudioUrl;

  static bool get isPlaying => _isPlaying;
  static String? get currentAudioUrl => _currentAudioUrl;

  static Future<void> playAudio(String audioUrl, VoidCallback onComplete) async {
    try {
      if (_isPlaying && _currentAudioUrl == audioUrl) {
        await stopAudio();
        return;
      }

      if (_isPlaying) {
        await stopAudio();
      }

      await _audioPlayer.play(UrlSource(audioUrl));
      _isPlaying = true;
      _currentAudioUrl = audioUrl;

      _audioPlayer.onPlayerStateChanged.listen((state) {
        if (state == PlayerState.completed) {
          _isPlaying = false;
          _currentAudioUrl = null;
          onComplete();
        }
      });
    } catch (e) {
      debugPrint('Audio playback error: $e');
      _isPlaying = false;
      _currentAudioUrl = null;
    }
  }

  static Future<void> stopAudio() async {
    await _audioPlayer.stop();
    _isPlaying = false;
    _currentAudioUrl = null;
  }

  static void dispose() {
    _audioPlayer.dispose();
  }
}