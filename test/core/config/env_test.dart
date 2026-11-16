import 'package:flutter_test/flutter_test.dart';

import 'package:carenest_app/core/config/env.dart';

void main() {
  group('Env.missingKeys', () {
    test('missingKeys_mock_needsNothing', () {
      expect(
        Env.missingKeys(useMock: true, apiBaseUrl: '', oidcIssuer: ''),
        isEmpty,
      );
    });

    test('missingKeys_real_listsMissing', () {
      expect(Env.missingKeys(useMock: false, apiBaseUrl: '', oidcIssuer: ''), [
        'API_BASE_URL',
        'OIDC_ISSUER',
      ]);
    });

    test('missingKeys_real_onlyIssuerMissing', () {
      expect(
        Env.missingKeys(
          useMock: false,
          apiBaseUrl: 'http://localhost:8080/api',
          oidcIssuer: '',
        ),
        ['OIDC_ISSUER'],
      );
    });

    test('missingKeys_real_complete', () {
      expect(
        Env.missingKeys(
          useMock: false,
          apiBaseUrl: 'http://localhost:8080/api',
          oidcIssuer: 'http://localhost:8180/realms/carenest',
        ),
        isEmpty,
      );
    });
  });

  test('oidcDefaults_matchBeMobileClient', () {
    expect(Env.oidcClientId, 'carenest-mobile');
    expect(Env.oidcRedirectUri, 'carenest://oauth/callback');
  });
}
