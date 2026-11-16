import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:carenest_app/bootstrap.dart';

void main() {
  testWidgets('buildRoot_missingKeys_showsConfigError', (tester) async {
    await tester.pumpWidget(
      buildRoot(missingKeys: const ['API_BASE_URL', 'OIDC_ISSUER']),
    );

    expect(find.text('Thiếu cấu hình'), findsOneWidget);
    expect(find.textContaining('API_BASE_URL, OIDC_ISSUER'), findsOneWidget);
    expect(find.textContaining('env/local.json'), findsOneWidget);
  });

  test('buildRoot_complete_wrapsAppInProviderScope', () {
    expect(buildRoot(missingKeys: const []), isA<ProviderScope>());
  });
}
