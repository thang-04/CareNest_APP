import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:carenest_app/core/integration/load_failure.dart';
import 'package:carenest_app/core/integration/mobile_api.dart';

void main() {
  const network = 'Kiểm tra kết nối mạng rồi thử lại.';

  test('loadFailureMessage_beRejection_showsBeReason', () {
    expect(
      loadFailureMessage(
        ApiFailure(403, 'Bạn chỉ xem được thông tin của con mình', 4108),
      ),
      'Bạn chỉ xem được thông tin của con mình',
    );
    expect(
      loadFailureMessage(ApiFailure(404, 'Không tìm thấy trẻ', 4001)),
      'Không tìm thấy trẻ',
    );
  });

  test('loadFailureMessage_networkOrServer_asksToCheckNetwork', () {
    expect(loadFailureMessage(const SocketException('offline')), network);
    expect(loadFailureMessage(ApiFailure(503, 'Bảo trì')), network);
    // 401: luồng đăng nhập lo, màn không nói "hết phiên" thay
    expect(loadFailureMessage(ApiFailure(401, 'Bạn cần đăng nhập.')), network);
  });
}
