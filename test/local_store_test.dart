import 'package:flutter_test/flutter_test.dart';
import 'package:samguk_master/services/local_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('광고 제거 권한', () {
    test('기본값은 false — 구매 전에는 광고가 나온다', () async {
      expect(await LocalStore.getAdFree(), isFalse);
    });

    test('저장하면 유지된다 — 오프라인/재시작에도 광고가 안 나와야 한다', () async {
      await LocalStore.setAdFree(true);
      expect(await LocalStore.getAdFree(), isTrue);
    });
  });

  group('오답 복습 대기열', () {
    test('기본값은 빈 집합', () async {
      expect(await LocalStore.getWrongIds(), isEmpty);
    });

    test('세션 간 이월된다', () async {
      await LocalStore.saveWrongIds({3, 1, 2});
      expect(await LocalStore.getWrongIds(), {1, 2, 3});
    });

    test('정복 초기화 시 복습 대기열도 함께 비워진다', () async {
      await LocalStore.saveWrongIds({7});
      await LocalStore.saveMasteredIds('Easy', {1});
      await LocalStore.resetConquest(['Easy', 'Medium', 'Hard']);

      expect(await LocalStore.getWrongIds(), isEmpty);
      expect(await LocalStore.getMasteredIds('Easy'), isEmpty);
    });

    test('정복 초기화가 광고 제거 권한까지 지우지는 않는다', () async {
      await LocalStore.setAdFree(true);
      await LocalStore.resetConquest(['Easy', 'Medium', 'Hard']);
      expect(await LocalStore.getAdFree(), isTrue,
          reason: '결제한 권한이 게임 진행도 초기화로 사라지면 안 된다');
    });
  });
}
