import 'package:carenest_app/features/campus_children/domain/campus_children.dart';
import 'package:carenest_app/features/class_roster/data/fake_class_roster_source.dart';
import 'package:carenest_app/features/class_roster/domain/class_roster.dart';
import 'package:carenest_app/features/parent_home/data/fake_parent_home_source.dart';

/// Dữ liệu giả mockup V10 / H06: cơ sở chính 6 lớp, 196 trẻ (khớp V01: 182 có mặt + 9 có phép + 5 vắng);
/// cơ sở 2 có 5 lớp, 138 trẻ (toàn trường 334, khớp H01). Mầm 3A lấy từ danh sách lớp của Giáo viên;
/// ghi chú dị ứng / ăn chay các lớp cơ sở chính khớp K03. Tên là giả.
class FakeCampusChildrenSource implements CampusChildrenSource {
  FakeCampusChildrenSource({
    this.mode = FakeMode.data,
    this.delay = const Duration(milliseconds: 300),
  });

  final FakeMode mode;
  final Duration delay;

  static const mainCampusId = 'campus-main';
  static const secondCampusId = 'campus-2';

  static const campusNames = {
    mainCampusId: 'Cơ sở chính – Thượng Hồng',
    secondCampusId: 'Cơ sở 2 – An Đồng',
  };

  static const _mainClasses = [
    CampusClass(FakeClassRosterSource.classId, FakeClassRosterSource.className),
    CampusClass('class-mam-3b', 'Mầm 3B'),
    CampusClass('class-choi-1', 'Chồi 1'),
    CampusClass('class-choi-2', 'Chồi 2'),
    CampusClass('class-la-1', 'Lá 1'),
    CampusClass('class-la-2', 'Lá 2'),
  ];

  /// (lớp, sĩ số, tuổi, trẻ có tên sẵn kèm ghi chú)
  static const _secondPlan = [
    (
      'cs2-nha-tre-1',
      'Nhà trẻ 1 (CS2)',
      24,
      '2 tuổi',
      [('Tô Minh Khuê', RosterTag(RosterTagKind.allergy, 'Dị ứng trứng'))],
    ),
    ('cs2-mam-1', 'Mầm 1 (CS2)', 26, '4 tuổi', <(String, RosterTag?)>[]),
    (
      'cs2-choi-1',
      'Chồi 1 (CS2)',
      28,
      '5 tuổi',
      [('Lã Bảo Nhi', RosterTag(RosterTagKind.diet, 'Ăn chay'))],
    ),
    ('cs2-la-1', 'Lá 1 (CS2)', 30, '6 tuổi', <(String, RosterTag?)>[]),
    (
      'cs2-la-2',
      'Lá 2 (CS2)',
      30,
      '6 tuổi',
      [('Viên Gia Phúc', RosterTag(RosterTagKind.allergy, 'Dị ứng hải sản'))],
    ),
  ];

  static const _mainPlan = [
    ('class-mam-3b', 'Mầm 3B', 28, '4 tuổi', <(String, RosterTag?)>[]),
    (
      'class-choi-1',
      'Chồi 1',
      33,
      '5 tuổi',
      [
        ('Vương Thục Anh', RosterTag(RosterTagKind.diet, 'Ăn chay')),
        ('Hà Minh Quân', RosterTag(RosterTagKind.diet, 'Ăn chay')),
      ],
    ),
    (
      'class-choi-2',
      'Chồi 2',
      33,
      '5 tuổi',
      [
        ('Lê Bảo Châu', null),
        ('Nguyễn Hải Đăng', null),
        ('Trần Khả Hân', null),
        ('Đỗ Phúc Lâm', RosterTag(RosterTagKind.allergy, 'Dị ứng hải sản')),
      ],
    ),
    (
      'class-la-1',
      'Lá 1',
      36,
      '6 tuổi',
      [
        ('Phạm Thảo Nguyên', null),
        ('Mạc Tùng Lâm', RosterTag(RosterTagKind.allergy, 'Dị ứng hải sản')),
        ('Giang Bảo Anh', RosterTag(RosterTagKind.allergy, 'Dị ứng sữa bò')),
      ],
    ),
    (
      'class-la-2',
      'Lá 2',
      38,
      '6 tuổi',
      [
        ('Phan Đức Mạnh', null),
        ('Lục Diệu Linh', RosterTag(RosterTagKind.diet, 'Ăn chay')),
      ],
    ),
  ];

