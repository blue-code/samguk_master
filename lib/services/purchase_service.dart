import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import 'local_store.dart';

/// 광고 제거(비소모성) 인앱 결제.
///
/// App Store Connect 의 제품 ID 와 정확히 일치해야 한다:
///   com.kent.quiz.samgukMaster.removeads  (비소모품, ₩3,900)
///
/// 비소모성 상품이므로 App Review 요구사항에 따라 '구매 복원' 경로를
/// 반드시 UI 에 노출해야 한다.
class PurchaseService extends ChangeNotifier {
  PurchaseService._();
  static final PurchaseService instance = PurchaseService._();

  static const String removeAdsProductId =
      'com.kent.quiz.samgukMaster.removeads';

  /// 심사 스크린샷 자동화용 표시 가격.
  /// 시뮬레이터에는 실제 스토어 연결이 없어 상품 조회가 비는데, IAP 심사
  /// 스크린샷에는 가격이 보여야 한다(AppCommonSkill 05). ASC 에 설정한
  /// 값과 **같은 문자열**을 넘겨야 하며, 표시에만 쓰이고 결제 경로는
  /// 건드리지 않는다. 예: --dart-define=SS_IAP_PRICE=₩3,900
  static const String _ssPrice = String.fromEnvironment('SS_IAP_PRICE');
  static bool get _isScreenshotPrice => _ssPrice.isNotEmpty;

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  bool _adFree = false;
  bool _available = false;
  bool _purchasePending = false;
  ProductDetails? _removeAdsProduct;

  /// 광고를 제거한 사용자인가. 저장된 값이라 오프라인에서도 유지된다.
  bool get isAdFree => _adFree;
  bool get isStoreAvailable => _available || _isScreenshotPrice;
  bool get isPurchasePending => _purchasePending;
  ProductDetails? get removeAdsProduct => _removeAdsProduct;

  /// 스토어에서 받은 현지화된 가격(예: ₩3,900). 조회 전이면 null.
  String? get formattedPrice =>
      _isScreenshotPrice ? _ssPrice : _removeAdsProduct?.price;

  Future<void> initialize() async {
    // 저장된 권한을 먼저 반영해 앱 시작 직후부터 광고를 띄우지 않는다.
    _adFree = await LocalStore.getAdFree();
    notifyListeners();

    _available = await _iap.isAvailable();
    if (!_available) return;

    // 콜드 스타트 시의 복원 결과도 이 스트림으로 들어온다.
    _subscription = _iap.purchaseStream.listen(
      _onPurchaseUpdated,
      onError: (Object e) => debugPrint('purchaseStream error: $e'),
    );

    final response = await _iap.queryProductDetails({removeAdsProductId});
    if (response.productDetails.isNotEmpty) {
      _removeAdsProduct = response.productDetails.first;
      notifyListeners();
    }
  }

  Future<void> buyRemoveAds() async {
    final product = _removeAdsProduct;
    if (product == null || _adFree) return;

    _purchasePending = true;
    notifyListeners();

    try {
      await _iap.buyNonConsumable(
        purchaseParam: PurchaseParam(productDetails: product),
      );
    } catch (e) {
      debugPrint('buyNonConsumable failed: $e');
      _purchasePending = false;
      notifyListeners();
    }
  }

  /// 비소모성 상품은 복원 경로 노출이 App Review 요구사항이다.
  Future<void> restorePurchases() async {
    if (!_available) return;
    try {
      await _iap.restorePurchases();
    } catch (e) {
      debugPrint('restorePurchases failed: $e');
    }
  }

  Future<void> _onPurchaseUpdated(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.productID != removeAdsProductId) {
        // 알 수 없는 상품이라도 pending 으로 남기면 스토어가 계속 재전달한다.
        if (purchase.pendingCompletePurchase) {
          await _iap.completePurchase(purchase);
        }
        continue;
      }

      switch (purchase.status) {
        case PurchaseStatus.pending:
          _purchasePending = true;
          break;

        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          // 권한을 먼저 저장한 뒤에 completePurchase 를 호출한다.
          // 반대 순서면 저장 직전에 앱이 죽었을 때 구매가 유실된다.
          _adFree = true;
          await LocalStore.setAdFree(true);
          _purchasePending = false;
          break;

        case PurchaseStatus.error:
        case PurchaseStatus.canceled:
          _purchasePending = false;
          break;
      }

      if (purchase.pendingCompletePurchase) {
        await _iap.completePurchase(purchase);
      }
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
