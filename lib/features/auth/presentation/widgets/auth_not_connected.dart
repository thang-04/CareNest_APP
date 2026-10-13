import 'package:carenest_app/core/widgets/app_banner.dart';

/// Banner dùng chung khi màn xác thực chưa nối AUTH_CONTRACT (`BE:docs/contracts/AUTH_CONTRACT.md` SKELETON).
const authNotConnectedBanner = AppBanner(
  message: 'Chức năng này chưa được kết nối với máy chủ trong bản này.',
);
