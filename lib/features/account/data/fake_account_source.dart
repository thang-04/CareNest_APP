import 'package:carenest_app/features/account/domain/account_profile.dart';

/// Dữ liệu giả theo mockup; tên và số điện thoại là giả, không phải người thật.
class FakeAccountSource implements AccountSource {
  const FakeAccountSource();

  static const profiles = {
    AppRole.parent: AccountProfile(
      fullName: 'Nguyễn Thu Lan',
      phone: '0912 345 678',
      email: 'thulan.nguyen@example.com',
      role: AppRole.parent,
      contextLabel: 'Con của tôi',
      contextValue: 'Nguyễn Minh Anh · Mầm 3A',
    ),
    AppRole.teacher: AccountProfile(
      fullName: 'Trần Thu Hà',
      phone: '0903 222 111',
      role: AppRole.teacher,
      contextLabel: 'Lớp chủ nhiệm',
      contextValue: 'Mầm 3A · Cơ sở chính',
    ),
    AppRole.kitchen: AccountProfile(
      fullName: 'Nguyễn Thị Mai',
      phone: '0988 111 222',
      role: AppRole.kitchen,
      contextLabel: 'Bếp',
      contextValue: 'Cơ sở chính',
    ),
    AppRole.vicePrincipal: AccountProfile(
      fullName: 'Lê Văn Bình',
      phone: '0977 333 444',
      role: AppRole.vicePrincipal,
      contextLabel: 'Cơ sở phụ trách',
      contextValue: 'Cơ sở chính – Thượng Hồng',
    ),
    AppRole.principal: AccountProfile(
      fullName: 'Nguyễn Thị Hồng',
      phone: '0966 555 666',
      role: AppRole.principal,
      contextLabel: 'Phạm vi',
      contextValue: 'Toàn trường · 2 cơ sở',
    ),
  };

  @override
  Future<AccountProfile> loadProfile(AppRole role) async => profiles[role]!;
}
