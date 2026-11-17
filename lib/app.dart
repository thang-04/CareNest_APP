import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:carenest_app/core/config/env.dart';
import 'package:carenest_app/core/theme/app_theme.dart';
import 'package:carenest_app/features/auth/presentation/controllers/auth_state.dart';
import 'package:carenest_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:carenest_app/features/parent/parent_home/presentation/selected_child.dart';
import 'package:carenest_app/routing/app_router.dart';

/// `useMock` (mặc định theo `USE_MOCK`): `true` ⇒ dữ liệu giả + Xem thử như trước;
/// `false` ⇒ đăng nhập Keycloak, chuyển màn theo phiên.
class CareNestApp extends ConsumerStatefulWidget {
  const CareNestApp({super.key, this.useMock = Env.useMock});

  final bool useMock;

  @override
  ConsumerState<CareNestApp> createState() => _CareNestAppState();
}

class _CareNestAppState extends ConsumerState<CareNestApp>
    with WidgetsBindingObserver {
  // Báo router chạy lại redirect mỗi khi AuthState đổi
  final _authChanges = ValueNotifier(0);

  // Giữ một router suốt vòng đời app, không tạo lại mỗi lần build
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    if (widget.useMock) {
      _router = buildAppRouter();
      return;
    }
    ref.listenManual(authControllerProvider, (_, next) {
      // Mọi đường về Đăng nhập (đăng xuất, hết phiên, 401) ⇒ người sau không thấy ngữ cảnh con của người trước
      if (next is AuthSignedOut) SelectedChild.reset();
      _authChanges.value++;
    });
    _router = buildAppRouter(
      refresh: _authChanges,
      readAuth: () => ref.read(authControllerProvider),
      onSignOut: () => ref.read(authControllerProvider.notifier).signOut(),
      onSwitchMode: (mode) =>
          ref.read(authControllerProvider.notifier).switchMode(mode),
    );
    WidgetsBinding.instance.addObserver(this);
    Future.microtask(() {
      if (mounted) ref.read(authControllerProvider.notifier).start();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Quay lại App ⇒ tải lại tài khoản: quyền/khóa tài khoản có thể đã đổi ở BE
    if (state == AppLifecycleState.resumed) {
      ref.read(authControllerProvider.notifier).onResumed();
    }
  }

  @override
  void dispose() {
    if (!widget.useMock) WidgetsBinding.instance.removeObserver(this);
    _router.dispose();
    _authChanges.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
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
