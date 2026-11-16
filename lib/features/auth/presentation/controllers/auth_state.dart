import 'package:carenest_app/core/errors/app_failure.dart';
import 'package:carenest_app/features/auth/domain/entities/app_mode.dart';
import 'package:carenest_app/features/auth/domain/entities/app_user.dart';

/// Trạng thái phiên mà router và màn hình dựa vào. Không chứa token.
sealed class AuthState {
  const AuthState();
}

/// Đang khôi phục phiên lúc mở App.
final class AuthChecking extends AuthState {
  const AuthChecking();
}

final class AuthSignedOut extends AuthState {
  const AuthSignedOut({this.notice});

  final AuthNotice? notice;
}

/// Đang mở trang Keycloak hoặc tải tài khoản sau đăng nhập.
final class AuthSigningIn extends AuthState {
  const AuthSigningIn();
}

final class AuthSignedIn extends AuthState {
  const AuthSignedIn(this.user, this.mode);

  final AppUser user;
  final AppMode mode;
}

/// Tài khoản không dùng được trên App; chỉ còn nút Đăng xuất.
final class AuthBlocked extends AuthState {
  const AuthBlocked(this.reason);

  final AuthBlockReason reason;
}

/// Mất mạng hoặc BE/Keycloak tạm lỗi; giữ token, cho thử lại.
final class AuthRetryNeeded extends AuthState {
  const AuthRetryNeeded(this.failure);

  final AppFailure failure;
}

enum AuthNotice { sessionExpired, signInCancelled, signInFailed }

enum AuthBlockReason {
  /// Token App không có role App: Ban giám hiệu, Admin (BE ADR-0022, 403 1101).
  webOnlyAccount,

  /// Tài khoản bị khóa, chưa có hồ sơ (403 1015, 1014) hoặc phụ huynh không còn con đang học.
  accountUnavailable,
}
