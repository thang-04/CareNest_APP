import 'package:carenest_app/features/parent/evaluation/domain/evaluation.dart';
import 'package:carenest_app/features/parent/parent_home/data/fake_parent_home_source.dart';

/// Đánh giá giả (user 18/11: dựng theo canvas "Đánh giá của bé", tạm bỏ qua BE). Mốc cuối năm học
/// 2026–2027 để đủ 5 mục. Minh Anh (Mầm 3A) có ngày vắng, ngày cô chưa lưu và một chủ đề chưa đạt;
/// Bảo Ngọc (Lá 1) có nhãn hoàn thành chương trình và một chủ đề đang học.
class FakeEvaluationSource implements EvaluationSource {
  const FakeEvaluationSource({
    this.mode = FakeMode.data,
    this.delay = const Duration(milliseconds: 300),
  });

  final FakeMode mode;
  final Duration delay;

  @override
  Future<EvaluationBook> load(String childId) async {
    await Future<void>.delayed(delay);
    if (mode == FakeMode.error) throw StateError('Không tải được dữ liệu giả');
    if (mode == FakeMode.empty) return const EvaluationBook();
    return childId == 'child-2' ? _baoNgoc() : _minhAnh();
  }
}

const _teacherHa = 'Cô Trần Thu Hà';
const _teacherThu = 'Cô Vũ Minh Thư';

const _domainBody = 'Phát triển thể chất';
const _domainMind = 'Phát triển nhận thức';
const _domainLanguage = 'Phát triển ngôn ngữ';
const _domainSocial = 'Phát triển tình cảm và kỹ năng xã hội';
const _domainArt = 'Phát triển thẩm mỹ';

const _allMealsFinished = {
  MealSession.morning: EatingLevel.finished,
  MealSession.lunch: EatingLevel.finished,
  MealSession.afternoon: EatingLevel.finished,
};

GoalResult _met(String text, [String? activity]) =>
    GoalResult(text, met: true, activity: activity);

GoalResult _notMet(String text, [String? activity]) =>
    GoalResult(text, met: false, activity: activity);

/// MT của học kỳ kèm số chủ đề đạt / số chủ đề có kết quả. Giả lập đơn giản: đạt ở mọi chủ đề
/// thì Đạt; khi nối BE, kết quả lấy nguyên từ BE.
GoalResult _term(String text, int themesMet, int themesAssessed) => GoalResult(
  text,
  met: themesMet > 0 && themesMet == themesAssessed,
  themesMet: themesMet,
  themesAssessed: themesAssessed,
);

DayEvaluation _day(
  DateTime date, {
  required String teacher,
  required String comment,
  required List<GoalResult> goals,
  bool flagged = false,
  List<HealthSign> healthSigns = const [],
  Map<MealSession, EatingLevel> meals = _allMealsFinished,
  NapLevel nap = NapLevel.good,
  Emotion emotion = Emotion.happy,
  List<ObservedBehavior> behaviors = const [],
  Participation participation = Participation.active,
}) => DayEvaluation(
  date: date,
  teacherName: teacher,
  savedAt: DateTime(date.year, date.month, date.day, 16, 20),
  flagged: flagged,
  healthSigns: healthSigns,
  meals: meals,
  nap: nap,
  emotion: emotion,
  behaviors: behaviors,
  participation: participation,
  goals: goals,
  comment: comment,
);

