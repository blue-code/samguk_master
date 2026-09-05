import 'dart:async';

import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:flutter/foundation.dart';

// AdMob 단위 ID 위치
//   앱 ID   → ios/Runner/Info.plist  GADApplicationIdentifier
//   배너 ID → _bannerAdUnitId
//   전면 ID → _interstitialAdUnitId
class AdService {
  AdService._();
  static final AdService instance = AdService._();

  static const _bannerAdUnitId =
      kDebugMode
          ? 'ca-app-pub-3940256099942544/2934735716' // Google 공식 테스트 배너
          : 'ca-app-pub-6800171305049310/1734174097'; // samguk_banner_home

  static const _interstitialAdUnitId =
      kDebugMode
          ? 'ca-app-pub-3940256099942544/4411468910' // Google 공식 테스트 전면
          : 'ca-app-pub-6800171305049310/4771400970'; // samguk_interstitial_gameend

  static const _rewardedAdUnitId =
      kDebugMode
          ? 'ca-app-pub-3940256099942544/1712485313' // Google 공식 테스트 리워드
          : 'ca-app-pub-6800171305049310/5834799030'; // samguk_rewarded_boost

  InterstitialAd? _interstitialAd;
  bool _interstitialReady = false;

  /// 전면광고 최소 간격. 한 판이 약 4분이라 매 판 노출은 이탈을 키운다.
  /// 이 간격이면 대략 두 판에 한 번꼴로 노출된다.
  static const Duration _minInterstitialGap = Duration(seconds: 180);
  DateTime? _lastInterstitialShownAt;

  RewardedAd? _rewardedAd;
  bool _rewardedReady = false;

  /// 리워드 광고를 지금 보여줄 수 있는지. 버튼 노출 여부 판단에 쓴다.
  bool get isRewardedReady => _rewardedReady && _rewardedAd != null;

  Future<void> initialize() async {
    // 1) ATT 우선. 사용자가 추적을 거부하면 같은 세션에서 GDPR 동의로
    //    다시 묻지 않는다 (App Store 가이드라인 5.1.1(iv)).
    final trackingAllowed = await _requestTrackingAuthorizationIfNeeded();

    // 2) ATT 가 허용된 경우에만 EEA 사용자에게 GDPR personalized-ads 동의 모달 표시.
    //    거부 또는 not-determined 상태에서는 non-personalized ads 만 송출되므로
    //    GDPR 동의 모달을 띄우지 않는다.
    if (trackingAllowed) {
      await _gatherConsentIfNeeded();
    }

    await MobileAds.instance.initialize();
    loadInterstitial();
    loadRewarded();
  }

  /// EEA / UK / 스위스 사용자 GDPR 동의 수집 (Google CMP UMP).
  /// AdMob 콘솔에 publish된 consent message 를 SDK 가 자동 fetch 한다.
  /// ATT 가 허용된 경우에만 호출된다.
  Future<void> _gatherConsentIfNeeded() async {
    if (kDebugMode) return;
    try {
      final params = ConsentRequestParameters();
      await _requestConsentUpdate(params);
      await ConsentForm.loadAndShowConsentFormIfRequired((_) {});
    } catch (_) {
      // 네트워크 실패·미지원 등 — 광고는 non-personalized 로 fallback
    }
  }

  Future<void> _requestConsentUpdate(ConsentRequestParameters params) {
    final completer = Completer<void>();
    ConsentInformation.instance.requestConsentInfoUpdate(
      params,
      () => completer.complete(),
      (e) => completer.complete(),
    );
    return completer.future;
  }

  /// ATT 권한 요청. true 반환 시 personalized 추적 가능.
  Future<bool> _requestTrackingAuthorizationIfNeeded() async {
    // 디버그 빌드에서는 ATT 스킵 (스크린샷·UI 테스트 시 모달 방해 방지)
    if (kDebugMode) return false;
    try {
      var status = await AppTrackingTransparency.trackingAuthorizationStatus;
      if (status == TrackingStatus.notDetermined) {
        await Future.delayed(const Duration(milliseconds: 200));
        status = await AppTrackingTransparency.requestTrackingAuthorization();
      }
      return status == TrackingStatus.authorized;
    } catch (_) {
      // ATT 는 iOS 14+ 전용 — 다른 플랫폼/버전에선 false
      return false;
    }
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
    final last = _lastInterstitialShownAt;
    if (last != null && DateTime.now().difference(last) < _minInterstitialGap) {
      onClosed();
      return;
    }

    if (_interstitialReady && _interstitialAd != null) {
      _lastInterstitialShownAt = DateTime.now();
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

  void loadRewarded() {
    RewardedAd.load(
      adUnitId: _rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _rewardedReady = true;
        },
        onAdFailedToLoad: (_) {
          _rewardedAd = null;
          _rewardedReady = false;
        },
      ),
    );
  }

  /// 리워드 광고를 보여주고, 시청 완료 시에만 [onEarned] 를 호출한다.
  /// 광고가 없거나 도중에 닫으면 [onEarned] 는 호출되지 않는다.
  /// 어느 경우든 [onClosed] 는 정확히 한 번 호출된다.
  void showRewarded({
    required VoidCallback onEarned,
    required VoidCallback onClosed,
  }) {
    final ad = _rewardedAd;
    if (!_rewardedReady || ad == null) {
      onClosed();
      return;
    }

    // 보상은 광고를 끝까지 본 경우에만 지급하고, 화면 복귀는 닫힘 시점에 한다.
    var earned = false;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedAd = null;
        _rewardedReady = false;
        loadRewarded();
        if (earned) onEarned();
        onClosed();
      },
      onAdFailedToShowFullScreenContent: (ad, _) {
        ad.dispose();
        _rewardedAd = null;
        _rewardedReady = false;
        loadRewarded();
        onClosed();
      },
    );

    _rewardedAd = null;
    _rewardedReady = false;
    ad.show(onUserEarnedReward: (ad, reward) => earned = true);
  }

  BannerAd createBannerAd() => BannerAd(
    adUnitId: _bannerAdUnitId,
    size: AdSize.banner,
    request: const AdRequest(),
    listener: const BannerAdListener(),
  );
}
