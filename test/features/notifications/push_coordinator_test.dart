import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:carenest_app/core/integration/mobile_api.dart';
import 'package:carenest_app/core/integration/mobile_session.dart';
import 'package:carenest_app/features/notifications/data/push_coordinator.dart';

class FakeSession extends MobileSession {
  int? owner;
  @override
  int? get userId => owner;
  @override
  bool get signedIn => owner != null;
}

class FakeProvider implements PushProvider {
  final tokenController = StreamController<String>.broadcast(sync: true);
  final openController = StreamController<int>.broadcast(sync: true);
  final foregroundController = StreamController<int>.broadcast(sync: true);
  bool allowed = true;
  String? currentToken = 'fake-token-a';
  @override
  Future<void> initialize() async {}
  @override
  Future<bool> requestPermission() async => allowed;
  @override
  Future<String?> token() async => currentToken;
  @override
  Future<int?> initialNotification() async => null;
  @override
  Stream<String> get tokenChanges => tokenController.stream;
  @override
  Stream<int> get opened => openController.stream;
  @override
  Stream<int> get foreground => foregroundController.stream;
  Future<void> close() async {
    await tokenController.close();
    await openController.close();
    await foregroundController.close();
  }
}

class FakeApi extends MobileApi {
  FakeApi(super.session);
  final calls = <String>[];
  bool offline = false;
  @override
  Future<void> registerDevice(String token) async {
    calls.add('register:${session.userId}:$token');
    if (offline) throw Exception('offline');
  }

  @override
  Future<void> unregisterDevice(String token) async {
    calls.add('unregister:${session.userId}:$token');
    if (offline) throw Exception('offline');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  testWidgets(
    'giữ ID qua đăng nhập và dedup theo tài khoản, kể cả tạo coordinator mới',
    (tester) async {
      final session = FakeSession();
      final opened = <int>[];
      final coordinator = PushCoordinator(
        session,
        MobileApi(session),
        opened.add,
      );
      coordinator.open(42);
      await tester.pump();
      expect(opened, isEmpty);
      session.owner = 1;
      await coordinator.startSession();
      expect(opened, [42]);
      coordinator.open(42);
      await tester.pumpAndSettle();
      expect(opened, [42]);
      final restarted = PushCoordinator(
        session,
        MobileApi(session),
        opened.add,
      );
      restarted.open(42);
      await tester.pumpAndSettle();
      expect(opened, [42]);
      session.owner = 2;
      restarted.open(42);
      await tester.pumpAndSettle();
      expect(opened, [42, 42]);
      await coordinator.dispose();
      await restarted.dispose();
    },
  );

  test(
    'không hiển thị lặp trong App cho cùng userId và notificationId',
    () async {
      final session = FakeSession()..owner = 1;
      final displayed = <int>[];
      final coordinator = PushCoordinator(
        session,
        MobileApi(session),
        (_) {},
        onForeground: displayed.add,
      );
      await coordinator.receiveForeground(12);
      await coordinator.receiveForeground(12);
      session.owner = 2;
      await coordinator.receiveForeground(12);
      expect(displayed, [12, 12]);
      await coordinator.dispose();
    },
  );

  test('đăng ký, đổi token, logout và tài khoản mới dùng đúng phiên', () async {
    final session = FakeSession()..owner = 1;
    final provider = FakeProvider();
    final api = FakeApi(session);
    final coordinator = PushCoordinator(
      session,
      api,
      (_) {},
      provider: provider,
    );
    expect(await coordinator.initialize(), isTrue);
    await coordinator.startSession();
    provider.tokenController.add('fake-token-b');
    await Future<void>.delayed(Duration.zero);
    expect(await coordinator.stopSession(), isTrue);
    session.owner = 2;
    provider.currentToken = 'fake-token-b';
    await coordinator.startSession();
    expect(api.calls, [
      'register:1:fake-token-a',
      'unregister:1:fake-token-a',
      'register:1:fake-token-b',
      'unregister:1:fake-token-b',
      'register:2:fake-token-b',
    ]);
    await coordinator.dispose();
    await provider.close();
  });

  test(
    'logout ngoại tuyến báo chưa hủy token và không nhận đăng ký tiếp',
    () async {
      final session = FakeSession()..owner = 1;
      final provider = FakeProvider();
      final api = FakeApi(session);
      final coordinator = PushCoordinator(
        session,
        api,
        (_) {},
        provider: provider,
      );
      await coordinator.initialize();
      await coordinator.startSession();
      api.offline = true;
      expect(await coordinator.stopSession(), isFalse);
      provider.tokenController.add('fake-token-new');
      await Future<void>.delayed(Duration.zero);
      expect(api.calls, [
        'register:1:fake-token-a',
        'unregister:1:fake-token-a',
      ]);
      await coordinator.dispose();
      await provider.close();
    },
  );

  test(
    'từ chối quyền không đăng ký token nhưng vẫn xử lý đích đang chờ',
    () async {
      final session = FakeSession()..owner = 1;
      final provider = FakeProvider()..allowed = false;
      final api = FakeApi(session);
      final opened = <int>[];
      final coordinator = PushCoordinator(
        session,
        api,
        opened.add,
        provider: provider,
      );
      await coordinator.initialize();
      provider.openController.add(91);
      await coordinator.startSession();
      await Future<void>.delayed(Duration.zero);
      expect(opened, [91]);
      expect(api.calls, isEmpty);
      expect(await coordinator.stopSession(), isTrue);
      expect(api.calls, ['unregister:1:fake-token-a']);
      await coordinator.dispose();
      await provider.close();
    },
  );
}
