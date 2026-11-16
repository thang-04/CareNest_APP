import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:carenest_app/app.dart';
import 'package:carenest_app/core/config/env.dart';
import 'package:carenest_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:carenest_app/features/auth/presentation/screens/config_error_screen.dart';

/// Gốc widget của App: thiếu cấu hình bắt buộc ⇒ màn báo lỗi; còn lại ⇒ ghép provider rồi chạy App.
Widget bootstrap() => buildRoot(
  missingKeys: Env.missingKeys(
    useMock: Env.useMock,
    apiBaseUrl: Env.apiBaseUrl,
    oidcIssuer: Env.oidcIssuer,
  ),
);

Widget buildRoot({required List<String> missingKeys}) {
  if (missingKeys.isNotEmpty) return ConfigErrorApp(missingKeys: missingKeys);
  return ProviderScope(overrides: authOverrides, child: const CareNestApp());
}
