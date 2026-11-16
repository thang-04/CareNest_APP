import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:carenest_app/core/errors/app_failure.dart';
import 'package:carenest_app/core/network/api_providers.dart';
import 'package:carenest_app/core/storage/last_mode_store.dart';
import 'package:carenest_app/core/storage/secure_store.dart';
import 'package:carenest_app/core/storage/token_storage.dart';
import 'package:carenest_app/features/auth/data/datasources/oidc_client.dart';
import 'package:carenest_app/features/auth/domain/entities/app_mode.dart';
import 'package:carenest_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:carenest_app/features/auth/presentation/controllers/auth_state.dart';
import 'package:carenest_app/features/auth/presentation/providers/auth_providers.dart';

import '../../../helpers/fake_http_adapter.dart';
import '../../../helpers/fake_me.dart';
import '../../../helpers/fake_oidc_client.dart';

class _Harness {
  _Harness({MemorySecureStore? store}) : store = store ?? MemorySecureStore() {
    container = ProviderContainer(
      overrides: [
        ...authOverrides,
        secureStoreProvider.overrideWithValue(this.store),
        oidcClientProvider.overrideWithValue(oidc),
        httpClientAdapterProvider.overrideWithValue(http),
        apiBaseUrlProvider.overrideWithValue('http://localhost:8080/api'),
        clockProvider.overrideWithValue(() => now),
      ],
    );
  }

  final MemorySecureStore store;
  final oidc = FakeOidcClient();
  final http = FakeHttpAdapter();
  DateTime now = DateTime(2026, 11, 16, 9);
  late final ProviderContainer container;

  AuthController get controller =>
      container.read(authControllerProvider.notifier);
  AuthState get state => container.read(authControllerProvider);
  TokenStorage get tokens => container.read(tokenStorageProvider);
  LastModeStore get modes => container.read(lastModeStoreProvider);

  Future<void> storedSession() =>
      tokens.write(const StoredTokens(refreshToken: 'r0'));
  void refreshOk() => oidc.refreshResults.add(fakeTokens('1', now: now));
  void me({
    List<String> roles = const ['TEACHER'],
    List<int> childIds = const [],
  }) => http.enqueue(
    FakeReply.envelope(
      200,
      data: fakeMe(roles: roles, childIds: childIds),
    ),
  );

  Future<void> restoredAs({
    List<String> roles = const ['TEACHER'],
    List<int> childIds = const [],
  }) async {
    await storedSession();
    refreshOk();
    me(roles: roles, childIds: childIds);
    await controller.start();
  }
}

Matcher _signedIn(AppMode mode) =>
    isA<AuthSignedIn>().having((s) => s.mode, 'mode', mode);

Matcher _blocked(AuthBlockReason reason) =>
    isA<AuthBlocked>().having((s) => s.reason, 'reason', reason);

Matcher _signedOut([AuthNotice? notice]) =>
    isA<AuthSignedOut>().having((s) => s.notice, 'notice', notice);

