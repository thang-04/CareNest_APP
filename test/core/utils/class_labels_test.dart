import 'package:flutter_test/flutter_test.dart';

import 'package:carenest_app/core/utils/class_labels.dart';

void main() {
  test('classLabel_noDoublePrefix', () {
    expect(classLabel('Mầm 3A'), 'Lớp Mầm 3A');
    expect(classLabel('Lớp Nhà trẻ 1'), 'Lớp Nhà trẻ 1');
    expect(classLabel('Lớp Nhà trẻ 1', lower: true), 'lớp Nhà trẻ 1');
    expect(classLabel('Mầm 3A', lower: true), 'lớp Mầm 3A');
  });
}
