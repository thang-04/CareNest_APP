import 'package:carenest_app/core/network/api_client.dart';
import 'package:carenest_app/features/auth/data/models/me_dto.dart';
import 'package:carenest_app/features/auth/domain/entities/app_user.dart';

/// Tài khoản đang đăng nhập: role, quyền, phân công, con (BE AUTH_CONTRACT).
class AccountRemoteDataSource {
  AccountRemoteDataSource(this._api);

  final ApiClient _api;

  Future<AppUser> fetchMe() => _api.get(
    '/accounts/me',
    decode: (data) =>
        MeDto.fromJson(Map<String, dynamic>.from(data! as Map)).toEntity(),
  );
}
