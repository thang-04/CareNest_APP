import 'package:carenest_app/features/auth/domain/entities/app_mode.dart';
import 'package:carenest_app/features/auth/domain/entities/app_user.dart';
import 'package:carenest_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:carenest_app/features/auth/presentation/controllers/auth_state.dart';

/// AuthController giả cho test màn hình/router: trạng thái đặt tay, ghi lại hành động.
class FakeAuthController extends AuthController {
  FakeAuthController([this._initial = const AuthSignedOut()]);

  final AuthState _initial;
  final List<String> calls = [];

  @override
  AuthState build() => _initial;

  void emit(AuthState next) => state = next;

  @override
  Future<void> start() async => calls.add('start');

  @override
  Future<void> retry() async => calls.add('retry');

  @override
  Future<void> signIn({String? loginHint}) async =>
      calls.add('signIn:${loginHint ?? ''}');

  @override
  Future<void> signOut({AuthNotice? notice}) async => calls.add('signOut');

  @override
  Future<void> switchMode(AppMode mode) async =>
      calls.add('switchMode:${mode.name}');

  @override
  Future<void> onResumed() async => calls.add('onResumed');
}

AppUser fakeUser({
  Set<String> roles = const {'TEACHER'},
  List<int> childIds = const [],
}) => AppUser(
  userId: 12,
  username: '0900000001',
  fullName: 'Người dùng thử',
  roles: roles,
  permissions: const {},
  assignments: const [],
  childIds: childIds,
);
