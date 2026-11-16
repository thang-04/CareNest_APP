import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:carenest_app/core/errors/app_failure.dart';
import 'package:carenest_app/core/storage/secure_store.dart';
import 'package:carenest_app/core/storage/token_storage.dart';
import 'package:carenest_app/features/auth/data/datasources/oidc_client.dart';
import 'package:carenest_app/features/auth/data/session_manager.dart';

import '../../../helpers/fake_oidc_client.dart';

void main() {
  late DateTime now;
  late FakeOidcClient oidc;
  late TokenStorage storage;
  late SessionManager session;

  setUp(() {
    now = DateTime(2026, 11, 16, 9);
    oidc = FakeOidcClient();
    storage = TokenStorage(MemorySecureStore(), env: 'test');
    session = SessionManager(oidc: oidc, storage: storage, now: () => now);
  });

  tearDown(() => session.dispose());

  Future<void> signedIn({int minutes = 5}) async {
    oidc.signInResults.add(fakeTokens('1', now: now, minutes: minutes));
    await session.signIn();
  }

  test('signIn_storesRefreshAndIdToken', () async {
    oidc.signInResults.add(fakeTokens('1', now: now));

    await session.signIn(loginHint: '0900000001');

    final stored = await storage.read();
    expect(stored?.refreshToken, 'r1');
    expect(stored?.idToken, 'i1');
    expect(oidc.lastLoginHint, '0900000001');
    expect(await session.validAccessToken(), 'a1');
  });

  test('restore_noStoredTokens_returnsNoSession', () async {
    expect(await session.restore(), RestoreResult.noSession);
    expect(oidc.refreshCalls, 0);
  });

  test('restore_validRefresh_restoredAndRotates', () async {
    await storage.write(const StoredTokens(refreshToken: 'r1', idToken: 'i1'));
    oidc.refreshResults.add(fakeTokens('2', now: now));

    expect(await session.restore(), RestoreResult.restored);

    expect(oidc.refreshedWith, ['r1']);
    expect((await storage.read())?.refreshToken, 'r2');
    expect(await session.validAccessToken(), 'a2');
  });

  test('restore_refreshWithoutIdToken_keepsStoredIdToken', () async {
    await storage.write(const StoredTokens(refreshToken: 'r1', idToken: 'i1'));
    oidc.refreshResults.add(
      OidcTokens(
        accessToken: 'a2',
        accessTokenExpiresAt: now.add(const Duration(minutes: 5)),
        refreshToken: 'r2',
      ),
    );

    await session.restore();

    expect((await storage.read())?.idToken, 'i1');
  });

  test('restore_expiredRefresh_signsOut', () async {
    await storage.write(const StoredTokens(refreshToken: 'r1'));
    oidc.refreshResults.add(const OidcInvalidGrant());

    expect(await session.restore(), RestoreResult.ended);

    expect(await storage.read(), isNull);
    expect(await session.validAccessToken(), isNull);
  });

  test('restore_networkError_keepsTokens', () async {
    await storage.write(const StoredTokens(refreshToken: 'r1'));
    oidc.refreshResults.add(const OidcUnavailable('offline'));

    await expectLater(session.restore(), throwsA(isA<OidcUnavailable>()));

    expect((await storage.read())?.refreshToken, 'r1');
  });

  test('validAccessToken_noSession_returnsNull', () async {
    expect(await session.validAccessToken(), isNull);
  });

  test('validAccessToken_valid_noRefresh', () async {
    await signedIn();

    expect(await session.validAccessToken(), 'a1');
    expect(oidc.refreshCalls, 0);
  });

  test('validAccessToken_nearExpiry_refreshesFirst', () async {
    await signedIn();
    now = now.add(const Duration(minutes: 4, seconds: 50));
    oidc.refreshResults.add(fakeTokens('2', now: now));

    expect(await session.validAccessToken(), 'a2');
    expect(oidc.refreshCalls, 1);
  });

  test('validAccessToken_refreshNetworkError_throwsNetworkFailure', () async {
    await signedIn(minutes: 0);
    oidc.refreshResults.add(const OidcUnavailable('offline'));

    await expectLater(
      session.validAccessToken(),
      throwsA(isA<NetworkFailure>()),
    );
    expect((await storage.read())?.refreshToken, 'r1');
  });

  test('refresh_concurrentCalls_singleFlight', () async {
    await signedIn();
    final pending = Completer<OidcTokens>();
    oidc.refreshResults.add(pending);

    final calls = [
      session.refreshAfterUnauthorized(),
      session.refreshAfterUnauthorized(),
      session.refreshAfterUnauthorized(),
    ];
    pending.complete(fakeTokens('2', now: now));

    expect(await Future.wait(calls), [true, true, true]);
    expect(oidc.refreshCalls, 1);
    expect(await session.validAccessToken(), 'a2');
  });

  test('refresh_invalidGrant_emitsSessionEnded', () async {
    await signedIn();
    oidc.refreshResults.add(const OidcInvalidGrant());
    final ended = expectLater(session.sessionEnded, emits(anything));

    expect(await session.refreshAfterUnauthorized(), isFalse);

    await ended;
    expect(await storage.read(), isNull);
  });

  test('refresh_networkError_throwsNetworkFailure', () async {
    await signedIn();
    oidc.refreshResults.add(const OidcUnavailable('offline'));

    await expectLater(
      session.refreshAfterUnauthorized(),
      throwsA(isA<NetworkFailure>()),
    );
  });

  test('signOut_revokesStoredRefreshToken', () async {
    await signedIn();

    await session.signOut();

    expect(oidc.revoked, ['r1']);
    expect(await storage.read(), isNull);
    expect(await session.validAccessToken(), isNull);
  });

  test('signOut_duringRefresh_doesNotRestoreSession', () async {
    await signedIn();
    final pending = Completer<OidcTokens>();
    oidc.refreshResults.add(pending);

    final refresh = session.refreshAfterUnauthorized();
    await session.signOut();
    pending.complete(fakeTokens('2', now: now));

    expect(await refresh, isFalse);
    expect(await storage.read(), isNull);
    expect(await session.validAccessToken(), isNull);
  });

  test('signOut_duringRefreshStorageWrite_doesNotRestoreSession', () async {
    final gated = _GatedStore();
    final gatedStorage = TokenStorage(gated, env: 'test');
    final s = SessionManager(oidc: oidc, storage: gatedStorage, now: () => now);
    addTearDown(s.dispose);
    oidc.signInResults.add(fakeTokens('1', now: now));
    await s.signIn();
    oidc.refreshResults.add(fakeTokens('2', now: now));
    gated.gate = Completer<void>();

    final refresh = s.refreshAfterUnauthorized();
    await Future<void>.delayed(Duration.zero);
    final signOut = s.signOut();
    gated.gate!.complete();
    await signOut;

    expect(await refresh, isFalse);
    expect(await s.validAccessToken(), isNull);
    expect(await gatedStorage.read(), isNull);
  });

  test('refresh_rejectedByProvider_throwsServerFailure', () async {
    await signedIn();
    oidc.refreshResults.add(
      const OidcUnavailable('unauthorized_client', network: false),
    );

    await expectLater(
      session.refreshAfterUnauthorized(),
      throwsA(isA<ServerFailure>()),
    );
  });

  test('signOut_revokeFails_stillClears', () async {
    await signedIn();
    oidc.revokeError = const OidcUnavailable('offline');

    await session.signOut();

    expect(await storage.read(), isNull);
    expect(await session.validAccessToken(), isNull);
  });
}

/// Store giữ lệnh ghi refresh token tới khi mở cổng (đăng xuất chen vào giữa lúc ghi).
class _GatedStore extends MemorySecureStore {
  Completer<void>? gate;

  @override
  Future<void> write(String key, String value) async {
    final pending = gate;
    if (pending != null && key.endsWith('refresh_token')) await pending.future;
    return super.write(key, value);
  }
}
