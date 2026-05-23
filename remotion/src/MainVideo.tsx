import { AbsoluteFill, useCurrentFrame, useVideoConfig, interpolate } from 'remotion';

export const MainVideo: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  const opacity = interpolate(frame, [0, 30], [0, 1], { extrapolateRight: 'clamp' });
  const scale = interpolate(frame, [0, 20], [0.8, 1], { extrapolateRight: 'clamp' });

  return (
    <AbsoluteFill style={{ backgroundColor: '#1a1a2e' }}>
      <AbsoluteFill
        style={{
          justifyContent: 'center',
          alignItems: 'center',
          opacity,
          transform: `scale(${scale})`,
        }}
      >
        <h1 style={{ color: '#e94560', fontSize: 80, fontWeight: 'bold', textAlign: 'center' }}>
          삼국지 마스터
        </h1>
        <p style={{ color: '#f0f0f0', fontSize: 30, marginTop: 20 }}>
          퀴즈로 정복하는 삼국지
        </p>
      </AbsoluteFill>
    </AbsoluteFill>
  );
};
