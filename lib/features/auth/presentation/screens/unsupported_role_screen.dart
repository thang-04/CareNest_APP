import 'package:flutter/material.dart';

import 'package:carenest_app/core/constants/app_icons.dart';
import 'package:carenest_app/core/widgets/app_state_view.dart';

/// Vai trò không có trên App (BGH, Admin — AUTH-21): báo rõ, không mặc định Giáo viên (DESIGN.md §B5.2).
class UnsupportedRoleScreen extends StatelessWidget {
  const UnsupportedRoleScreen({super.key, required this.onSignOut});

  final Future<void> Function() onSignOut;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: AppEmptyState(
              icon: AppIcons.shieldPerson,
              title: 'Tài khoản này dùng trên Web',
              message:
                  'Ứng dụng dành cho phụ huynh, giáo viên và nhân viên bếp. '
                  'Vui lòng đăng nhập CareNest trên máy tính.',
              actionLabel: 'Đăng xuất',
              onAction: onSignOut,
            ),
          ),
        ),
      ),
    );
  }
}
