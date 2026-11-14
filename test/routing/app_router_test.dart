import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:carenest_app/core/theme/app_theme.dart';
import 'package:carenest_app/features/account/domain/app_modes.dart';
import 'package:carenest_app/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:carenest_app/features/auth/presentation/screens/login_screen.dart';
import 'package:carenest_app/features/auth/presentation/screens/otp_verify_screen.dart';
import 'package:carenest_app/routing/app_router.dart';
import 'package:carenest_app/routing/route_paths.dart';

import '../helpers/pump_app.dart';

Future<GoRouter> pumpRouter(
  WidgetTester tester, {
  required bool enablePreview,
}) async {
  usePhoneSize(tester);
  final router = buildAppRouter(enablePreview: enablePreview);
  addTearDown(router.dispose);
  await tester.pumpWidget(
    MaterialApp.router(theme: buildLightTheme(), routerConfig: router),
  );
  await tester.pumpAndSettle();
  return router;
}

void main() {
  testWidgets('AC-9: release ⇒ chỉ có Đăng nhập, không có lối xem thử', (
    tester,
  ) async {
    final router = await pumpRouter(tester, enablePreview: false);
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('Xem thử theo vai trò'), findsNothing);

    for (final path in [
      RoutePaths.preview,
      RoutePaths.parentToday,
      RoutePaths.teacherToday,
      RoutePaths.kitchenHome,
      RoutePaths.vicePrincipalHome,
      RoutePaths.principalHome,
    ]) {
      router.go(path);
      await tester.pumpAndSettle();
      expect(find.text('Không tìm thấy trang'), findsOneWidget, reason: path);
    }
  });

  testWidgets('AC-9: debug ⇒ Đăng nhập → Xem thử → Phụ huynh có 4 tab', (
    tester,
  ) async {
    await pumpRouter(tester, enablePreview: true);
    await tester.ensureVisible(find.text('Xem thử theo vai trò'));
    await tester.tap(find.text('Xem thử theo vai trò'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Phụ huynh'));
    await tester.pumpAndSettle();

    final bar = find.byType(NavigationBar);
    expect(bar, findsOneWidget);
    for (final label in ['Trang chủ', 'Bé của tôi', 'Thông báo', 'Tài khoản']) {
      expect(
        find.descendant(of: bar, matching: find.text(label)),
        findsOneWidget,
      );
    }

    await tester.tap(
      find.descendant(of: bar, matching: find.text('Bé của tôi')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Hôm nay'), findsOneWidget);
    expect(find.text('Sức khỏe'), findsOneWidget);
  });

  testWidgets('Bếp mở thẳng tab Thực đơn', (tester) async {
    final router = await pumpRouter(tester, enablePreview: true);
    router.go(RoutePaths.kitchenMenu);
    await tester.pumpAndSettle();
    final bar = tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(bar.selectedIndex, 1);
  });

  testWidgets('Redraw AC-9: GV không còn route chụp/gửi ảnh bữa ăn', (
    tester,
  ) async {
    final router = await pumpRouter(tester, enablePreview: true);
    router.go(RoutePaths.teacherToday);
    await tester.pumpAndSettle();
    expect(find.text('Không tìm thấy trang'), findsNothing);
    for (final path in [
      '/teacher/meal-photos',
      '/teacher/meal-photos/send?slot=lunch',
    ]) {
      router.go(path);
      await tester.pumpAndSettle();
      expect(find.text('Không tìm thấy trang'), findsOneWidget, reason: path);
    }
  });

  testWidgets(
    'Redraw AC-19 (NUT-11, NUT-12, NUT-14, NUT-22): gỡ route nhận nguyên liệu, báo thiếu, trạng thái nấu',
    (tester) async {
      final router = await pumpRouter(tester, enablePreview: true);
      for (final path in [
        '/kitchen/receipts',
        '/kitchen/receipts/shortage',
        '/kitchen/cooking',
      ]) {
        router.go(path);
        await tester.pumpAndSettle();
        expect(find.text('Không tìm thấy trang'), findsOneWidget, reason: path);
      }
    },
  );

  testWidgets(
    'Bếp: Trang chủ mở Ảnh mẫu bữa và Sổ lưu mẫu, màn con ẩn thanh đáy',
    (tester) async {
      final router = await pumpRouter(tester, enablePreview: true);
      router.go(RoutePaths.kitchenHome);
      await tester.pumpAndSettle();
      for (final (task, title) in [
        ('Ảnh mẫu bữa', 'Lưu ảnh mẫu'),
        ('Sổ lưu mẫu', 'Ghi lưu mẫu'),
      ]) {
        await tester.scrollUntilVisible(find.text(task), 200);
        await tester.tap(find.text(task));
        await tester.pumpAndSettle();
        expect(find.text(title), findsOneWidget, reason: task);
        expect(find.byType(NavigationBar), findsNothing, reason: task);
        await tester.pageBack();
        await tester.pumpAndSettle();
        expect(find.byType(NavigationBar), findsOneWidget, reason: task);
      }
    },
  );

  testWidgets('Phó HT: màn con ẩn thanh đáy, ngữ cảnh lấy từ query', (
    tester,
  ) async {
    final router = await pumpRouter(tester, enablePreview: true);
    router.go(RoutePaths.vicePrincipalApprovals);
    await tester.pumpAndSettle();
    expect(find.textContaining('Chỉ xem. Xác nhận số suất'), findsOneWidget);

    for (final (path, title) in [
      (RoutePaths.vicePrincipalMealConfirm, 'Số suất hôm nay'),
      (RoutePaths.vicePrincipalChildren, 'Trẻ của cơ sở'),
      (
        RoutePaths.vicePrincipalNutritionOf('choi', DateTime(2026, 10, 12)),
        'Cân đối dinh dưỡng',
      ),
    ]) {
      router.go(path);
      await tester.pumpAndSettle();
      expect(find.text(title), findsOneWidget, reason: path);
      expect(find.byType(NavigationBar), findsNothing, reason: path);
    }
    expect(find.text('Nhóm Chồi · Thứ Hai, 12/10 · chỉ xem'), findsOneWidget);
  });

  testWidgets(
    'BGH (AUTH-21, NUT-04, NUT-14): route duyệt điều chỉnh suất, trạng thái bếp đã gỡ',
    (tester) async {
      final router = await pumpRouter(tester, enablePreview: true);
      for (final path in [
        '/vice-principal/approvals/meals/adj-mam-3a',
        '/vice-principal/kitchen',
      ]) {
        router.go(path);
        await tester.pumpAndSettle();
        expect(find.text('Không tìm thấy trang'), findsOneWidget, reason: path);
      }
    },
  );

  testWidgets('BGH (AUTH-21): tab thứ hai tên "Chờ xử lý"', (tester) async {
    final router = await pumpRouter(tester, enablePreview: true);
    for (final path in [
      RoutePaths.vicePrincipalHome,
      RoutePaths.principalHome,
    ]) {
      router.go(path);
      await tester.pumpAndSettle();
      final bar = tester.widget<NavigationBar>(find.byType(NavigationBar));
      final labels = bar.destinations
          .whereType<NavigationDestination>()
          .map((destination) => destination.label)
          .toList();
      expect(labels, contains('Chờ xử lý'), reason: path);
      expect(labels, isNot(contains('Duyệt')), reason: path);
    }
  });

  testWidgets('Hiệu trưởng: màn con ẩn thanh đáy; Tài khoản mở Cơ sở', (
    tester,
  ) async {
    final router = await pumpRouter(tester, enablePreview: true);
    for (final (path, title) in [
      (
        RoutePaths.principalRewardBatch('batch-main-year'),
        'Khen thưởng cuối năm',
      ),
      (RoutePaths.principalChildren, 'Danh sách trẻ'),
      (
        RoutePaths.principalClassChildrenOf('campus-2', 'cs2-la-1'),
        'Trẻ của lớp',
      ),
      (RoutePaths.principalMenu, 'Thực đơn tuần'),
      (
        RoutePaths.principalNutritionOf(
          'campus-2',
          'nha-tre',
          DateTime(2026, 10, 12),
        ),
        'Cân đối dinh dưỡng',
      ),
    ]) {
      router.go(path);
      await tester.pumpAndSettle();
      expect(find.text(title), findsOneWidget, reason: path);
      expect(find.byType(NavigationBar), findsNothing, reason: path);
    }
    expect(
      find.text('Nhóm Nhà trẻ · Thứ Hai, 12/10 · chỉ xem'),
      findsOneWidget,
    );

    router.go(RoutePaths.principalAccount);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cơ sở của trường'));
    await tester.pumpAndSettle();
    expect(find.text('Thầy Lê Văn Bình'), findsOneWidget);

    router.go(RoutePaths.vicePrincipalAccount);
    await tester.pumpAndSettle();
    expect(find.text('Cơ sở của trường'), findsNothing);
  });

  testWidgets(
    'AC-3: Xem thử có 5 vai trò, mỗi vai trò đúng 4 tab theo mockup',
    (tester) async {
      final router = await pumpRouter(tester, enablePreview: true);
      router.go(RoutePaths.preview);
      await tester.pumpAndSettle();

      const roles = {
        'Phụ huynh': ['Trang chủ', 'Bé của tôi', 'Thông báo', 'Tài khoản'],
        'Giáo viên': ['Trang chủ', 'Lớp học', 'Thông báo', 'Tài khoản'],
        'Nhân viên bếp': ['Trang chủ', 'Thực đơn', 'Thông báo', 'Tài khoản'],
        'Phó Hiệu trưởng': ['Trang chủ', 'Chờ xử lý', 'Thông báo', 'Tài khoản'],
        'Hiệu trưởng': ['Tổng quan', 'Chờ xử lý', 'Thông báo', 'Tài khoản'],
      };
      for (final MapEntry(key: role, value: tabs) in roles.entries) {
        router.go(RoutePaths.preview);
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text(role));
        await tester.tap(find.text(role));
        await tester.pumpAndSettle();
        final bar = find.byType(NavigationBar);
        for (final label in tabs) {
          expect(
            find.descendant(of: bar, matching: find.text(label)),
            findsOneWidget,
            reason: '$role · $label',
          );
        }
      }
    },
  );

  testWidgets(
    'Plan 14/11 AC-6 (AUTH-21): GV kiêm phụ huynh mở chế độ GV, chuyển ở Tài khoản, lần sau mở chế độ cuối',
    (tester) async {
      AppMode.resetForTest();
      addTearDown(AppMode.resetForTest);
      final router = await pumpRouter(tester, enablePreview: true);
      Future<void> openTab(String label) async {
        await tester.tap(
          find.descendant(
            of: find.byType(NavigationBar),
            matching: find.text(label),
          ),
        );
        await tester.pumpAndSettle();
      }

      Future<void> openDual() async {
        router.go(RoutePaths.preview);
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Giáo viên kiêm phụ huynh'));
        await tester.tap(find.text('Giáo viên kiêm phụ huynh'));
        await tester.pumpAndSettle();
      }

      await openDual();
      expect(find.text('Lớp học'), findsWidgets);
      await openTab('Tài khoản');
      await tester.tap(find.text('Chuyển sang chế độ phụ huynh'));
      await tester.pumpAndSettle();
      expect(find.text('Bé của tôi'), findsWidgets);
      await openTab('Tài khoản');
      expect(find.text('Trần Thu Hà'), findsOneWidget);
      expect(find.text('Chuyển sang chế độ giáo viên'), findsOneWidget);
      // Mở lại phiên ⇒ giữ chế độ dùng lần cuối (phụ huynh)
      await openDual();
      expect(find.text('Bé của tôi'), findsWidgets);
      // Tài khoản chỉ có một vai trò ⇒ không có nút chuyển chế độ
      router.go(RoutePaths.preview);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Phụ huynh'));
      await tester.pumpAndSettle();
      await openTab('Tài khoản');
      expect(find.text('Nguyễn Thu Lan'), findsOneWidget);
      expect(find.textContaining('Chuyển sang chế độ'), findsNothing);
    },
  );

  testWidgets('Đường dẫn không tồn tại ⇒ "Không tìm thấy trang"', (
    tester,
  ) async {
    final router = await pumpRouter(tester, enablePreview: true);
    router.go('/khong-co');
    await tester.pumpAndSettle();
    expect(find.text('Không tìm thấy trang'), findsOneWidget);
  });
  testWidgets('AC-2: release vẫn có Quên mật khẩu, gửi mã ⇒ báo chưa kết nối', (
    tester,
  ) async {
    await pumpRouter(tester, enablePreview: false);
    await tester.tap(find.text('Quên mật khẩu?'));
    await tester.pumpAndSettle();
    expect(find.byType(ForgotPasswordScreen), findsOneWidget);
    await tester.enterText(find.byType(TextField), '0912345678');
    await tester.tap(find.text('Gửi mã OTP'));
    await tester.pump();
    expect(find.textContaining('chưa được kết nối'), findsOneWidget);
    expect(find.byType(OtpVerifyScreen), findsNothing);
  });

  testWidgets(
    'Debug: Quên mật khẩu → OTP (số đã che) → Đặt mật khẩu → Đăng nhập',
    (tester) async {
      final router = await pumpRouter(tester, enablePreview: true);
      router.push(RoutePaths.forgotPassword);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '0912 345 678');
      await tester.tap(find.text('Gửi mã OTP'));
      await tester.pumpAndSettle();
      expect(find.textContaining('091••••678'), findsOneWidget);

      await tester.enterText(find.byType(TextField), '482615');
      await tester.pump();
      await tester.tap(find.text('Xác nhận mã'));
      await tester.pumpAndSettle();
      expect(find.text('Đặt mật khẩu mới'), findsOneWidget);

      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), 'matkhau1');
      await tester.enterText(fields.at(1), 'matkhau1');
      await tester.pump();
      await tester.tap(find.text('Lưu mật khẩu'));
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);
    },
  );

  testWidgets('Thông báo: mở chi tiết ẩn thanh đáy, Back về danh sách', (
    tester,
  ) async {
    final router = await pumpRouter(tester, enablePreview: true);
    router.go(RoutePaths.teacherNotifications);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Phụ huynh bé Minh Anh gửi đơn nghỉ 13/10'));
    await tester.pumpAndSettle();
    expect(find.text('Chi tiết thông báo'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets(
    'Tài khoản: Thông tin cá nhân mở màn con; Đăng xuất về Đăng nhập',
    (tester) async {
      final router = await pumpRouter(tester, enablePreview: true);
      router.go(RoutePaths.principalAccount);
      await tester.pumpAndSettle();
      expect(find.text('Nguyễn Thị Hồng'), findsOneWidget);

      await tester.tap(find.text('Thông tin cá nhân'));
      await tester.pumpAndSettle();
      expect(find.text('Lưu thay đổi'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Đăng xuất'));
      await tester.tap(find.text('Đăng xuất'));
      await tester.pumpAndSettle();
      // Hỏi lại trước khi đăng xuất (P19)
      await tester.tap(find.text('Đăng xuất').last);
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);
    },
  );
}
