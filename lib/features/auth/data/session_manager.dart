import 'dart:async';

import 'package:carenest_app/core/errors/app_failure.dart';
import 'package:carenest_app/core/network/auth_interceptor.dart';
import 'package:carenest_app/core/storage/token_storage.dart';
import 'package:carenest_app/features/auth/data/datasources/oidc_client.dart';

enum RestoreResult {
  /// Có refresh token và Keycloak cấp token mới.
  restored,

  /// Chưa đăng nhập trên máy này.
  noSession,

  /// Refresh token hết hạn hoặc bị thu hồi ⇒ đã xóa, cần đăng nhập lại.
  ended,
}

/// Giữ phiên Keycloak: access token chỉ trong bộ nhớ, refresh token + id token trong secure storage
/// (CODING_GUIDE §5.3–5.5). Một lần refresh dùng chung cho mọi request cùng lúc.
class SessionManager implements AccessTokenSource {
  SessionManager({
    required this._oidc,
    required this._storage,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  // Token còn ít hơn mức này thì refresh trước khi gửi (access token BE sống 5 phút)
  static const _refreshMargin = Duration(seconds: 30);

  final OidcClient _oidc;
  final TokenStorage _storage;
  final DateTime Function() _now;
  final _ended = StreamController<void>.broadcast();

  String? _access;
  DateTime? _expiresAt;
  String? _refresh;
  String? _idToken;
  Future<bool>? _inFlight;

  // Tăng mỗi lần đăng nhập/đăng xuất: kết quả refresh của phiên cũ bị bỏ
  int _generation = 0;

  /// Phát khi refresh bị Keycloak từ chối lúc đang dùng App (phiên hết hạn/bị thu hồi).
  Stream<void> get sessionEnded => _ended.stream;

  Future<void> signIn({String? loginHint}) async {
    final tokens = await _oidc.signIn(loginHint: loginHint);
    _generation++;
    await _storage.write(
      StoredTokens(refreshToken: tokens.refreshToken, idToken: tokens.idToken),
    );
    _apply(tokens);
  }

  /// Khôi phục phiên lúc mở App. Mạng/Keycloak lỗi ⇒ ném [OidcUnavailable], giữ token để thử lại.
  Future<RestoreResult> restore() async {
    final stored = await _storage.read();
    if (stored == null) return RestoreResult.noSession;
    _refresh = stored.refreshToken;
    _idToken = stored.idToken;
    final ok = await _refreshShared(notifyEnded: false);
    return ok ? RestoreResult.restored : RestoreResult.ended;
  }

  @override
  Future<String?> validAccessToken() async {
    if (_refresh == null) return null;
    final expiresAt = _expiresAt;
    if (_access != null &&
        expiresAt != null &&
        expiresAt.difference(_now()) > _refreshMargin) {
      return _access;
    }
    return await _refreshForRequest() ? _access : null;
  }

  @override
  Future<bool> refreshAfterUnauthorized() => _refreshForRequest();

  Future<void> signOut() async {
    _generation++;
    final refresh = _refresh;
    _clearMemory();
    await _storage.clear();
    if (refresh == null) return;
    try {
      await _oidc.revoke(refresh);
    } on OidcFailure {
      // Thu hồi ở Keycloak là best-effort; token trên máy đã xóa (CODING_GUIDE §5.6)
    }
  }

  void dispose() => _ended.close();

  // Request đang chạy: lỗi mạng khi refresh ⇒ NetworkFailure, không coi là hết phiên
  Future<bool> _refreshForRequest() async {
    try {
      return await _refreshShared(notifyEnded: true);
    } on OidcUnavailable {
      throw const NetworkFailure();
    }
  }

  Future<bool> _refreshShared({required bool notifyEnded}) {
    return _inFlight ??= _doRefresh(
      notifyEnded: notifyEnded,
    ).whenComplete(() => _inFlight = null);
  }

  Future<bool> _doRefresh({required bool notifyEnded}) async {
    final generation = _generation;
    final refresh = _refresh;
    if (refresh == null) return false;
    try {
      final tokens = await _oidc.refresh(refresh);
      if (generation != _generation) return false;
      await _storage.write(
        StoredTokens(
          refreshToken: tokens.refreshToken,
          idToken: tokens.idToken ?? _idToken,
        ),
      );
      _apply(tokens);
      return true;
    } on OidcInvalidGrant {
      if (generation != _generation) return false;
      _generation++;
      _clearMemory();
      await _storage.clear();
      if (notifyEnded && !_ended.isClosed) _ended.add(null);
      return false;
    }
  }

  void _apply(OidcTokens tokens) {
    _access = tokens.accessToken;
    _expiresAt = tokens.accessTokenExpiresAt;
    _refresh = tokens.refreshToken;
    _idToken = tokens.idToken ?? _idToken;
  }

  void _clearMemory() {
    _access = null;
    _expiresAt = null;
    _refresh = null;
    _idToken = null;
  }
}
