import 'package:audioplayers/audioplayers.dart';
import 'local_store.dart';

class SoundManager {
  static final AudioPlayer _correctPlayer = AudioPlayer();
  static final AudioPlayer _wrongPlayer = AudioPlayer();
  static final AudioPlayer _bgmPlayer = AudioPlayer();
  
  static bool _isMuted = false;
  static bool get isMuted => _isMuted;

  // 앱 진입 시 등 초기화가 필요하다면 호출
  static Future<void> init() async {
    _isMuted = await LocalStore.getIsMuted();

    await _correctPlayer.setSourceAsset('audio/correct.wav');
    await _wrongPlayer.setSourceAsset('audio/wrong.wav');
    await _bgmPlayer.setSourceAsset('audio/bgm.wav');
    
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
    
    // 만약 음소거가 해제되었고 BGM이 플레이 중이어야 한다면,
    // (보통 앱 실행 중에는 항상 bgmPlayer.resume() 혹은 play() 상태라고 가정)
    if (!_isMuted) {
      playBgm();
    } else {
      stopBgm();
    }
  }

  static void playBgm() {
    if (_isMuted) return;
    _bgmPlayer.resume();
  }

  static void stopBgm() {
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
