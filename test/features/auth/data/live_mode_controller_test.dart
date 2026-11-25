import 'package:flutter_test/flutter_test.dart';

import 'package:carenest_app/core/storage/last_mode_store.dart';
import 'package:carenest_app/core/storage/secure_store.dart';
import 'package:carenest_app/features/auth/data/live_mode_controller.dart';
import 'package:carenest_app/features/auth/domain/entities/app_mode.dart';
import 'package:carenest_app/features/parent/parent_home/data/fake_parent_home_source.dart';
import 'package:carenest_app/features/parent/parent_home/presentation/selected_child.dart';

import '../../../helpers/live_fakes.dart';

void main() {
  late MemorySecureStore secure;
  late LastModeStore store;

  setUp(() {
    secure = MemorySecureStore();
    store = LastModeStore(secure, env: 'test');
  });
  tearDown(SelectedChild.reset);

  Future<LiveModeController> start(FakeLiveSession session) async {
    final controller = LiveModeController(session, store);
    addTearDown(controller.dispose);
    await controller.ready;
    return controller;
  }

  test('signIn_teacherParent_noStored_opensTeacher', () async {
    final c = await start(
      FakeLiveSession(['TEACHER', 'PARENT'], childIds: [9]),
    );
    expect(c.mode, AppMode.teacher);
    expect(c.modes, [AppMode.teacher, AppMode.parent]);
  });

  test('signIn_storedParent_opensParent', () async {
    await store.write(4, 'parent');
    final c = await start(
      FakeLiveSession(['TEACHER', 'PARENT'], childIds: [9]),
    );
    expect(c.mode, AppMode.parent);
  });

  test('signIn_storedModeNoLongerAllowed_opensFirst', () async {
    await store.write(4, 'parent');
    final c = await start(FakeLiveSession(['TEACHER', 'PARENT']));
    expect(c.mode, AppMode.teacher);
  });

  test('switchTo_parent_persistsAndNotifies', () async {
    final session = FakeLiveSession(['TEACHER', 'PARENT'], childIds: [9]);
    final c = await start(session);
    var calls = 0;
    c.addListener(() => calls++);

    await c.switchTo(AppMode.parent);

    expect(c.mode, AppMode.parent);
    expect(calls, 1);
    final again = await start(session);
    expect(again.mode, AppMode.parent);
  });

  test('switchTo_modeNotAllowed_ignored', () async {
    final c = await start(FakeLiveSession(['TEACHER']));
    await c.switchTo(AppMode.parent);
    expect(c.mode, AppMode.teacher);
    expect(secure.values, isEmpty);
  });

  test('signOut_clearsModeAndSelectedChild', () async {
    final session = FakeLiveSession(['PARENT'], childIds: [9]);
    final c = await start(session);
    SelectedChild.notifier.value = FakeParentHomeSource.children.last.id;

    await session.signOut();

    expect(c.mode, isNull);
    expect(c.modes, isEmpty);
    expect(
      SelectedChild.notifier.value,
      FakeParentHomeSource.children.first.id,
    );
  });

  test('switchDuringRestore_userChoiceWins', () async {
    final slow = SlowSecureStore({'carenest.test.last_mode.4': 'parent'});
    final c = LiveModeController(
      FakeLiveSession(['TEACHER', 'KITCHEN_STAFF', 'PARENT'], childIds: [9]),
      LastModeStore(slow, env: 'test'),
    );
    addTearDown(c.dispose);

    await c.switchTo(AppMode.kitchen);
    slow.release();
    await c.ready;

    expect(c.mode, AppMode.kitchen);
  });

  test('ready_setBeforeFirstNotify', () async {
    final slow = SlowSecureStore({'carenest.test.last_mode.4': 'parent'});
    final session = FakeLiveSession(['TEACHER', 'PARENT'], childIds: [9]);
    await session.signOut();
    final c = LiveModeController(session, LastModeStore(slow, env: 'test'));
    addTearDown(c.dispose);
    Future<void>? seen;
    c.addListener(() => seen ??= c.ready);

    session.account = {
      'userId': 4,
      'roles': ['TEACHER', 'PARENT'],
      'childIds': [9],
    };
    session.notifyListeners();
    slow.release();
    await seen;

    expect(c.mode, AppMode.parent);
  });

  test('storeReadHangs_opensFirstModeAfterTimeout', () async {
    final slow = SlowSecureStore({'carenest.test.last_mode.4': 'parent'});
    final c = LiveModeController(
      FakeLiveSession(['TEACHER', 'PARENT'], childIds: [9]),
      LastModeStore(slow, env: 'test'),
      readTimeout: const Duration(milliseconds: 20),
    );
    addTearDown(c.dispose);

    await c.ready;

    expect(c.mode, AppMode.teacher);
  });

  test('signIn_parent_selectsFirstRealChild', () async {
    SelectedChild.notifier.value = FakeParentHomeSource.children.first.id;
    await start(FakeLiveSession(['PARENT'], childIds: [5, 3]));
    expect(SelectedChild.notifier.value, '5');
  });

  test('signIn_parent_keepsSelectedChildInList', () async {
    SelectedChild.notifier.value = '3';
    await start(FakeLiveSession(['PARENT'], childIds: [5, 3]));
    expect(SelectedChild.notifier.value, '3');
  });

  test('signIn_principalOnly_modeNull', () async {
    final c = await start(FakeLiveSession(['PRINCIPAL']));
    expect(c.mode, isNull);
  });

  test('storeReadFails_opensFirstMode', () async {
    final c = LiveModeController(
      FakeLiveSession(['TEACHER', 'PARENT'], childIds: [9]),
      LastModeStore(_ThrowingStore(), env: 'test'),
    );
    addTearDown(c.dispose);
    await c.ready;
    expect(c.mode, AppMode.teacher);
  });
}

class _ThrowingStore implements SecureStore {
  @override
  Future<String?> read(String key) async => throw StateError('no plugin');

  @override
  Future<void> write(String key, String value) async =>
      throw StateError('no plugin');

  @override
  Future<void> delete(String key) async {}
}
