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

  // Tăng ở mỗi start/signIn/signOut: kết quả đến muộn của lượt cũ bị bỏ, không đưa người dùng cũ trở lại
  int _session = 0;

  SessionManager get _sessionManager => ref.read(sessionManagerProvider);
  DateTime _now() => ref.read(clockProvider)();
  bool _isCurrent(int session) => ref.mounted && session == _session;

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
    final session = ++_session;
    state = const AuthChecking();
    final RestoreResult result;
    try {
      result = await _sessionManager.restore();
    } on OidcUnavailable catch (failure) {
      if (_isCurrent(session)) {
        state = AuthRetryNeeded(
          failure.network ? const NetworkFailure() : const ServerFailure(),
        );
      }
      return;
    } catch (_) {
      // Lỗi lạ (vd. secure storage hỏng) ⇒ vẫn có lối Thử lại / Đăng xuất, không kẹt màn chờ
      if (_isCurrent(session)) state = const AuthRetryNeeded(ServerFailure());
      return;
    }
    if (!_isCurrent(session)) return;
    switch (result) {
      case RestoreResult.noSession:
        state = const AuthSignedOut();
      case RestoreResult.ended:
        state = const AuthSignedOut(notice: AuthNotice.sessionExpired);
      case RestoreResult.restored:
        await _loadUser(session);
    }
  }

  Future<void> retry() => start();

  Future<void> signIn({String? loginHint}) async {
    final session = ++_session;
    state = const AuthSigningIn();
    try {
      await _sessionManager.signIn(loginHint: loginHint);
    } on OidcCancelled {
      if (_isCurrent(session)) {
        state = const AuthSignedOut(notice: AuthNotice.signInCancelled);
      }
      return;
    } catch (_) {
      if (_isCurrent(session)) {
        state = const AuthSignedOut(notice: AuthNotice.signInFailed);
      }
      return;
    }
    if (_isCurrent(session)) await _loadUser(session);
  }

  Future<void> signOut({AuthNotice? notice}) async {
    final session = ++_session;
    _lastFetch = null;
    try {
      await _sessionManager.signOut();
    } catch (_) {
      // Xóa token trên máy lỗi vẫn phải rời màn của người dùng (máy dùng chung — AUTH-22)
    } finally {
      if (_isCurrent(session)) state = AuthSignedOut(notice: notice);
    }
  }

  /// Chỉ đổi sang chế độ tài khoản được dùng; nhớ cho lần mở App sau (user 14/11).
  Future<void> switchMode(AppMode mode) async {
    final current = state;
    if (current is! AuthSignedIn || !current.user.modes.contains(mode)) return;
    final session = _session;
    await ref.read(lastModeStoreProvider).write(current.user.userId, mode.name);
    if (_isCurrent(session)) state = AuthSignedIn(current.user, mode);
  }

  Future<void> onResumed() async {
    if (state is! AuthSignedIn) return;
    final last = _lastFetch;
    if (last != null && _now().difference(last) < _refetchGap) return;
    await _loadUser(_session, background: true);
  }

  /// `background`: tải lại khi quay về App — lỗi mạng/BE giữ nguyên màn đang dùng, lần sau thử lại.
  Future<void> _loadUser(int session, {bool background = false}) async {
    final AppUser user;
    try {
      user = await ref.read(accountRemoteDataSourceProvider).fetchMe();
    } on ForbiddenFailure catch (failure) {
      // 1101 ở /accounts/me = token App không có role App (BGH, Admin — ADR-0022)
      if (_isCurrent(session)) {
        state = AuthBlocked(
          failure.errorCode == ApiErrorCodes.forbidden
              ? AuthBlockReason.webOnlyAccount
              : AuthBlockReason.accountUnavailable,
        );
      }
      return;
    } on UnauthenticatedFailure {
      if (_isCurrent(session)) {
        await signOut(notice: AuthNotice.sessionExpired);
      }
      return;
    } on AppFailure catch (failure) {
      if (!background && _isCurrent(session)) {
        state = AuthRetryNeeded(failure);
      }
      return;
    } catch (_) {
      if (!background && _isCurrent(session)) {
        state = const AuthRetryNeeded(ServerFailure());
      }
      return;
    }
    if (!_isCurrent(session)) return;
    _lastFetch = _now();

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
    if (!_isCurrent(session)) return;
    final remembered = AppMode.values.asNameMap()[saved];
    // Quay về App: giữ chế độ đang dùng nếu vẫn hợp lệ
    final current = state;
    final keep = current is AuthSignedIn && modes.contains(current.mode)
        ? current.mode
        : null;
    state = AuthSignedIn(
      user,
      keep ??
          (remembered != null && modes.contains(remembered)
              ? remembered
              : modes.first),
    );
  }
}
