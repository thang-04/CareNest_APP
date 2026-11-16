import 'package:flutter/foundation.dart';

import 'package:carenest_app/features/parent_home/data/fake_parent_home_source.dart';

/// Con đang xem, dùng chung Trang chủ và tab Bé của tôi (ngữ cảnh là state, không nằm trong route).
/// Tạm là `ValueNotifier` toàn cục tới khi nối BE phụ huynh; về Đăng nhập phải reset (bản thật ở `app.dart`).
abstract final class SelectedChild {
  static final notifier = ValueNotifier<String>(
    FakeParentHomeSource.children.first.id,
  );

  static void reset() =>
      notifier.value = FakeParentHomeSource.children.first.id;
}