Future<void> _settle(bool Function() done) async {
  for (var i = 0; i < 20 && !done(); i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  late _Harness h;

  setUp(() => h = _Harness());
  tearDown(() => h.container.dispose());

  test('start_noSession_signedOut', () async {
    await h.controller.start();

    expect(h.state, _signedOut());
  });

  test('start_restoredTeacher_signedInTeacher', () async {
    await h.restoredAs(roles: ['TEACHER']);

    expect(h.state, _signedIn(AppMode.teacher));
    expect(h.http.requests.single.headers['Authorization'], 'Bearer a1');
  });

  test('start_kitchen_onlyKitchenMode', () async {
    await h.restoredAs(roles: ['KITCHEN_STAFF']);

    expect(h.state, _signedIn(AppMode.kitchen));
  });

  test('start_teacherParent_opensTeacher_thenRemembersParent', () async {
    await h.restoredAs(roles: ['TEACHER', 'PARENT'], childIds: [7]);
    expect(h.state, _signedIn(AppMode.teacher));

    await h.controller.switchMode(AppMode.parent);
    expect(h.state, _signedIn(AppMode.parent));

    final reopened = _Harness(store: h.store);
    addTearDown(reopened.container.dispose);
    reopened.refreshOk();
    reopened.me(roles: ['TEACHER', 'PARENT'], childIds: [7]);
    await reopened.controller.start();

    expect(reopened.state, _signedIn(AppMode.parent));
  });

  test('switchMode_notAllowed_ignored', () async {
    await h.restoredAs(roles: ['TEACHER']);

    await h.controller.switchMode(AppMode.parent);

    expect(h.state, _signedIn(AppMode.teacher));
  });

  test('start_principal403_1101_blockedWebOnly', () async {
    await h.storedSession();
    h.refreshOk();
    h.http.enqueue(FakeReply.envelope(403, errorCode: 1101));

    await h.controller.start();

    expect(h.state, _blocked(AuthBlockReason.webOnlyAccount));
  });

  test('start_principalRolesOnly_blockedWebOnly', () async {
    await h.restoredAs(roles: ['PRINCIPAL']);

    expect(h.state, _blocked(AuthBlockReason.webOnlyAccount));
  });

  test('start_inactive1015_blockedUnavailable', () async {
    await h.storedSession();
    h.refreshOk();
    h.http.enqueue(FakeReply.envelope(403, errorCode: 1015));

    await h.controller.start();

    expect(h.state, _blocked(AuthBlockReason.accountUnavailable));
  });

  test('start_parentWithoutChildren_blockedUnavailable', () async {
    await h.restoredAs(roles: ['PARENT']);

    expect(h.state, _blocked(AuthBlockReason.accountUnavailable));
  });

  test('start_meServiceUnavailable_showsRetry', () async {
    await h.storedSession();
    h.refreshOk();
    h.http.enqueue(FakeReply.envelope(503, errorCode: 1013));

    await h.controller.start();

    expect(
      h.state,
      isA<AuthRetryNeeded>().having(
        (s) => s.failure,
        'failure',
        isA<ServiceUnavailableFailure>(),
      ),
    );
    expect((await h.tokens.read())?.refreshToken, 'r1');
  });

  test('start_restoreNetworkError_showsRetryAndKeepsTokens', () async {
    await h.storedSession();
    h.oidc.refreshResults.add(const OidcUnavailable('offline'));

    await h.controller.start();

    expect(h.state, isA<AuthRetryNeeded>());
    expect((await h.tokens.read())?.refreshToken, 'r0');
  });

  test('start_expiredRefresh_signedOutWithExpiredNotice', () async {
    await h.storedSession();
    h.oidc.refreshResults.add(const OidcInvalidGrant());

    await h.controller.start();

    expect(h.state, _signedOut(AuthNotice.sessionExpired));
  });

  test('retry_afterServiceUnavailable_signsIn', () async {
    await h.storedSession();
    h.refreshOk();
    h.http.enqueue(FakeReply.envelope(503, errorCode: 1013));
    await h.controller.start();

    h.oidc.refreshResults.add(fakeTokens('2', now: h.now));
    h.me(roles: ['TEACHER']);
    await h.controller.retry();

    expect(h.state, _signedIn(AppMode.teacher));
  });

  test('signIn_success_loadsUser', () async {
    h.oidc.signInResults.add(fakeTokens('1', now: h.now));
    h.me(roles: ['KITCHEN_STAFF']);

    await h.controller.signIn(loginHint: '0900000001');

    expect(h.state, _signedIn(AppMode.kitchen));
    expect(h.oidc.lastLoginHint, '0900000001');
  });

  test('signIn_cancelled_signedOutWithNotice', () async {
    h.oidc.signInResults.add(const OidcCancelled());

    await h.controller.signIn();

    expect(h.state, _signedOut(AuthNotice.signInCancelled));
  });

  test('signIn_providerError_signedOutWithFailedNotice', () async {
    h.oidc.signInResults.add(const OidcUnavailable('offline'));

    await h.controller.signIn();

    expect(h.state, _signedOut(AuthNotice.signInFailed));
  });

  test('signOut_clearsUserAndMode', () async {
    await h.restoredAs(roles: ['TEACHER', 'PARENT'], childIds: [7]);
    await h.controller.switchMode(AppMode.parent);

    await h.controller.signOut();

    expect(h.state, _signedOut());
    expect(await h.tokens.read(), isNull);
    expect(h.oidc.revoked, ['r1']);
    expect(await h.modes.read(12), 'parent');
  });

  test('sessionEnded_signsOutWithExpiredNotice', () async {
    await h.restoredAs(roles: ['TEACHER']);
    h.oidc.refreshResults.add(const OidcInvalidGrant());

    await h.container.read(sessionManagerProvider).refreshAfterUnauthorized();
    await _settle(() => h.state is AuthSignedOut);

    expect(h.state, _signedOut(AuthNotice.sessionExpired));
  });

  test('onResumed_inactiveAccount_blocks', () async {
    await h.restoredAs(roles: ['TEACHER']);
    h.now = h.now.add(const Duration(seconds: 61));
    h.http.enqueue(FakeReply.envelope(403, errorCode: 1015));

    await h.controller.onResumed();

    expect(h.state, _blocked(AuthBlockReason.accountUnavailable));
  });

  test('onResumed_withinMinute_skipsFetch', () async {
    await h.restoredAs(roles: ['TEACHER']);
    h.now = h.now.add(const Duration(seconds: 30));

    await h.controller.onResumed();

    expect(h.http.requests, hasLength(1));
    expect(h.state, _signedIn(AppMode.teacher));
  });

  group('review fixes', () {
    test('onResumed_networkError_staysSignedIn', () async {
      await h.restoredAs(roles: ['TEACHER']);
      h.now = h.now.add(const Duration(seconds: 61));
      h.http.enqueue(FakeReply.envelope(503, errorCode: 1013));

      await h.controller.onResumed();

      expect(h.state, _signedIn(AppMode.teacher));
    });

    test('onResumed_afterFailure_retriesOnNextResume', () async {
      await h.restoredAs(roles: ['TEACHER']);
      h.now = h.now.add(const Duration(seconds: 61));
      h.http.enqueue(FakeReply.envelope(503, errorCode: 1013));
      await h.controller.onResumed();

      h.now = h.now.add(const Duration(seconds: 5));
      h.http.enqueue(FakeReply.envelope(403, errorCode: 1015));
      await h.controller.onResumed();

      expect(h.state, _blocked(AuthBlockReason.accountUnavailable));
    });

    test('signOut_whileResumeRefetchInFlight_staysSignedOut', () async {
      await h.restoredAs(roles: ['TEACHER']);
      h.now = h.now.add(const Duration(seconds: 61));
      final late = Completer<FakeReply>();
      h.http.enqueueLater(late.future);

      final resumed = h.controller.onResumed();
      await Future<void>.delayed(Duration.zero);
      await h.controller.signOut();
      late.complete(FakeReply.envelope(200, data: fakeMe(roles: ['TEACHER'])));
      await resumed;

      expect(h.state, _signedOut());
    });

    test('signOut_whileSignInLoadsAccount_staysSignedOut', () async {
      h.oidc.signInResults.add(fakeTokens('1', now: h.now));
      final late = Completer<FakeReply>();
      h.http.enqueueLater(late.future);

      final signingIn = h.controller.signIn();
      await _settle(() => h.http.requests.isNotEmpty);
      await h.controller.signOut();
      late.complete(FakeReply.envelope(200, data: fakeMe(roles: ['TEACHER'])));
      await signingIn;

      expect(h.state, _signedOut());
    });

    test('signOut_doesNotWaitForRevoke', () async {
      await h.restoredAs(roles: ['TEACHER']);
      h.oidc.revokeGate = Completer<void>().future;

      await h.controller.signOut().timeout(const Duration(seconds: 1));

      expect(h.state, _signedOut());
      expect(await h.tokens.read(), isNull);
      expect(h.oidc.revoked, ['r1']);
    });

    test('start_keycloakRejectsRefresh_showsGenericRetry', () async {
      await h.storedSession();
      h.oidc.refreshResults.add(
        const OidcUnavailable('unauthorized_client', network: false),
      );

      await h.controller.start();

      expect(
        h.state,
        isA<AuthRetryNeeded>().having(
          (s) => s.failure,
          'failure',
          isA<ServerFailure>(),
        ),
      );
    });

    test('start_unexpectedStorageError_showsRetry', () async {
      final broken = _Harness(store: _ThrowingStore());
      addTearDown(broken.container.dispose);

      await broken.controller.start();

      expect(broken.state, isA<AuthRetryNeeded>());
    });

    test('signOut_storageError_stillSignedOut', () async {
      final store = _ThrowingStore(throwOnRead: false);
      final failing = _Harness(store: store);
      addTearDown(failing.container.dispose);
      await failing.restoredAs(roles: ['TEACHER']);
      store.throwOnDelete = true;

      await failing.controller.signOut();

      expect(failing.state, _signedOut());
    });
  });
}

/// Store lỗi không phải PlatformException (plugin hỏng bất thường).
class _ThrowingStore extends MemorySecureStore {
  _ThrowingStore({this.throwOnRead = true});

  final bool throwOnRead;
  bool throwOnDelete = false;

  @override
  Future<String?> read(String key) async {
    if (throwOnRead) throw StateError('storage broken');
    return super.read(key);
  }

  @override
  Future<void> delete(String key) async {
    if (throwOnDelete) throw StateError('storage broken');
    return super.delete(key);
  }
}
