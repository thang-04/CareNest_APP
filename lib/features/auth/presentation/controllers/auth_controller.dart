import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:carenest_app/core/errors/app_failure.dart';
import 'package:carenest_app/features/auth/data/datasources/oidc_client.dart';
import 'package:carenest_app/features/auth/data/session_manager.dart';
import 'package:carenest_app/features/auth/domain/entities/app_mode.dart';
import 'package:carenest_app/features/auth/domain/entities/app_user.dart';
import 'package:carenest_app/features/auth/presentation/controllers/auth_state.dart';
import 'package:carenest_app/features/auth/presentation/providers/auth_providers.dart';

/// Điều phối phiên: khôi phục, đăng nhập, tải `/accounts/me`, chọn chế độ, đăng xuất.
class AuthController extends Notifier<AuthState> {
  // Quay lại App sau ít nhất ngần này thì tải lại tài khoản (quyền/khóa tài khoản đổi ở BE)
  static const _refetchGap = Duration(seconds: 60);

  DateTime? _lastFetch;

  SessionManager get _session => ref.read(sessionManagerProvider);
  DateTime _now() => ref.read(clockProvider)();

  @override
  AuthState build() {
    final subscription = ref
        .watch(sessionManagerProvider)
        .sessionEnded
        .listen((_) => signOut(notice: AuthNotice.sessionExpired));
    ref.onDispose(subscription.cancel);
    return const AuthChecking();
  }

  Future<void> start() async {
    state = const AuthChecking();
    final RestoreResult result;
    try {
      result = await _session.restore();
    } on OidcUnavailable {
      if (ref.mounted) state = const AuthRetryNeeded(NetworkFailure());
      return;
    }
    if (!ref.mounted) return;
    switch (result) {
      case RestoreResult.noSession:
        state = const AuthSignedOut();
      case RestoreResult.ended:
        state = const AuthSignedOut(notice: AuthNotice.sessionExpired);
      case RestoreResult.restored:
        await _loadUser();
    }
  }

  Future<void> retry() => start();

  Future<void> signIn({String? loginHint}) async {
    state = const AuthSigningIn();
    try {
      await _session.signIn(loginHint: loginHint);
    } on OidcCancelled {
      if (ref.mounted) {
        state = const AuthSignedOut(notice: AuthNotice.signInCancelled);
      }
      return;
    } on OidcFailure {
      if (ref.mounted) {
        state = const AuthSignedOut(notice: AuthNotice.signInFailed);
      }
      return;
    }
    if (ref.mounted) await _loadUser();
  }

  Future<void> signOut({AuthNotice? notice}) async {
    await _session.signOut();
    _lastFetch = null;
    if (ref.mounted) state = AuthSignedOut(notice: notice);
  }

  /// Chỉ đổi sang chế độ tài khoản được dùng; nhớ cho lần mở App sau (user 14/11).
  Future<void> switchMode(AppMode mode) async {
    final current = state;
    if (current is! AuthSignedIn || !current.user.modes.contains(mode)) return;
    await ref.read(lastModeStoreProvider).write(current.user.userId, mode.name);
    if (ref.mounted) state = AuthSignedIn(current.user, mode);
  }

  Future<void> onResumed() async {
    if (state is! AuthSignedIn) return;
    final last = _lastFetch;
    if (last != null && _now().difference(last) < _refetchGap) return;
    await _loadUser();
  }

  Future<void> _loadUser() async {
    final AppUser user;
    try {
      user = await ref.read(accountRemoteDataSourceProvider).fetchMe();
    } on ForbiddenFailure catch (failure) {
      // 1101 ở /accounts/me = token App không có role App (BGH, Admin — ADR-0022)
      if (ref.mounted) {
        state = AuthBlocked(
          failure.errorCode == ApiErrorCodes.forbidden
              ? AuthBlockReason.webOnlyAccount
              : AuthBlockReason.accountUnavailable,
        );
      }
      return;
    } on UnauthenticatedFailure {
      await signOut(notice: AuthNotice.sessionExpired);
      return;
    } on AppFailure catch (failure) {
      if (ref.mounted) state = AuthRetryNeeded(failure);
      return;
    }
    _lastFetch = _now();
    if (!ref.mounted) return;

    final modes = user.modes;
    if (modes.isEmpty) {
      state = AuthBlocked(
        user.hasAppRole
            ? AuthBlockReason.accountUnavailable
            : AuthBlockReason.webOnlyAccount,
      );
      return;
    }
    final saved = await ref.read(lastModeStoreProvider).read(user.userId);
    final remembered = AppMode.values.asNameMap()[saved];
    if (!ref.mounted) return;
    state = AuthSignedIn(
      user,
      remembered != null && modes.contains(remembered)
          ? remembered
          : modes.first,
    );
  }
}
