import { Composition } from 'remotion';
import { AppPromoVideo } from './AppPromoVideo';

export const RemotionRoot: React.FC = () => {
  return (
    <>
      <Composition
        id="AppStorePromo"
        component={AppPromoVideo}
        durationInFrames={180}
        fps={30}
        width={1920}
        height={1080}
      />
      <Composition
        id="AppStoreScreenshot1"
        component={AppPromoVideo}
        durationInFrames={1}
        fps={30}
        width={1284}
        height={2778}
      />
    </>
  );
};
