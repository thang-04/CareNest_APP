import 'package:carenest_app/features/class_roster/domain/class_roster.dart';

/// Lớp Mầm 3A giả (28 trẻ) dùng chung cho các màn Giáo viên; tên và số điện thoại là giả.
/// Sáu trẻ đầu theo mockup, khớp màn Phụ huynh (bé Minh Anh, mẹ Thu Lan).
class FakeClassRosterSource implements ClassRosterSource {
  const FakeClassRosterSource();

  static const classId = 'class-mam-3a';
  static const className = 'Mầm 3A';
  static const campusName = 'Cơ sở chính';

  static const _named = [
    RosterKid(
      id: 'child-1',
      fullName: 'Nguyễn Minh Anh',
      ageLabel: '4 tuổi',
      guardianLine: 'Mẹ: 0912 345 678',
    ),
    RosterKid(
      id: 'k-02',
      fullName: 'Lê Hoàng Nam',
      ageLabel: '4 tuổi',
      guardianLine: 'Mẹ: 0903 111 222',
      tag: RosterTag(RosterTagKind.allergy, 'Dị ứng hải sản'),
    ),
    RosterKid(
      id: 'k-03',
      fullName: 'Phạm Khánh Linh',
      ageLabel: '4 tuổi',
      guardianLine: 'Bố: 0977 222 333',
      tag: RosterTag(RosterTagKind.leave, 'Nghỉ ốm'),
    ),
    RosterKid(
      id: 'k-04',
      fullName: 'Vũ Đức Huy',
      ageLabel: '5 tuổi',
      guardianLine: 'Mẹ: 0934 555 666',
    ),
    RosterKid(
      id: 'k-05',
      fullName: 'Đỗ Tuấn Kiệt',
      ageLabel: '4 tuổi',
      guardianLine: 'Bố: 0988 777 888',
      tag: RosterTag(RosterTagKind.meal, 'Ăn 1 bữa'),
    ),
    RosterKid(
      id: 'k-06',
      fullName: 'Trần Bảo Ngọc',
      ageLabel: '4 tuổi',
      guardianLine: 'Mẹ: 0911 999 000',
      tag: RosterTag(RosterTagKind.diet, 'Ăn chay'),
    ),
    RosterKid(
      id: 'k-07',
      fullName: 'Phan Gia Huy',
      ageLabel: '4 tuổi',
      guardianLine: 'Ông: 0966 123 456',
    ),
  ];

  static const _givenNames = [
    'Hoàng Minh Châu',
    'Bùi Gia Thịnh',
    'Ngô Thảo Vy',
    'Đặng Quốc Bảo',
    'Lý Ngọc Hân',
    'Trịnh Đức Anh',
    'Mai Khánh An',
    'Phùng Bảo Long',
    'Tạ Thu Trang',
    'Hồ Minh Khôi',
    'Dương Tuệ Nhi',
    'Cao Gia Hưng',
    'Lưu Phương Linh',
    'Kiều Anh Tuấn',
    'Châu Mỹ Duyên',
    'Võ Nhật Minh',
    'Đinh Hà My',
    'Lâm Thành Đạt',
    'Quách Bảo Trâm',
    'Tôn Gia Khang',
    'Âu Ngọc Diệp',
  ];

  static final kids = [
    ..._named,
    for (var i = 0; i < _givenNames.length; i++)
      RosterKid(
        id: 'k-${(i + 8).toString().padLeft(2, '0')}',
        fullName: _givenNames[i],
        ageLabel: i.isEven ? '4 tuổi' : '3 tuổi',
        guardianLine:
            '${i.isEven ? 'Mẹ' : 'Bố'}: 09${(10 + i) % 100} 000 ${(100 + i * 7) % 1000}',
      ),
  ];

  static RosterKid kidById(String id) => kids.firstWhere((kid) => kid.id == id);

  @override
  Future<ClassRoster> loadRoster(String classId) async => ClassRoster(
    classId: classId,
    className: className,
    campusName: campusName,
    kids: kids,
  );
}
