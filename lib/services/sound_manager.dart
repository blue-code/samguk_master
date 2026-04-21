import 'package:audioplayers/audioplayers.dart';

class SoundManager {
  static final AudioPlayer _correctPlayer = AudioPlayer();
  static final AudioPlayer _wrongPlayer = AudioPlayer();

  // 앱 진입 시 등 초기화가 필요하다면 호출
  static Future<void> init() async {
    await _correctPlayer.setSourceAsset('audio/correct.wav');
    await _wrongPlayer.setSourceAsset('audio/wrong.wav');
    
    // 볼륨 조절 약간 자극적으로 (너무 시끄럽지 않게)
    await _correctPlayer.setVolume(1.0);
    await _wrongPlayer.setVolume(1.0);
  }

  static void playCorrect() {
    // 이미 재생 중이면 멈추고 처음부터 재생 (빠른 타격감)
    _correctPlayer.stop();
    _correctPlayer.play(AssetSource('audio/correct.wav'));
  }

  static void playWrong() {
    _wrongPlayer.stop();
    _wrongPlayer.play(AssetSource('audio/wrong.wav'));
  }
}
