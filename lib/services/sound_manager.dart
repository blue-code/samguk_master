import 'package:audioplayers/audioplayers.dart';
import 'local_store.dart';

class SoundManager {
  static final AudioPlayer _correctPlayer = AudioPlayer();
  static final AudioPlayer _wrongPlayer = AudioPlayer();
  static final AudioPlayer _bgmPlayer = AudioPlayer();
  
  static bool _isMuted = false;
  static bool get isMuted => _isMuted;

  static String _currentBgm = '';

  // 앱 진입 시 등 초기화가 필요하다면 호출
  static Future<void> init() async {
    _isMuted = await LocalStore.getIsMuted();

    await _correctPlayer.setSourceAsset('audio/correct.wav');
    await _wrongPlayer.setSourceAsset('audio/wrong.wav');
    
    _bgmPlayer.setReleaseMode(ReleaseMode.loop); // BGM 반복 재생

    _applyMute();
  }

  static void _applyMute() {
    double vol = _isMuted ? 0.0 : 1.0;
    _correctPlayer.setVolume(vol);
    _wrongPlayer.setVolume(vol);
    _bgmPlayer.setVolume(_isMuted ? 0.0 : 0.6); // BGM은 기본 볼륨 60%
  }

  static Future<void> toggleMute() async {
    _isMuted = !_isMuted;
    await LocalStore.saveIsMuted(_isMuted);
    _applyMute();
    
    if (!_isMuted && _currentBgm.isNotEmpty) {
      _bgmPlayer.resume();
    } else {
      _bgmPlayer.pause();
    }
  }

  static Future<void> _playBgm(String assetPath) async {
    if (_currentBgm == assetPath && _bgmPlayer.state == PlayerState.playing) return;
    _currentBgm = assetPath;
    await _bgmPlayer.stop();
    await _bgmPlayer.setSourceAsset(assetPath);
    if (!_isMuted) {
      await _bgmPlayer.resume();
    }
  }

  static void playLobbyBgm() => _playBgm('audio/bgm_lobby.mp3');
  static void playInGameBgm() => _playBgm('audio/bgm_ingame.mp3');
  static void playResultBgm() => _playBgm('audio/bgm_result.mp3');

  static void stopBgm() {
    _currentBgm = '';
    _bgmPlayer.pause();
  }

  static void playCorrect() {
    if (_isMuted) return;
    _correctPlayer.stop();
    _correctPlayer.play(AssetSource('audio/correct.wav'));
  }

  static void playWrong() {
    if (_isMuted) return;
    _wrongPlayer.stop();
    _wrongPlayer.play(AssetSource('audio/wrong.wav'));
  }
}
