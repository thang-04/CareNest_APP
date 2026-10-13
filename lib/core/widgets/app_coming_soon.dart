import 'package:flutter/material.dart';

import 'package:carenest_app/core/constants/app_icons.dart';
import 'package:carenest_app/core/widgets/app_state_view.dart';

/// Tab/màn chưa làm trong đợt này: báo rõ, không dẫn vào trang trống.
class AppComingSoon extends StatelessWidget {
  const AppComingSoon({super.key, this.title = 'Sắp có'});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: AppEmptyState(
          icon: AppIcons.construction,
          title: title,
          message: 'Tính năng này sẽ có trong bản sau.',
        ),
      ),
    );
  }
}

/// Mở màn con "Sắp có" cho lối vào trỏ tới màn ngoài phạm vi đợt này.
void openComingSoon(BuildContext context, String title) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => Scaffold(
        appBar: AppBar(title: Text(title)),
        body: AppComingSoon(title: title),
      ),
    ),
  );
}
