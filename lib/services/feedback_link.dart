import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// "피드백 보내기" 링크 — blue-code 앱들이 공유하는 구글 폼.
///
/// 앱은 절대 POST 하지 않는다. 사용자가 외부 브라우저(별개 컨텍스트)에서 제출하므로
/// 앱 자체는 아무것도 수집하지 않는다.
/// 폼 하나를 모든 앱이 공유하고 `app` 필드(슬러그)로 시트를 앱별로 필터한다.
/// (AppCommonSkill 06-legal-privacy-review.md · CLAUDE.md "Shared facts")
class FeedbackLink {
  static const String _form =
      'https://docs.google.com/forms/d/e/1FAIpQLSekD7Uyg8Oa5WVWX0zV15PEyWS2y9A5sIGxA_pSeAcvWVtf6Q/viewform';

  /// 공용 시트의 App 열에 들어가는 이 앱의 슬러그.
  static const String appSlug = 'samguk';

  /// App Store 에 올라가는 버전(= fastlane/Fastfile 의 APP_VERSION).
  /// package_info_plus 의존성을 새로 들이는 대신 상수로 두었다.
  /// ⚠️ 릴리스마다 손으로 올려야 한다. 1.0.3 제출 때 이 값이 1.0.0+1 로
  ///    남아 있어 피드백 시트의 version 열이 전부 틀리게 찍혔다.
  ///    pubspec.yaml 의 `version:` 은 fastlane 이 --build-name 으로
  ///    덮어쓰기 때문에 진실의 원천이 아니다 — Fastfile 쪽을 보라.
  static const String appVersion = '1.0.3';

  // 프리필 필드. type/message/email 은 사용자가 채운다.
  static const String _appField = 'entry.1556462282';
  static const String _versionField = 'entry.88571063';
  static const String _localeField = 'entry.1277534382';

  /// 순수 빌더 — 플러그인 없이 테스트할 수 있도록 필요한 값을 모두 받는다.
  static Uri build({required String version, required String locale}) {
    return Uri.parse(_form).replace(queryParameters: {
      'usp': 'pp_url',
      _appField: appSlug,
      _versionField: version,
      _localeField: locale,
    });
  }

  /// 이번 빌드의 실제 링크를 외부 브라우저로 연다.
  static Future<bool> open({required String locale}) async {
    try {
      return launchUrl(build(version: appVersion, locale: locale),
          mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Failed to open feedback form: $e');
      return false;
    }
  }
}
