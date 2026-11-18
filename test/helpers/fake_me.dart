/// `data` giả của `GET /accounts/me` (dạng theo BE AUTH_CONTRACT).
Map<String, Object?> fakeMe({
  int userId = 12,
  List<String> roles = const ['TEACHER'],
  List<int> childIds = const [],
}) => {
  'userId': userId,
  'username': '0900000001',
  'fullName': 'Người dùng thử',
  'email': null,
  'roles': roles,
  'permissions': <String>[],
  'schoolWidePermissions': <String>[],
  'assignments': <Object>[],
  'childIds': childIds,
};
