import { AbsoluteFill, useCurrentFrame, useVideoConfig, interpolate, Img, spring } from 'remotion';

export const AppPromoVideo: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps, width, height } = useVideoConfig();
  const isPortrait = height > width;

  // Timing
  const logoFadeIn = interpolate(frame, [0, 20], [0, 1], { extrapolateRight: 'clamp' });
  const logoScale = spring({ frame, fps, config: { damping: 12 } });
  const titleY = interpolate(frame, [15, 35], [50, 0], { extrapolateRight: 'clamp' });
  const subtitleOpacity = interpolate(frame, [30, 50], [0, 1], { extrapolateRight: 'clamp' });
  const badgeOpacity = interpolate(frame, [60, 80], [0, 1], { extrapolateRight: 'clamp' });
  const feature1Y = interpolate(frame, [80, 100], [30, 0], { extrapolateRight: 'clamp' });
  const feature2Y = interpolate(frame, [100, 120], [30, 0], { extrapolateRight: 'clamp' });
  const feature3Y = interpolate(frame, [120, 140], [30, 0], { extrapolateRight: 'clamp' });
  const ctaOpacity = interpolate(frame, [150, 170], [0, 1], { extrapolateRight: 'clamp' });

  const bgColor = '#0f0f23';
  const accentColor = '#e94560';
  const goldColor = '#ffd700';
  const textColor = '#ffffff';

  return (
    <AbsoluteFill style={{ backgroundColor: bgColor, fontFamily: 'sans-serif' }}>
      {/* Background decoration */}
      <AbsoluteFill style={{
        background: `radial-gradient(ellipse at 50% 30%, ${accentColor}22 0%, transparent 70%)`,
      }} />

      {/* Logo area */}
      <AbsoluteFill style={{
        justifyContent: 'center',
        alignItems: 'center',
        opacity: logoFadeIn,
        transform: `scale(${logoScale})`,
      }}>
        {/* App Icon placeholder */}
        <div style={{
          width: isPortrait ? 200 : 160,
          height: isPortrait ? 200 : 160,
          borderRadius: 40,
          background: `linear-gradient(135deg, ${accentColor}, #c0392b)`,
          display: 'flex',
          justifyContent: 'center',
          alignItems: 'center',
          marginBottom: 30,
          boxShadow: `0 0 60px ${accentColor}44`,
        }}>
          <span style={{ fontSize: 80 }}>⚔️</span>
        </div>
      </AbsoluteFill>

      {/* Title */}
      <AbsoluteFill style={{
        justifyContent: 'center',
        alignItems: 'center',
        transform: `translateY(${titleY}px)`,
        paddingTop: isPortrait ? 260 : 200,
      }}>
        <h1 style={{
          color: goldColor,
          fontSize: isPortrait ? 72 : 56,
          fontWeight: 'bold',
          margin: 0,
          textAlign: 'center',
          textShadow: `0 0 30px ${goldColor}44`,
        }}>
          삼국지 마스터
        </h1>
        <p style={{
          color: textColor,
          fontSize: isPortrait ? 32 : 24,
          marginTop: 12,
          opacity: subtitleOpacity,
          textAlign: 'center',
          fontWeight: 300,
        }}>
          퀴즈로 정복하는 삼국지
        </p>
      </AbsoluteFill>

      {/* Features */}
      <AbsoluteFill style={{
        justifyContent: 'center',
        alignItems: 'center',
        paddingTop: isPortrait ? 480 : 360,
        gap: 16,
      }}>
        <Feature text="📚 300+ 삼국지 퀴즈" opacity={feature1Y > 0 ? 1 : 0} y={feature1Y} isPortrait={isPortrait} />
        <Feature text="🏆 실시간 랭킹 대결" opacity={feature2Y > 0 ? 1 : 0} y={feature2Y} isPortrait={isPortrait} />
        <Feature text="🎯 장수 카드 수집" opacity={feature3Y > 0 ? 1 : 0} y={feature3Y} isPortrait={isPortrait} />
      </AbsoluteFill>

      {/* CTA */}
      <AbsoluteFill style={{
        justifyContent: 'flex-end',
        alignItems: 'center',
        paddingBottom: isPortrait ? 80 : 60,
        opacity: ctaOpacity,
      }}>
        <div style={{
          background: accentColor,
          color: textColor,
          padding: '16px 48px',
          borderRadius: 50,
          fontSize: isPortrait ? 28 : 22,
          fontWeight: 'bold',
          letterSpacing: 2,
        }}>
          지금 다운로드
        </div>
      </AbsoluteFill>
    </AbsoluteFill>
  );
};

const Feature: React.FC<{ text: string; opacity: number; y: number; isPortrait: boolean }> = ({ text, opacity, y, isPortrait }) => (
  <div style={{
    color: '#ffffff',
    fontSize: isPortrait ? 28 : 22,
    opacity,
    transform: `translateY(${y}px)`,
    fontWeight: 400,
    textShadow: '0 0 10px rgba(255,255,255,0.2)',
  }}>
    {text}
  </div>
);
