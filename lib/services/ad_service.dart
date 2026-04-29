import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/foundation.dart';

// TODO: 출시 전 실제 AdMob 단위 ID로 교체
//   앱 ID     → ios/Runner/Info.plist  GADApplicationIdentifier
//   배너 ID   → _bannerAdUnitId
//   전면 ID   → _interstitialAdUnitId
class AdService {
  AdService._();
  static final AdService instance = AdService._();

  static const _bannerAdUnitId =
      kDebugMode
          ? 'ca-app-pub-3940256099942544/2934735716' // Google 공식 테스트 배너
          : 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX'; // TODO: 실제 배너 ID

  static const _interstitialAdUnitId =
      kDebugMode
          ? 'ca-app-pub-3940256099942544/4411468910' // Google 공식 테스트 전면
          : 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX'; // TODO: 실제 전면 ID

  InterstitialAd? _interstitialAd;
  bool _interstitialReady = false;

  Future<void> initialize() async {
    await MobileAds.instance.initialize();
    loadInterstitial();
  }

  void loadInterstitial() {
    InterstitialAd.load(
      adUnitId: _interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _interstitialReady = true;
        },
        onAdFailedToLoad: (_) {
          _interstitialReady = false;
        },
      ),
    );
  }

  void showInterstitial({required VoidCallback onClosed}) {
    if (_interstitialReady && _interstitialAd != null) {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _interstitialAd = null;
          _interstitialReady = false;
          loadInterstitial();
          onClosed();
        },
        onAdFailedToShowFullScreenContent: (ad, _) {
          ad.dispose();
          _interstitialAd = null;
          _interstitialReady = false;
          onClosed();
        },
      );
      _interstitialAd!.show();
    } else {
      onClosed();
    }
  }

  BannerAd createBannerAd() => BannerAd(
    adUnitId: _bannerAdUnitId,
    size: AdSize.banner,
    request: const AdRequest(),
    listener: const BannerAdListener(),
  );
}
