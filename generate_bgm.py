import wave, struct, math, os

os.makedirs('assets/audio', exist_ok=True)

# BGM: 긴장감 있는 다크 앰비언트 베이스 드론 (Loop용)
with wave.open('assets/audio/bgm.wav', 'w') as w:
    w.setnchannels(1)
    w.setsampwidth(2)
    sample_rate = 44100
    w.setframerate(sample_rate)
    duration = 5.0 # 5 seconds loop
    for i in range(int(sample_rate * duration)):
        t = i / sample_rate
        # 깊고 울리는 베이스 톤 + 느린 모듈레이션
        freq1 = 55.0 # A1
        freq2 = 55.5 # 약간의 비트
        vol = 0.5 + 0.3 * math.sin(2.0 * math.pi * 0.2 * t)
        val = (math.sin(2.0 * math.pi * freq1 * t) + math.sin(2.0 * math.pi * freq2 * t)) * 0.5
        value = int(32767.0 * vol * val * 0.8) # BGM이므로 너무 크지 않게
        data = struct.pack('<h', value)
        w.writeframesraw(data)

print("BGM generated in assets/audio/bgm.wav")