  static const _families = [
    'Nguyễn',
    'Trần',
    'Lê',
    'Phạm',
    'Hoàng',
    'Vũ',
    'Đặng',
    'Bùi',
    'Đỗ',
    'Hồ',
    'Ngô',
    'Dương',
  ];
  static const _given = [
    'Minh Khang',
    'Gia Hân',
    'Bảo An',
    'Thanh Tâm',
    'Đức Minh',
    'Ngọc Anh',
    'Quang Huy',
    'Khánh Vy',
    'Tuấn Anh',
    'Hải Yến',
    'Phúc An',
    'Thùy Dung',
    'Nhật Nam',
    'Mai Chi',
    'Hà Phương',
    'Trọng Nhân',
  ];

  // Cơ sở 2 dùng tên đệm khác để không trùng tên với cơ sở chính
  static const _secondGiven = [
    'An Khang',
    'Bảo Hân',
    'Minh Thư',
    'Gia Bảo',
    'Ngọc Hà',
    'Hoàng Long',
    'Thảo My',
    'Trung Kiên',
    'Diệu Anh',
    'Hữu Phước',
    'Quỳnh Chi',
    'Thiên Ân',
  ];

  static final children = [
    for (final kid in FakeClassRosterSource.kids)
      CampusChild(
        id: kid.id,
        fullName: kid.fullName,
        classId: FakeClassRosterSource.classId,
        className: FakeClassRosterSource.className,
        ageLabel: kid.ageLabel,
        // Trạng thái trong ngày (nghỉ ốm, ăn 1 bữa) không thuộc danh sách cơ sở
        tag: switch (kid.tag?.kind) {
          RosterTagKind.allergy || RosterTagKind.diet => kid.tag,
          _ => null,
        },
      ),
    ..._generate(_mainPlan, _given),
  ];

  static final secondCampusChildren = _generate(_secondPlan, _secondGiven);

  static List<CampusClass> classesOf(String campusId) => switch (campusId) {
    mainCampusId => _mainClasses,
    secondCampusId => [
      for (final (id, name, _, _, _) in _secondPlan) CampusClass(id, name),
    ],
    _ => const [],
  };

  static List<CampusChild> childrenOf(String campusId) => switch (campusId) {
    mainCampusId => children,
    secondCampusId => secondCampusChildren,
    _ => const [],
  };

  // Tên đổi lần lượt; họ dịch theo vòng. (số tên + 1) nguyên tố cùng nhau với số họ (12)
  // ⇒ không trùng tên trong mỗi cơ sở
  static List<CampusChild> _generate(
    List<(String, String, int, String, List<(String, RosterTag?)>)> plan,
    List<String> given,
  ) {
    final result = <CampusChild>[];
    var generated = 0;
    for (final (classId, className, size, age, named) in plan) {
      for (var i = 0; i < size; i++) {
        final String name;
        RosterTag? tag;
        if (i < named.length) {
          (name, tag) = named[i];
        } else {
          name =
              '${_families[(generated ~/ given.length + generated) % _families.length]} ${given[generated % given.length]}';
          generated++;
        }
        result.add(
          CampusChild(
            id: '$classId-${i + 1}',
            fullName: name,
            classId: classId,
            className: className,
            ageLabel: age,
            tag: tag,
          ),
        );
      }
    }
    return result;
  }

  @override
  Future<CampusChildren> load(String campusId) async {
    await Future<void>.delayed(delay);
    if (mode == FakeMode.error) throw StateError('Không tải được dữ liệu giả');
    return CampusChildren(
      campusName: campusNames[campusId] ?? '',
      classes: classesOf(campusId),
      children: mode == FakeMode.empty ? const [] : childrenOf(campusId),
    );
  }
}
