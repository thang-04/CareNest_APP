import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:carenest_app/core/widgets/app_password_field.dart';
import 'package:carenest_app/core/widgets/app_text_field.dart';

import '../../helpers/pump_app.dart';

void main() {
  testWidgets('AC-4: hiện label và lỗi dưới trường', (tester) async {
    await pumpWithTheme(
      tester,
      const AppTextField(
        label: 'Email',
        hint: 'ten@gmail.com',
        errorText: 'Email chưa đúng định dạng',
      ),
    );
    expect(find.text('Email', findRichText: true), findsOneWidget);
    expect(find.text('Email chưa đúng định dạng'), findsOneWidget);
  });

  testWidgets('AC-4: trường bắt buộc có dấu * và semantics "bắt buộc"', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpWithTheme(
      tester,
      const AppTextField(label: 'Họ và tên', isRequired: true),
    );
    expect(find.text('Họ và tên *', findRichText: true), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('Họ và tên, bắt buộc')), findsWidgets);
    handle.dispose();
  });

  testWidgets('AC-4: mật khẩu ẩn mặc định, nút ẩn/hiện có tooltip', (
    tester,
  ) async {
    await pumpWithTheme(tester, const AppPasswordField());
    EditableText editable() =>
        tester.widget<EditableText>(find.byType(EditableText));

    expect(editable().obscureText, isTrue);
    expect(find.byTooltip('Hiện mật khẩu'), findsOneWidget);

    await tester.tap(find.byTooltip('Hiện mật khẩu'));
    await tester.pump();
    expect(editable().obscureText, isFalse);
    expect(find.byTooltip('Ẩn mật khẩu'), findsOneWidget);
  });

  testWidgets('validator chạy khi người dùng nhập', (tester) async {
    await pumpWithTheme(
      tester,
      AppTextField(
        label: 'Mã',
        validator: (v) => (v ?? '').isEmpty ? 'Hãy nhập mã' : null,
      ),
    );
    await tester.enterText(find.byType(TextFormField), 'a');
    await tester.enterText(find.byType(TextFormField), '');
    await tester.pump();
    expect(find.text('Hãy nhập mã'), findsOneWidget);
  });
}