EvaluationBook _minhAnh() {
  const activityStory = 'Hoạt động học · Kể chuyện Thỏ con không vâng lời';
  return EvaluationBook(
    weeks: [
      EvaluationWeek(
        label: 'Tuần 35',
        from: DateTime(2027, 5, 24),
        to: DateTime(2027, 5, 28),
        days: [
          _day(
            DateTime(2027, 5, 24),
            teacher: _teacherHa,
            flagged: true,
            goals: [
              _met(
                'Nhận biết hình tròn, hình vuông',
                'Hoạt động học · Làm quen hình tròn, hình vuông',
              ),
              _met(
                'Chơi đúng luật cùng các bạn',
                'Hoạt động ngoài trời · Trò chơi Bóng tròn to',
              ),
            ],
            comment:
                'Con nhận biết hình tròn, hình vuông rất nhanh và chơi vui vẻ với các bạn.',
          ),
          _day(
            DateTime(2027, 5, 25),
            teacher: _teacherHa,
            flagged: true,
            emotion: Emotion.calm,
            behaviors: const [ObservedBehavior.helpful],
            goals: [
              _met(
                'Hát thuộc bài Cả nhà thương nhau',
                'Hoạt động âm nhạc · Hát Cả nhà thương nhau',
              ),
            ],
            comment: 'Con hát to, rõ lời và giúp bạn cất ghế sau giờ học.',
          ),
          _day(
            DateTime(2027, 5, 26),
            teacher: _teacherHa,
            nap: NapLevel.little,
            goals: [
              _met(
                'Đi theo đường hẹp không chạm vạch',
                'Hoạt động thể chất · Đi trong đường hẹp',
              ),
            ],
            comment:
                'Trưa nay con ngủ ít, cô cho con nằm nghỉ thêm. Con vẫn vui vẻ tham gia các hoạt động.',
          ),
          DayEvaluation(date: DateTime(2027, 5, 27), status: DayStatus.absent),
          _day(
            DateTime(2027, 5, 28),
            teacher: _teacherHa,
            flagged: true,
            meals: const {
              MealSession.morning: EatingLevel.finished,
              MealSession.lunch: EatingLevel.finished,
              MealSession.afternoon: EatingLevel.little,
            },
            behaviors: const [
              ObservedBehavior.cooperative,
              ObservedBehavior.helpful,
            ],
            goals: [
              _met('Nghe và trả lời được câu hỏi của cô', activityStory),
              _notMet('Kể lại được 1–2 câu trong chuyện', activityStory),
              _met(
                'Xếp được hàng rào bằng khối',
                'Hoạt động góc · Góc xây dựng',
              ),
              _met(
                'Chạy theo hiệu lệnh của cô',
                'Hoạt động ngoài trời · Trò chơi Mèo đuổi chuột',
              ),
            ],
            comment:
                'Hôm nay con nghe cô kể chuyện rất chăm chú và trả lời đúng câu hỏi. '
                'Bữa chiều con ăn ít vì còn no, mẹ cho con ăn nhẹ khi về nhé.',
          ),
        ],
      ),
      EvaluationWeek(
        label: 'Tuần 34',
        from: DateTime(2027, 5, 17),
        to: DateTime(2027, 5, 21),
        days: [
          _day(
            DateTime(2027, 5, 17),
            teacher: _teacherHa,
            flagged: true,
            goals: [
              _met('Đếm đồ vật trong phạm vi 4', 'Hoạt động học · Đếm đến 4'),
            ],
            comment: 'Con đếm đúng đến 4 và rất thích chơi với khối gỗ.',
          ),
          _day(
            DateTime(2027, 5, 18),
            teacher: _teacherHa,
            healthSigns: const [HealthSign.runnyNose],
            emotion: Emotion.calm,
            goals: [
              _notMet(
                'Tô màu không chờm ra ngoài hình',
                'Hoạt động tạo hình · Tô màu quả cam',
              ),
            ],
            comment:
                'Con hơi sổ mũi từ sáng, cô đã cho con uống nước ấm. Gia đình theo dõi thêm cho con nhé.',
          ),
          _day(
            DateTime(2027, 5, 19),
            teacher: _teacherHa,
            flagged: true,
            goals: [
              _met(
                'Nói được tên một số loại quả mùa hè',
                'Hoạt động khám phá · Quả mùa hè',
              ),
            ],
            comment:
                'Con kể được tên quả dưa hấu, quả xoài và chia quả cho bạn cùng ăn.',
          ),
          _day(
            DateTime(2027, 5, 20),
            teacher: _teacherHa,
            goals: [
              _met(
                'Vận động theo nhạc',
                'Hoạt động âm nhạc · Vận động bài Quả',
              ),
            ],
            comment: 'Con vận động theo nhạc rất nhịp nhàng.',
          ),
          DayEvaluation(
            date: DateTime(2027, 5, 21),
            status: DayStatus.notRecorded,
          ),
        ],
      ),
    ],
    weeklyComments: [
      WeeklyComment(
        weekLabel: 'Tuần 35',
        from: DateTime(2027, 5, 24),
        to: DateTime(2027, 5, 28),
        paragraphs: const [
          'Tuần này con đi học 4 ngày, nghỉ thứ Năm. Con nhận biết hình tròn, hình vuông rất nhanh, '
              'hát thuộc bài Cả nhà thương nhau và hay giúp bạn cất ghế, cất đồ chơi.',
          'Trưa thứ Tư con ngủ ít và bữa chiều thứ Sáu con ăn ít vì còn no. Gia đình cho con ngủ sớm '
              'và đọc truyện cùng con mỗi tối nhé.',
        ],
        teacherName: _teacherHa,
        sentAt: DateTime(2027, 5, 28, 16, 40),
      ),
      WeeklyComment(
        weekLabel: 'Tuần 34',
        from: DateTime(2027, 5, 17),
        to: DateTime(2027, 5, 21),
        paragraphs: const [
          'Con tích cực tham gia hoạt động khám phá quả mùa hè và đếm đúng đến 4. Thứ Ba con hơi sổ '
              'mũi nhưng vẫn vui vẻ đến lớp. Con cần tập tô màu gọn trong hình.',
        ],
        teacherName: _teacherHa,
        sentAt: DateTime(2027, 5, 21, 16, 35),
      ),
      WeeklyComment(
        weekLabel: 'Tuần 33',
        from: DateTime(2027, 5, 10),
        to: DateTime(2027, 5, 14),
        paragraphs: const [
          'Tuần đầu của chủ đề Bé vui hè, con thích nhất giờ chơi với nước và cát. Con biết rửa tay '
              'sạch sẽ trước khi ăn và tự cất dép đúng chỗ.',
        ],
        teacherName: _teacherHa,
        sentAt: DateTime(2027, 5, 14, 16, 30),
      ),
      WeeklyComment(
        weekLabel: 'Tuần 32',
        from: DateTime(2027, 5, 3),
        to: DateTime(2027, 5, 7),
        paragraphs: const [
          'Con đã quen nề nếp sau kỳ nghỉ lễ. Con mạnh dạn chào cô, chào bạn khi đến lớp và ăn hết '
              'suất trưa cả tuần.',
        ],
        teacherName: _teacherHa,
        sentAt: DateTime(2027, 5, 7, 16, 45),
      ),
    ],
    themes: [
      ThemeResult(
        id: 'theme-mam-7',
        name: 'Bé vui hè',
        semester: 2,
        from: DateTime(2027, 5, 3),
        to: DateTime(2027, 5, 21),
        metGoals: 4,
        totalGoals: 5,
        passed: true,
        goals: [
          _met('Nói được tên một số loại quả mùa hè'),
          _met('Biết uống đủ nước khi trời nóng'),
          _met('Đi theo đường hẹp không chạm vạch'),
          _met('Đếm đồ vật trong phạm vi 4'),
          _notMet('Kể lại chuyện ngắn có sự giúp đỡ của cô'),
        ],
        confirmedBy: _teacherHa,
        confirmedAt: DateTime(2027, 5, 24),
      ),
      ThemeResult(
        id: 'theme-mam-6',
        name: 'Phương tiện giao thông',
        semester: 2,
        from: DateTime(2027, 4, 5),
        to: DateTime(2027, 4, 30),
        metGoals: 4,
        totalGoals: 5,
        passed: true,
        goals: [
          _met('Gọi tên xe đạp, xe máy, ô tô'),
          _met('Đi đúng phía bên phải khi đi bộ cùng người lớn'),
          _met('Vẽ các nét thẳng, nét ngang'),
          _met('Nhận biết hình tròn, hình vuông'),
          _notMet('Kể lại chuyện ngắn có sự giúp đỡ của cô'),
        ],
        confirmedBy: _teacherHa,
        confirmedAt: DateTime(2027, 5, 5),
      ),
      ThemeResult(
        id: 'theme-mam-5',
        name: 'Thế giới động vật',
        semester: 2,
        from: DateTime(2027, 3, 1),
        to: DateTime(2027, 4, 2),
        metGoals: 3,
        totalGoals: 5,
        passed: false,
        goals: [
          _met('Gọi tên một số con vật nuôi trong gia đình'),
          _met('Bắt chước tiếng kêu của con vật'),
          _notMet('Phân biệt to – nhỏ'),
          _notMet('Kể chuyện theo tranh Đôi bạn tốt'),
          _met('Đếm đồ vật trong phạm vi 3'),
        ],
        confirmedBy: _teacherHa,
        confirmedAt: DateTime(2027, 4, 7),
      ),
      ThemeResult(
        id: 'theme-mam-4',
        name: 'Tết và mùa xuân',
        semester: 2,
        from: DateTime(2027, 1, 25),
        to: DateTime(2027, 2, 26),
        metGoals: 4,
        totalGoals: 5,
        passed: true,
        goals: [
          _met('Kể được một vài món ăn ngày Tết'),
          _met('Nhận biết một số loại hoa mùa xuân'),
          _met('Tô màu bức tranh hoa đào, hoa mai'),
          _met('Hát và vận động theo bài Sắp đến Tết rồi'),
          _notMet('Đếm đồ vật trong phạm vi 3'),
        ],
        confirmedBy: _teacherHa,
        confirmedAt: DateTime(2027, 3, 3),
      ),
      ThemeResult(
        id: 'theme-mam-3',
        name: 'Gia đình',
        semester: 1,
        from: DateTime(2026, 11, 2),
        to: DateTime(2026, 12, 11),
        metGoals: 5,
        totalGoals: 5,
        passed: true,
        goals: [
          _met('Kể tên các thành viên trong gia đình'),
          _met('Nhận biết một số đồ dùng trong gia đình'),
          _met('Xếp chồng được 3–4 khối'),
          _met('Đọc thuộc bài thơ ngắn về gia đình'),
          _met('Biết lễ phép, vâng lời người lớn'),
        ],
        confirmedBy: _teacherHa,
        confirmedAt: DateTime(2026, 12, 16),
      ),
      ThemeResult(
        id: 'theme-mam-2',
        name: 'Bản thân',
        semester: 1,
        from: DateTime(2026, 9, 28),
        to: DateTime(2026, 10, 30),
        metGoals: 4,
        totalGoals: 5,
        passed: true,
        goals: [
          _met('Nói được tên, tuổi, giới tính của bản thân'),
          _met('Nhận biết các bộ phận trên cơ thể'),
          _met('Tự rửa tay bằng xà phòng'),
          _notMet('Xúc cơm ăn gọn gàng'),
          _met('Nhận biết màu đỏ, vàng, xanh'),
        ],
        confirmedBy: _teacherHa,
        confirmedAt: DateTime(2026, 11, 4),
      ),
      ThemeResult(
        id: 'theme-mam-1',
        name: 'Trường mầm non',
        semester: 1,
        from: DateTime(2026, 9, 7),
        to: DateTime(2026, 9, 25),
        metGoals: 4,
        totalGoals: 5,
        passed: true,
        goals: [
          _met('Nói được tên trường, tên lớp, tên cô'),
          _met('Chào cô, chào bạn khi đến lớp'),
          _met('Cất đồ dùng đúng nơi quy định'),
          _met('Chơi cùng bạn ở các góc chơi'),
          _notMet('Hát đúng giai điệu bài Vui đến trường'),
        ],
        confirmedBy: _teacherHa,
        confirmedAt: DateTime(2026, 9, 30),
      ),
    ],
    semesters: [
      SemesterResult(
        semester: 2,
        schoolYear: '2026–2027',
        from: DateTime(2027, 1, 18),
        to: DateTime(2027, 5, 21),
        domainsMet: 4,
        domainsTotal: 5,
        domains: [
          DomainResult(
            name: _domainBody,
            met: true,
            metGoals: 2,
            totalGoals: 2,
            goals: [
              _term('Đi theo đường hẹp không chạm vạch', 1, 1),
              _term('Biết uống đủ nước khi trời nóng', 1, 1),
            ],
          ),
          DomainResult(
            name: _domainMind,
            met: true,
            metGoals: 4,
            totalGoals: 5,
            goals: [
              _term('Nhận biết một số loại hoa mùa xuân', 1, 1),
              _term('Gọi tên một số con vật nuôi trong gia đình', 1, 1),
              _term('Nhận biết hình tròn, hình vuông', 1, 1),
              _term('Đếm đồ vật trong phạm vi 4', 1, 1),
              _term('Phân biệt to – nhỏ', 0, 1),
            ],
          ),
          DomainResult(
            name: _domainLanguage,
            met: false,
            metGoals: 1,
            totalGoals: 3,
            goals: [
              _term('Bắt chước tiếng kêu của con vật', 1, 1),
              _term('Kể lại chuyện ngắn có sự giúp đỡ của cô', 0, 2),
              _term('Kể chuyện theo tranh Đôi bạn tốt', 0, 1),
            ],
          ),
          DomainResult(
            name: _domainSocial,
            met: true,
            metGoals: 2,
            totalGoals: 2,
            goals: [
              _term('Đi đúng phía bên phải khi đi bộ cùng người lớn', 1, 1),
              _term('Chơi cùng bạn ở các góc chơi', 2, 2),
            ],
          ),
          DomainResult(
            name: _domainArt,
            met: true,
            metGoals: 3,
            totalGoals: 3,
            goals: [
              _term('Tô màu bức tranh hoa đào, hoa mai', 1, 1),
              _term('Hát và vận động theo bài Sắp đến Tết rồi', 1, 1),
              _term('Vẽ các nét thẳng, nét ngang', 1, 1),
            ],
          ),
        ],
        confirmedBy: _teacherHa,
        confirmedAt: DateTime(2027, 5, 26),
      ),
      SemesterResult(
        semester: 1,
        schoolYear: '2026–2027',
        from: DateTime(2026, 9, 7),
        to: DateTime(2027, 1, 15),
        domainsMet: 4,
        domainsTotal: 5,
        domains: [
          DomainResult(
            name: _domainBody,
            met: true,
            metGoals: 2,
            totalGoals: 3,
            goals: [
              _term('Tự rửa tay bằng xà phòng', 1, 1),
              _term('Xếp chồng được 3–4 khối', 1, 1),
              _term('Xúc cơm ăn gọn gàng', 0, 1),
            ],
          ),
          DomainResult(
            name: _domainMind,
            met: true,
            metGoals: 3,
            totalGoals: 3,
            goals: [
              _term('Nhận biết màu đỏ, vàng, xanh', 1, 1),
              _term('Nhận biết các bộ phận trên cơ thể', 1, 1),
              _term('Nhận biết một số đồ dùng trong gia đình', 1, 1),
            ],
          ),
          DomainResult(
            name: _domainLanguage,
            met: true,
            metGoals: 3,
            totalGoals: 3,
            goals: [
              _term('Nói được tên trường, tên lớp, tên cô', 1, 1),
              _term('Nói được tên, tuổi, giới tính của bản thân', 1, 1),
              _term('Đọc thuộc bài thơ ngắn về gia đình', 1, 1),
            ],
          ),
          DomainResult(
            name: _domainSocial,
            met: true,
            metGoals: 3,
            totalGoals: 3,
            goals: [
              _term('Chào cô, chào bạn khi đến lớp', 1, 1),
              _term('Cất đồ dùng đúng nơi quy định', 1, 1),
              _term('Biết lễ phép, vâng lời người lớn', 1, 1),
            ],
          ),
          DomainResult(
            name: _domainArt,
            met: false,
            metGoals: 0,
            totalGoals: 1,
            goals: [_term('Hát đúng giai điệu bài Vui đến trường', 0, 1)],
          ),
        ],
        confirmedBy: _teacherHa,
        confirmedAt: DateTime(2027, 1, 20),
      ),
    ],
    yearEnd: YearEndResult(
      schoolYear: '2026–2027',
      ageGroup: 'Nhóm 3–4 tuổi',
      metGoals: 21,
      totalGoals: 25,
      teacherComment:
          'Qua một năm học, con mạnh dạn, lễ phép và hòa đồng với các bạn. Con nhận biết màu sắc, '
          'hình dạng nhanh, thuộc nhiều bài thơ, bài hát và tự phục vụ tốt. Cô mong con tập kể lại '
          'chuyện và xúc cơm gọn gàng hơn khi lên lớp Chồi.',
      teacherName: _teacherHa,
      commentedAt: DateTime(2027, 5, 27),
      noteForParent:
          'Hè này gia đình cùng con đọc truyện tranh và hỏi con kể lại, cho con tự xúc cơm trong '
          'bữa ăn ở nhà.',
      domains: [
        DomainResult(
          name: _domainBody,
          metGoals: 4,
          totalGoals: 5,
          comment:
              'Con khỏe mạnh, vận động nhanh nhẹn. Con cần tập xúc cơm gọn gàng hơn.',
          goals: [
            _met('Tự rửa tay bằng xà phòng'),
            _met('Đi theo đường hẹp không chạm vạch'),
            _met('Xếp chồng được 3–4 khối'),
            _met('Biết uống đủ nước khi trời nóng'),
            _notMet('Xúc cơm ăn gọn gàng'),
          ],
        ),
        DomainResult(
          name: _domainMind,
          metGoals: 5,
          totalGoals: 6,
          comment: 'Con ham tìm hiểu, nhận biết màu sắc và hình dạng nhanh.',
          goals: [
            _met('Nhận biết màu đỏ, vàng, xanh'),
            _met('Nhận biết hình tròn, hình vuông'),
            _met('Đếm đồ vật trong phạm vi 4'),
            _met('Gọi tên một số con vật nuôi trong gia đình'),
            _met('Gọi tên xe đạp, xe máy, ô tô'),
            _notMet('Phân biệt to – nhỏ'),
          ],
        ),
        DomainResult(
          name: _domainLanguage,
          metGoals: 3,
          totalGoals: 5,
          comment:
              'Con nói rõ ràng, thuộc nhiều bài thơ. Con cần tập kể lại chuyện theo tranh.',
          goals: [
            _met('Nói được tên, tuổi, giới tính của bản thân'),
            _met('Đọc thuộc bài thơ ngắn về gia đình'),
            _met('Bắt chước tiếng kêu của con vật'),
            _notMet('Kể lại chuyện ngắn có sự giúp đỡ của cô'),
            _notMet('Kể chuyện theo tranh Đôi bạn tốt'),
          ],
        ),
        DomainResult(
          name: _domainSocial,
          metGoals: 5,
          totalGoals: 5,
          comment: 'Con lễ phép, hòa đồng và hay giúp đỡ bạn.',
          goals: [
            _met('Chào cô, chào bạn khi đến lớp'),
            _met('Chơi cùng bạn ở các góc chơi'),
            _met('Cất đồ dùng đúng nơi quy định'),
            _met('Biết lễ phép, vâng lời người lớn'),
            _met('Đi đúng phía bên phải khi đi bộ cùng người lớn'),
          ],
        ),
        DomainResult(
          name: _domainArt,
          metGoals: 4,
          totalGoals: 4,
          goals: [
            _met('Hát và vận động theo bài Sắp đến Tết rồi'),
            _met('Tô màu bức tranh hoa đào, hoa mai'),
            _met('Vẽ các nét thẳng, nét ngang'),
            _met('Vận động theo nhạc'),
          ],
        ),
      ],
      confirmedBy: _teacherHa,
      confirmedAt: DateTime(2027, 5, 27),
    ),
  );
}

