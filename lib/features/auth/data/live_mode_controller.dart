import 'package:flutter/foundation.dart';

import 'package:carenest_app/core/integration/mobile_session.dart';
import 'package:carenest_app/core/storage/last_mode_store.dart';
import 'package:carenest_app/features/auth/domain/entities/app_mode.dart';
import 'package:carenest_app/features/auth/domain/entities/app_user.dart';
import 'package:carenest_app/features/parent/parent_home/presentation/selected_child.dart';

/// Chế độ dùng App của phiên thật (ADR-0022, user 14/11): mở chế độ nhân sự trước,
/// chuyển sang phụ huynh ở Tài khoản, nhớ chế độ cuối theo tài khoản. Chế độ không gửi lên BE.
class LiveModeController extends ChangeNotifier {
  LiveModeController(
    this._session,
    this._store, {
    this.readTimeout = const Duration(seconds: 3),
  }) {
    _session.addListener(_sync);
    _sync();
  }

  final MobileSession _session;
  final LastModeStore _store;

  /// Router chờ đọc chế độ cuối; kho treo quá hạn ⇒ dùng chế độ đầu, không kẹt App.
  final Duration readTimeout;

  int? _userId;
  List<AppMode> _modes = const [];
  AppMode? _mode;
  Future<void> _ready = Future.value();

  /// Người dùng đã tự chọn chế độ trong phiên này ⇒ không lấy chế độ đã lưu đè lên.
  bool _switched = false;

  AppMode? get mode => _mode;
  List<AppMode> get modes => _modes;

  /// Xong khi đã đọc chế độ cuối của phiên hiện tại.
  Future<void> get ready => _ready;

  void _sync() {
    final account = _session.signedIn ? _session.account : null;
    final user = account == null ? null : AppUser.fromAccount(account);
    if (user?.userId == _userId) {
      // Cùng phiên, `/accounts/me` tải lại ⇒ chỉ cập nhật danh sách chế độ
      if (user != null) _setModes(user.modes);
      return;
    }
    _userId = user?.userId;
    if (user == null) {
      _modes = const [];
      _mode = null;
      // AUTH-22: máy dùng chung ⇒ người sau không thấy con của người trước
      SelectedChild.reset();
      notifyListeners();
      return;
    }
    _modes = user.modes;
    _mode = _modes.isEmpty ? null : _modes.first;
    _switched = false;
    // Gán trước khi báo: router chờ `ready` rồi mới chọn màn, không nhảy qua chế độ tạm
    _ready = _restore(user.userId);
    notifyListeners();
  }

  void _setModes(List<AppMode> modes) {
    if (listEquals(modes, _modes)) return;
    _modes = modes;
    if (!modes.contains(_mode)) _mode = modes.isEmpty ? null : modes.first;
    notifyListeners();
  }

  Future<void> _restore(int userId) async {
    String? stored;
    try {
      stored = await _store.read(userId).timeout(readTimeout);
    } catch (_) {
      // Không đọc được chế độ cuối ⇒ dùng chế độ đầu
      return;
    }
    if (userId != _userId || _switched) return;
    final saved = _modes.where((m) => m.name == stored).firstOrNull;
    if (saved != null && saved != _mode) {
      _mode = saved;
      notifyListeners();
    }
  }

  Future<void> switchTo(AppMode mode) async {
    final userId = _userId;
    if (userId == null || !_modes.contains(mode) || mode == _mode) return;
    _switched = true;
    _mode = mode;
    notifyListeners();
    try {
      await _store.write(userId, mode.name);
    } catch (_) {
      // Không lưu được chỉ mất "nhớ chế độ cuối"; chế độ hiện tại vẫn đổi
    }
  }

  @override
  void dispose() {
    _session.removeListener(_sync);
    super.dispose();
  }
}
