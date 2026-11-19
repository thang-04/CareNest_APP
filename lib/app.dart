import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

import 'package:carenest_app/core/theme/app_theme.dart';
import 'package:carenest_app/routing/app_router.dart';
import 'package:carenest_app/core/integration/mobile_api.dart';
import 'package:carenest_app/core/integration/mobile_session.dart';
import 'package:carenest_app/features/notifications/data/push_coordinator.dart';

class CareNestApp extends StatefulWidget {
  const CareNestApp({super.key});

  @override
  State<CareNestApp> createState() => _CareNestAppState();
}

class _CareNestAppState extends State<CareNestApp> {
  // Giữ một router suốt vòng đời app, không tạo lại mỗi lần build
  late final MobileSession _session = MobileSession();
  late final MobileApi _api = MobileApi(_session);
  late final GoRouter _router = buildAppRouter(
    session: _session,
    api: _api,
    signIn: _signIn,
    signOut: _signOut,
  );
  final _messengerKey = GlobalKey<ScaffoldMessengerState>();
  late final PushCoordinator _push = PushCoordinator(
    _session,
    _api,
    (id) => _router.go('/live/notifications/$id'),
    onForeground: (id) {
      _messengerKey.currentState?.showSnackBar(
        SnackBar(
          content: const Text('Bạn có thông báo mới.'),
          action: SnackBarAction(label: 'Xem', onPressed: () => _push.open(id)),
        ),
      );
    },
  );

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _push.initialize();
    await _session.restore();
    if (_session.signedIn) {
      _router.go('/live/notifications');
      try {
        await _push.startSession();
      } catch (_) {
        /* Danh sách vẫn dùng được khi đăng ký push lỗi. */
      }
    }
  }

  Future<void> _signIn() async {
    await _session.signIn();
    _router.go('/live/notifications');
    try {
      await _push.startSession();
    } catch (_) {
      /* Không chặn đọc thông báo trong App. */
    }
  }

  Future<void> _signOut() async {
    final removed = await _push.stopSession();
    await _session.signOut();
    _router.go('/login');
    if (!removed && mounted) {
      _messengerKey.currentState?.showSnackBar(
        const SnackBar(
          content: Text(
            'Đã đăng xuất trên máy; chưa thể hủy đăng ký thông báo khi ngoại tuyến.',
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _push.dispose();
    _session.dispose();
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      scaffoldMessengerKey: _messengerKey,
      title: 'CareNest',
      debugShowCheckedModeBanner: false,
      theme: buildLightTheme(),
      themeMode: ThemeMode.light,
      locale: const Locale('vi'),
      supportedLocales: const [Locale('vi')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      routerConfig: _router,
    );
  }
}
