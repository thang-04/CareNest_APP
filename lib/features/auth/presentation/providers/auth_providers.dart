import 'package:dio/dio.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;

import 'package:carenest_app/core/config/env.dart';
import 'package:carenest_app/core/network/api_providers.dart';
import 'package:carenest_app/core/storage/last_mode_store.dart';
import 'package:carenest_app/core/storage/secure_store.dart';
import 'package:carenest_app/core/storage/token_storage.dart';
import 'package:carenest_app/features/auth/data/datasources/account_remote_data_source.dart';
import 'package:carenest_app/features/auth/data/datasources/app_auth_oidc_client.dart';
import 'package:carenest_app/features/auth/data/datasources/oidc_client.dart';
import 'package:carenest_app/features/auth/data/session_manager.dart';
import 'package:carenest_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:carenest_app/features/auth/presentation/controllers/auth_state.dart';

final secureStoreProvider = Provider<SecureStore>(
  (ref) => const FlutterSecureStore(),
);

final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

final tokenStorageProvider = Provider<TokenStorage>(
  (ref) => TokenStorage(ref.watch(secureStoreProvider), env: Env.appEnv),
);

final lastModeStoreProvider = Provider<LastModeStore>(
  (ref) => LastModeStore(ref.watch(secureStoreProvider), env: Env.appEnv),
);

final oidcClientProvider = Provider<OidcClient>(
  (ref) => AppAuthOidcClient(
    appAuth: const FlutterAppAuth(),
    plainDio: Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 20),
      ),
    ),
    issuer: Env.oidcIssuer,
    clientId: Env.oidcClientId,
    redirectUri: Env.oidcRedirectUri,
  ),
);

final sessionManagerProvider = Provider<SessionManager>((ref) {
  final session = SessionManager(
    oidc: ref.watch(oidcClientProvider),
    storage: ref.watch(tokenStorageProvider),
    now: ref.watch(clockProvider),
  );
  ref.onDispose(session.dispose);
  return session;
});

final accountRemoteDataSourceProvider = Provider<AccountRemoteDataSource>(
  (ref) => AccountRemoteDataSource(ref.watch(apiClientProvider)),
);

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);

/// Ghép nguồn token của API client với phiên đăng nhập; dùng ở bootstrap và test.
final authOverrides = <Override>[
  accessTokenSourceProvider.overrideWith(
    (ref) => ref.watch(sessionManagerProvider),
  ),
];
