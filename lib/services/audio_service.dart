import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

enum MusicTrack { none, menu, gameplay }

class AudioService {
  AudioService({required bool soundOn}) : _soundOn = soundOn;

  static const String _buttonPath = 'audio/button.wav';
  static const String _coinPath = 'audio/coin.wav';
  static const String _dangerPath = 'audio/danger.wav';
  static const String _nearMissPath = 'audio/near_miss.wav';
  static const String _crashPath = 'audio/crash.wav';
  static const String _menuLoopPath = 'audio/menu_loop.wav';
  static const String _gameplayLoopPath = 'audio/gameplay_loop.wav';

  final AudioPlayer _musicPlayer = AudioPlayer(playerId: 'bgm');
  final AudioPlayer _sfxPrimary = AudioPlayer(playerId: 'sfx_primary');
  final AudioPlayer _sfxSecondary = AudioPlayer(playerId: 'sfx_secondary');

  bool _soundOn;
  MusicTrack _requestedTrack = MusicTrack.none;
  MusicTrack _currentTrack = MusicTrack.none;
  bool _backendReady = false;
  bool _coinToggle = false;
  DateTime _lastCoinPlayed = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime _lastDangerPlayed = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime _lastNearMissPlayed = DateTime.fromMillisecondsSinceEpoch(0);

  bool get soundOn => _soundOn;

  Future<void> init() async {
    try {
      await _musicPlayer.setPlayerMode(PlayerMode.mediaPlayer);
      await _musicPlayer.setReleaseMode(ReleaseMode.loop);
      await _musicPlayer.setVolume(0.34);

      await _sfxPrimary.setPlayerMode(PlayerMode.lowLatency);
      await _sfxPrimary.setReleaseMode(ReleaseMode.stop);
      await _sfxPrimary.setVolume(0.95);

      await _sfxSecondary.setPlayerMode(PlayerMode.lowLatency);
      await _sfxSecondary.setReleaseMode(ReleaseMode.stop);
      await _sfxSecondary.setVolume(0.9);
      _backendReady = true;
    } catch (_) {
      _backendReady = false;
    }
  }

  void setSoundEnabled(bool enabled) {
    _soundOn = enabled;
    if (!enabled) {
      if (_backendReady) {
        unawaited(_musicPlayer.stop());
      }
      return;
    }
    unawaited(_playRequestedTrack());
  }

  Future<void> playButton() async {
    if (!_soundOn) {
      return;
    }
    if (!_backendReady) {
      await SystemSound.play(SystemSoundType.click);
      return;
    }
    await _safePlayOn(_sfxPrimary, _buttonPath);
  }

  Future<void> playCoin() async {
    if (!_soundOn) {
      return;
    }
    final now = DateTime.now();
    if (now.difference(_lastCoinPlayed) < const Duration(milliseconds: 55)) {
      return;
    }
    _lastCoinPlayed = now;
    await HapticFeedback.selectionClick();
    if (!_backendReady) {
      await SystemSound.play(SystemSoundType.click);
      return;
    }
    final player = _coinToggle ? _sfxPrimary : _sfxSecondary;
    _coinToggle = !_coinToggle;
    await _safePlayOn(player, _coinPath);
  }

  Future<void> playDanger() async {
    if (!_soundOn) {
      return;
    }
    final now = DateTime.now();
    if (now.difference(_lastDangerPlayed) < const Duration(milliseconds: 280)) {
      return;
    }
    _lastDangerPlayed = now;
    await HapticFeedback.lightImpact();
    if (!_backendReady) {
      return;
    }
    await _safePlayOn(_sfxPrimary, _dangerPath);
  }

  Future<void> playNearMiss() async {
    if (!_soundOn) {
      return;
    }
    final now = DateTime.now();
    if (now.difference(_lastNearMissPlayed) <
        const Duration(milliseconds: 160)) {
      return;
    }
    _lastNearMissPlayed = now;
    await HapticFeedback.mediumImpact();
    if (!_backendReady) {
      return;
    }
    await _safePlayOn(_sfxSecondary, _nearMissPath);
  }

  Future<void> playCrash() async {
    if (!_soundOn) {
      return;
    }
    await HapticFeedback.heavyImpact();
    if (!_backendReady) {
      await SystemSound.play(SystemSoundType.alert);
      return;
    }
    await _safePlayOn(_sfxPrimary, _crashPath);
  }

  Future<void> playMenuMusic() async {
    _requestedTrack = MusicTrack.menu;
    await _playRequestedTrack();
  }

  Future<void> playGameplayMusic() async {
    _requestedTrack = MusicTrack.gameplay;
    await _playRequestedTrack();
  }

  Future<void> pauseMusic() async {
    if (!_backendReady) {
      return;
    }
    await _musicPlayer.pause();
  }

  Future<void> resumeMusic() async {
    if (!_soundOn || !_backendReady || _requestedTrack == MusicTrack.none) {
      return;
    }
    if (_musicPlayer.state == PlayerState.paused &&
        _currentTrack == _requestedTrack) {
      await _musicPlayer.resume();
      return;
    }
    await _playRequestedTrack();
  }

  Future<void> stopMusic() async {
    _requestedTrack = MusicTrack.none;
    _currentTrack = MusicTrack.none;
    await _musicPlayer.stop();
  }

  Future<void> dispose() async {
    await _musicPlayer.dispose();
    await _sfxPrimary.dispose();
    await _sfxSecondary.dispose();
  }

  Future<void> _safePlayOn(AudioPlayer player, String assetPath) async {
    try {
      await player.stop();
      await player.play(AssetSource(assetPath));
    } catch (_) {
      _backendReady = false;
    }
  }

  Future<void> _playRequestedTrack() async {
    if (!_soundOn || !_backendReady || _requestedTrack == MusicTrack.none) {
      return;
    }
    switch (_requestedTrack) {
      case MusicTrack.none:
        return;
      case MusicTrack.menu:
        await _playMusicTrack(
          track: MusicTrack.menu,
          assetPath: _menuLoopPath,
          volume: 0.34,
        );
        return;
      case MusicTrack.gameplay:
        await _playMusicTrack(
          track: MusicTrack.gameplay,
          assetPath: _gameplayLoopPath,
          volume: 0.25,
        );
        return;
    }
  }

  Future<void> _playMusicTrack({
    required MusicTrack track,
    required String assetPath,
    required double volume,
  }) async {
    try {
      await _musicPlayer.setVolume(volume);
      if (_currentTrack == track && _musicPlayer.state == PlayerState.playing) {
        return;
      }
      await _musicPlayer.stop();
      await _musicPlayer.play(AssetSource(assetPath));
      _currentTrack = track;
    } catch (_) {
      _backendReady = false;
      _currentTrack = MusicTrack.none;
    }
  }
}