EvaluationBook _baoNgoc() {
  const activityLetters = 'Hoạt động học · Làm quen chữ p, q';
  return EvaluationBook(
    weeks: [
      EvaluationWeek(
        label: 'Tuần 35',
        from: DateTime(2027, 5, 24),
        to: DateTime(2027, 5, 28),
        days: [
          _day(
            DateTime(2027, 5, 24),
            teacher: _teacherThu,
            flagged: true,
            goals: [
              _met('Nhận biết, phát âm đúng chữ p, q', activityLetters),
              _met('Tô đúng chiều chữ p, q', activityLetters),
            ],
            comment: 'Con phát âm chữ p, q rõ ràng và tô chữ rất cẩn thận.',
          ),
          _day(
            DateTime(2027, 5, 25),
            teacher: _teacherThu,
            flagged: true,
            behaviors: const [ObservedBehavior.helpful],
            goals: [
              _met(
                'Đếm, so sánh số lượng trong phạm vi 10',
                'Hoạt động học · Số 10',
              ),
            ],
            comment: 'Con đếm và so sánh nhanh, còn hướng dẫn bạn cùng làm.',
          ),
          _day(
            DateTime(2027, 5, 26),
            teacher: _teacherThu,
            behaviors: const [ObservedBehavior.grabbing],
            goals: [
              _notMet(
                'Phối hợp nhịp nhàng cùng bạn',
                'Trò chơi ngoài trời · Kéo co',
              ),
            ],
            comment:
                'Trong giờ chơi kéo co con tranh dây với bạn, cô đã nhắc con chờ đến lượt.',
          ),
          _day(
            DateTime(2027, 5, 27),
            teacher: _teacherThu,
            flagged: true,
            goals: [
              _met(
                'Xây được mô hình trường tiểu học',
                'Hoạt động góc · Góc xây dựng',
              ),
            ],
            comment:
                'Con cùng các bạn xây mô hình trường tiểu học và giới thiệu rất tự tin.',
          ),
          _day(
            DateTime(2027, 5, 28),
            teacher: _teacherThu,
            healthSigns: const [HealthSign.runnyNose],
            nap: NapLevel.little,
            emotion: Emotion.calm,
            goals: [
              _met(
                'Kể về ngôi trường tiểu học con sẽ học',
                'Hoạt động trò chuyện · Trường tiểu học của bé',
              ),
            ],
            comment:
                'Con hơi sổ mũi từ trưa, cô đã cho con uống nước ấm và nghỉ ngơi. '
                'Gia đình theo dõi thêm cho con nhé.',
          ),
        ],
      ),
    ],
    weeklyComments: [
      WeeklyComment(
        weekLabel: 'Tuần 35',
        from: DateTime(2027, 5, 24),
        to: DateTime(2027, 5, 28),
        paragraphs: const [
          'Tuần này con đi học đủ 5 ngày và rất hào hứng với chủ đề Bé chuẩn bị vào lớp 1. Con phát âm '
              'đúng chữ p, q, đếm nhanh trong phạm vi 10 và cùng các bạn xây mô hình trường tiểu học.',
          'Thứ Sáu con hơi sổ mũi. Gia đình cho con mặc ấm, uống nhiều nước và tiếp tục tập cho con '
              'ngồi viết đúng tư thế nhé.',
        ],
        teacherName: _teacherThu,
        sentAt: DateTime(2027, 5, 28, 16, 30),
      ),
      WeeklyComment(
        weekLabel: 'Tuần 34',
        from: DateTime(2027, 5, 17),
        to: DateTime(2027, 5, 21),
        paragraphs: const [
          'Con tham gia tích cực buổi tham quan trường tiểu học, biết xếp hàng và chào hỏi các anh chị '
              'lớp 1 lễ phép. Con cần tập viết tên của mình theo mẫu.',
        ],
        teacherName: _teacherThu,
        sentAt: DateTime(2027, 5, 21, 16, 30),
      ),
    ],
    themes: [
      ThemeResult(
        id: 'theme-la-6',
        name: 'Bé chuẩn bị vào lớp 1',
        semester: 2,
        from: DateTime(2027, 5, 24),
        to: DateTime(2027, 5, 31),
        status: PeriodStatus.pending,
      ),
      ThemeResult(
        id: 'theme-la-5',
        name: 'Trường tiểu học',
        semester: 2,
        from: DateTime(2027, 5, 10),
        to: DateTime(2027, 5, 21),
        metGoals: 4,
        totalGoals: 5,
        passed: true,
        goals: [
          _met(
            'Biết tên trường tiểu học gần nhà và hoạt động của học sinh lớp 1',
          ),
          _met('Nhận biết, phát âm đúng chữ cái p, q, g, y'),
          _met('Đếm, so sánh số lượng trong phạm vi 10'),
          _met('Chào hỏi lễ phép, biết xếp hàng chờ đến lượt'),
          _notMet('Viết được tên của mình theo mẫu'),
        ],
        confirmedBy: _teacherThu,
        confirmedAt: DateTime(2027, 5, 24),
      ),
      ThemeResult(
        id: 'theme-la-4',
        name: 'Quê hương, đất nước',
        semester: 2,
        from: DateTime(2027, 4, 26),
        to: DateTime(2027, 5, 7),
        metGoals: 5,
        totalGoals: 5,
        passed: true,
        goals: [
          _met('Kể tên một vài danh lam thắng cảnh của quê hương'),
          _met('Đọc thuộc bài thơ Ảnh Bác'),
          _met('Hát đúng giai điệu bài hát về quê hương'),
          _met('Xếp hàng chào cờ nghiêm túc'),
          _met('Vẽ lá cờ Tổ quốc'),
        ],
        confirmedBy: _teacherThu,
        confirmedAt: DateTime(2027, 5, 11),
      ),
      ThemeResult(
        id: 'theme-la-3',
        name: 'Hiện tượng tự nhiên',
        semester: 2,
        from: DateTime(2027, 4, 5),
        to: DateTime(2027, 4, 23),
        metGoals: 2,
        totalGoals: 5,
        passed: false,
        goals: [
          _met('Nhận biết một số hiện tượng thời tiết'),
          _notMet('Kể lại chuyện theo trình tự có mở đầu, kết thúc'),
          _notMet('Dùng câu đơn, câu ghép khi trò chuyện'),
          _met('Làm thí nghiệm vật chìm, vật nổi cùng cô'),
          _notMet('Viết được tên của mình theo mẫu'),
        ],
        confirmedBy: _teacherThu,
        confirmedAt: DateTime(2027, 4, 28),
      ),
      ThemeResult(
        id: 'theme-la-2',
        name: 'Gia đình',
        semester: 1,
        from: DateTime(2026, 10, 19),
        to: DateTime(2026, 11, 13),
        metGoals: 4,
        totalGoals: 5,
        passed: true,
        goals: [
          _met('Kể về các thành viên trong gia đình'),
          _met('Đếm đến 6, nhận biết số 6'),
          _notMet('Kể lại chuyện theo trình tự có mở đầu, kết thúc'),
          _met('Giúp bố mẹ những việc vừa sức'),
          _met('Làm thiệp tặng người thân'),
        ],
        confirmedBy: _teacherThu,
        confirmedAt: DateTime(2026, 11, 18),
      ),
      ThemeResult(
        id: 'theme-la-1',
        name: 'Bản thân',
        semester: 1,
        from: DateTime(2026, 9, 28),
        to: DateTime(2026, 10, 16),
        metGoals: 5,
        totalGoals: 5,
        passed: true,
        goals: [
          _met('Nói được ngày sinh nhật của mình'),
          _met('Tự mặc, cởi quần áo'),
          _met('Nhận biết chữ cái o, ô, ơ'),
          _met('Biết chia sẻ đồ chơi với bạn'),
          _met('Vận động nhịp nhàng theo bài hát'),
        ],
        confirmedBy: _teacherThu,
        confirmedAt: DateTime(2026, 10, 21),
      ),
    ],
    semesters: [
      SemesterResult(
        semester: 2,
        schoolYear: '2026–2027',
        from: DateTime(2027, 1, 18),
        to: DateTime(2027, 5, 21),
        domainsMet: 4,
        domainsTotal: 5,
        domains: [
          DomainResult(
            name: _domainBody,
            met: true,
            metGoals: 2,
            totalGoals: 2,
            goals: [
              _term('Tô, đồ đúng nét các chữ cái đã học', 2, 2),
              _term('Bật xa tối thiểu 50 cm', 1, 1),
            ],
          ),
          DomainResult(
            name: _domainMind,
            met: true,
            metGoals: 3,
            totalGoals: 3,
            goals: [
              _term('Đếm, so sánh số lượng trong phạm vi 10', 1, 1),
              _term('Nhận biết một số hiện tượng thời tiết', 1, 1),
              _term('Làm thí nghiệm vật chìm, vật nổi cùng cô', 1, 1),
            ],
          ),
          DomainResult(
            name: _domainLanguage,
            met: false,
            metGoals: 2,
            totalGoals: 5,
            goals: [
              _term('Nhận biết, phát âm đúng chữ cái p, q, g, y', 1, 1),
              _term('Đọc thuộc bài thơ Ảnh Bác', 1, 1),
              _term('Viết được tên của mình theo mẫu', 0, 2),
              _term('Kể lại chuyện theo trình tự có mở đầu, kết thúc', 0, 1),
              _term('Dùng câu đơn, câu ghép khi trò chuyện', 0, 1),
            ],
          ),
          DomainResult(
            name: _domainSocial,
            met: true,
            metGoals: 2,
            totalGoals: 2,
            goals: [
              _term('Chào hỏi lễ phép, biết xếp hàng chờ đến lượt', 1, 1),
              _term('Xếp hàng chào cờ nghiêm túc', 1, 1),
            ],
          ),
          DomainResult(
            name: _domainArt,
            met: true,
            metGoals: 2,
            totalGoals: 2,
            goals: [
              _term('Hát đúng giai điệu bài hát về quê hương', 1, 1),
              _term('Vẽ lá cờ Tổ quốc', 1, 1),
            ],
          ),
        ],
        confirmedBy: _teacherThu,
        confirmedAt: DateTime(2027, 5, 26),
      ),
      SemesterResult(
        semester: 1,
        schoolYear: '2026–2027',
        from: DateTime(2026, 9, 7),
        to: DateTime(2027, 1, 15),
        domainsMet: 5,
        domainsTotal: 5,
        domains: [
          DomainResult(
            name: _domainBody,
            met: true,
            metGoals: 2,
            totalGoals: 2,
            goals: [
              _term('Tự mặc, cởi quần áo', 1, 1),
              _term('Vận động nhịp nhàng theo bài hát', 1, 1),
            ],
          ),
          DomainResult(
            name: _domainMind,
            met: true,
            metGoals: 2,
            totalGoals: 2,
            goals: [
              _term('Đếm đến 6, nhận biết số 6', 1, 1),
              _term('Nói được ngày sinh nhật của mình', 1, 1),
            ],
          ),
          DomainResult(
            name: _domainLanguage,
            met: true,
            metGoals: 2,
            totalGoals: 2,
            goals: [
              _term('Nhận biết chữ cái o, ô, ơ', 1, 1),
              _term('Kể về các thành viên trong gia đình', 1, 1),
            ],
          ),
          DomainResult(
            name: _domainSocial,
            met: true,
            metGoals: 2,
            totalGoals: 2,
            goals: [
              _term('Biết chia sẻ đồ chơi với bạn', 1, 1),
              _term('Giúp bố mẹ những việc vừa sức', 1, 1),
            ],
          ),
          DomainResult(
            name: _domainArt,
            met: true,
            metGoals: 2,
            totalGoals: 2,
            goals: [
              _term('Làm thiệp tặng người thân', 1, 1),
              _term('Vẽ chân dung người thân', 1, 1),
            ],
          ),
        ],
        confirmedBy: _teacherThu,
        confirmedAt: DateTime(2027, 1, 20),
      ),
    ],
    yearEnd: YearEndResult(
      schoolYear: '2026–2027',
      ageGroup: 'Nhóm 5–6 tuổi',
      metGoals: 22,
      totalGoals: 25,
      programCompleted: true,
      teacherComment:
          'Qua một năm học, con lớn lên rất nhiều: tự tin, lễ phép và biết giúp đỡ bạn. Con khéo tay '
          'ở các hoạt động tạo hình, thuộc nhiều bài thơ, bài hát và mạnh dạn trình bày ý kiến trước '
          'lớp. Con đã sẵn sàng vào lớp 1; cô mong con giữ thói quen tự xếp đồ dùng và tập viết đúng '
          'tư thế.',
      teacherName: _teacherThu,
      commentedAt: DateTime(2027, 5, 27),
      noteForParent:
          'Hè này gia đình cho con tập viết tên và đọc truyện tranh cùng con mỗi ngày, giúp con làm '
          'quen giờ giấc của lớp 1.',
      domains: [
        DomainResult(
          name: _domainBody,
          metGoals: 5,
          totalGoals: 5,
          goals: [
            _met('Bật xa tối thiểu 50 cm'),
            _met('Tự mặc, cởi quần áo'),
            _met('Tô, đồ đúng nét các chữ cái đã học'),
            _met('Vận động nhịp nhàng theo bài hát'),
            _met('Ném trúng đích bằng một tay'),
          ],
        ),
        DomainResult(
          name: _domainMind,
          metGoals: 5,
          totalGoals: 5,
          comment: 'Con ham học hỏi, đếm và so sánh nhanh.',
          goals: [
            _met('Đếm, so sánh số lượng trong phạm vi 10'),
            _met('Nhận biết một số hiện tượng thời tiết'),
            _met('Làm thí nghiệm vật chìm, vật nổi cùng cô'),
            _met('Nói được ngày sinh nhật của mình'),
            _met(
              'Biết tên trường tiểu học gần nhà và hoạt động của học sinh lớp 1',
            ),
          ],
        ),
        DomainResult(
          name: _domainLanguage,
          metGoals: 3,
          totalGoals: 5,
          comment:
              'Con nói rõ ràng, kể chuyện có đầu có cuối. Cần tập thêm viết tên và dùng câu dài khi '
              'kể chuyện.',
          goals: [
            _met('Nhận biết, phát âm đúng chữ cái p, q, g, y'),
            _met('Đọc thuộc bài thơ Ảnh Bác'),
            _met('Kể lại chuyện theo trình tự có mở đầu, kết thúc'),
            _notMet('Viết được tên của mình theo mẫu'),
            _notMet('Dùng câu đơn, câu ghép khi trò chuyện'),
          ],
        ),
        DomainResult(
          name: _domainSocial,
          metGoals: 5,
          totalGoals: 5,
          goals: [
            _met('Chào hỏi lễ phép, biết xếp hàng chờ đến lượt'),
            _met('Biết chia sẻ đồ chơi với bạn'),
            _met('Giúp bố mẹ những việc vừa sức'),
            _met('Xếp hàng chào cờ nghiêm túc'),
            _met('Kể về các thành viên trong gia đình'),
          ],
        ),
        DomainResult(
          name: _domainArt,
          metGoals: 4,
          totalGoals: 5,
          comment: 'Con khéo tay, vẽ đẹp. Con cần tập cắt dán cẩn thận hơn.',
          goals: [
            _met('Hát đúng giai điệu bài hát về quê hương'),
            _met('Vẽ lá cờ Tổ quốc'),
            _met('Làm thiệp tặng người thân'),
            _met('Vẽ chân dung người thân'),
            _notMet('Cắt dán được bức tranh đơn giản'),
          ],
        ),
      ],
      confirmedBy: _teacherThu,
      confirmedAt: DateTime(2027, 5, 27),
    ),
  );
}
