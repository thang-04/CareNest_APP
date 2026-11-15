import 'package:flutter_test/flutter_test.dart';

import 'package:carenest_app/features/account/domain/account_profile.dart';
import 'package:carenest_app/features/account/domain/app_modes.dart';

void main() {
  group('Plan 14/11 AC-6 (AUTH-21): chế độ mở sau đăng nhập', () {
    test('GV kiêm phụ huynh, chưa dùng lần nào ⇒ chế độ GV', () {
      expect(startMode([AppRole.parent, AppRole.teacher]), AppRole.teacher);
    });

    test('Có chế độ dùng lần cuối ⇒ mở lại chế độ đó', () {
      expect(
        startMode([AppRole.teacher, AppRole.parent], last: AppRole.parent),
        AppRole.parent,
      );
    });

    test('Chế độ cuối không còn trong tài khoản ⇒ bỏ qua', () {
      expect(
        startMode([AppRole.parent], last: AppRole.teacher),
        AppRole.parent,
      );
    });

    test('Chỉ một vai trò ⇒ không có chế độ để chuyển', () {
      AppMode.resetForTest();
      addTearDown(AppMode.resetForTest);
      AppMode.start([AppRole.kitchen]);
      expect(AppMode.otherThan(AppRole.kitchen), isNull);
      AppMode.start([AppRole.teacher, AppRole.parent]);
      expect(AppMode.otherThan(AppRole.teacher), AppRole.parent);
      expect(AppMode.otherThan(AppRole.parent), AppRole.teacher);
    });
  });
}
