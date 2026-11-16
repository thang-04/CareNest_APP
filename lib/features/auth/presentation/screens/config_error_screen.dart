import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:carenest_app/core/constants/app_icons.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/theme/app_theme.dart';
import 'package:carenest_app/core/widgets/app_state_view.dart';

/// App chạy với BE thật mà thiếu biến `--dart-define` bắt buộc (CODING_GUIDE §1.2): báo tên biến, không chạy tiếp.
class ConfigErrorApp extends StatelessWidget {
  const ConfigErrorApp({super.key, required this.missingKeys});

  final List<String> missingKeys;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CareNest',
      debugShowCheckedModeBanner: false,
      theme: buildLightTheme(),
      locale: const Locale('vi'),
      supportedLocales: const [Locale('vi')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.pagePadding),
              child: AppEmptyState(
                icon: AppIcons.alertTriangle,
                title: 'Thiếu cấu hình',
                message:
                    'Thiếu ${missingKeys.join(', ')}. Chạy App với '
                    '--dart-define-from-file=env/local.json.',
              ),
            ),
          ),
        ),
      ),
    );
  }
}
