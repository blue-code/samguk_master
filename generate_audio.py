import wave, struct, math, os

os.makedirs('assets/audio', exist_ok=True)

# 정답(Correct) 효과음: 기분 좋은 C장조 화음(C, E, G)
with wave.open('assets/audio/correct.wav', 'w') as w:
    w.setnchannels(1) # mono
    w.setsampwidth(2) # 16-bit
    sample_rate = 44100
    w.setframerate(sample_rate)
    duration = 0.5
    for i in range(int(sample_rate * duration)):
        value = int(32767.0 * 0.3 * (
            math.sin(2.0 * math.pi * 523.25 * i / sample_rate) +
            math.sin(2.0 * math.pi * 659.25 * i / sample_rate) +
            math.sin(2.0 * math.pi * 783.99 * i / sample_rate)
        ))
        data = struct.pack('<h', value)
        w.writeframesraw(data)

# 오답(Wrong) 효과음: 불길하게 뚝 떨어지는 저음 (글라이딩)
with wave.open('assets/audio/wrong.wav', 'w') as w:
    w.setnchannels(1)
    w.setsampwidth(2)
    sample_rate = 44100
    w.setframerate(sample_rate)
    duration = 0.6
    for i in range(int(sample_rate * duration)):
        freq = 300 - (180 * (i / (sample_rate * duration)))
        value = int(32767.0 * 0.8 * math.sin(2.0 * math.pi * freq * i / sample_rate))
        data = struct.pack('<h', value)
        w.writeframesraw(data)

print("Audio files generated in assets/audio/")
