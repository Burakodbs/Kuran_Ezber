// Audio Manager unit tests for Kuran Ezber app
import 'package:flutter_test/flutter_test.dart';
import 'package:kuran_ezber/utils/audio_manager.dart';

void main() {
  group('AudioManager Tests', () {
    test('AudioManager initial state', () {
      expect(AudioManager.isPlaying, false);
      expect(AudioManager.isPaused, false);
      expect(AudioManager.currentAudioUrl, null);
      expect(AudioManager.volume, 1.0);
      expect(AudioManager.playbackSpeed, 1.0);
    });

    test('URL validation cache operations', () {
      // Clear cache
      AudioManager.clearUrlCache();
      
      // Test debug info includes cache size
      final debugInfo = AudioManager.getDebugInfo();
      expect(debugInfo['cacheSize'], 0);
      expect(debugInfo.containsKey('isDisposed'), true);
      expect(debugInfo.containsKey('hasActiveSubscriptions'), true);
    });

    test('Audio state management', () {
      expect(AudioManager.progress, 0.0);
      expect(AudioManager.remainingTime, Duration.zero);
      expect(AudioManager.formattedPosition, '00:00');
      expect(AudioManager.formattedDuration, '00:00');
      expect(AudioManager.formattedRemainingTime, '00:00');
    });

    test('Debouncing mechanism state', () {
      final debugInfo = AudioManager.getDebugInfo();
      expect(debugInfo.containsKey('isProcessingPlayRequest'), true);
      expect(debugInfo.containsKey('lastPlayCall'), true);
      
      // Initial state should not be processing
      expect(debugInfo['isProcessingPlayRequest'], false);
    });
  });
}