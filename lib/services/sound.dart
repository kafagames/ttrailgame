import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

import 'store.dart';

enum Sfx { pick, turn, place, unpick, nope, bound, star, ribbon, hint, tap }

/// Sound effects, the music-box loop and haptics, all behind the player's
/// Quiet Room switches.
class Sound {
  /// Tests switch audio off so no platform channel is touched.
  static bool enabled = true;

  static final Map<Sfx, AudioPlayer> _players = {};
  static AudioPlayer? _music;
  static bool _musicOn = false;

  static Future<void> init() async {
    if (!enabled) return;
    try {
      await AudioPlayer.global.setAudioContext(
        AudioContextConfig(
          focus: AudioContextConfigFocus.mixWithOthers,
        ).build(),
      );
      for (final s in Sfx.values) {
        final p = AudioPlayer()..setReleaseMode(ReleaseMode.stop);
        await p.setPlayerMode(PlayerMode.lowLatency);
        await p.setSource(AssetSource('sfx/${s.name}.wav'));
        _players[s] = p;
      }
    } catch (_) {
      // Audio is a nicety; the game plays fine silently.
    }
  }

  static void play(Sfx s) {
    if (!enabled || !Store.instance.sound) return;
    final p = _players[s];
    if (p == null) return;
    p.stop().then((_) => p.resume()).catchError((_) {});
  }

  static Future<void> syncMusic() async {
    if (!enabled) return;
    final want = Store.instance.music;
    try {
      if (want && !_musicOn) {
        _music ??= AudioPlayer();
        await _music!.setReleaseMode(ReleaseMode.loop);
        await _music!.setVolume(0.32);
        await _music!.play(AssetSource('sfx/music.wav'));
        _musicOn = true;
      } else if (!want && _musicOn) {
        await _music?.pause();
        _musicOn = false;
      }
    } catch (_) {}
  }

  static Future<void> pauseMusic() async {
    if (_musicOn) await _music?.pause();
  }

  static Future<void> resumeMusic() async {
    if (_musicOn && Store.instance.music) await _music?.resume();
  }

  static void tick() {
    if (enabled && Store.instance.haptics) HapticFeedback.selectionClick();
  }

  static void bump() {
    if (enabled && Store.instance.haptics) HapticFeedback.lightImpact();
  }

  static void thud() {
    if (enabled && Store.instance.haptics) HapticFeedback.mediumImpact();
  }
}
