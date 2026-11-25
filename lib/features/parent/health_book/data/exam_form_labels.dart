/// Nhãn phiếu khám Phụ lục II, chép từ Web (CareNest_FE `src/models/children/healthExamForm.js`):
/// cùng mã BE ⇒ cùng chữ, cùng mục tô bất thường. Web đổi bảng này thì sửa theo.
class ExamOption {
  const ExamOption(this.value, this.label, {this.abnormal = false});

  final String value;
  final String label;
  final bool abnormal;
}

class ExamField {
  const ExamField(this.key, this.label, this.options);

  final String key;
  final String label;
  final List<ExamOption> options;

  ExamOption? option(Object? code) =>
      options.where((option) => option.value == code).firstOrNull;
}

class ExamVitalField {
  const ExamVitalField(
    this.key,
    this.statusKey,
    this.label,
    this.unit,
    this.options,
  );

  final String key;
  final String statusKey;
  final String label;
  final String unit;
  final List<ExamOption> options;
}

class ExamClinicalGroup {
  const ExamClinicalGroup(this.title, this.items);

  final String title;
  final List<ExamField> items;
}

const _noYes = [
  ExamOption('NO', 'Không'),
  ExamOption('YES', 'Có', abnormal: true),
];
const _yesFirst = [
  ExamOption('YES', 'Có', abnormal: true),
  ExamOption('NO', 'Không'),
];
const _hasNo = [
  ExamOption('YES', 'Có'),
  ExamOption('NO', 'Không', abnormal: true),
];
const _normalOr = [
  ExamOption('NORMAL', 'Bình thường'),
  ExamOption('ABNORMAL', 'Không bình thường', abnormal: true),
];

/// Tiền sử: "Có" kèm tên bệnh (`selfText`, `familyText`) hoặc ngày tiếp xúc (`tbContactDate`).
const examHistory = [
  ExamField('self', 'Tiền sử bản thân', _noYes),
  ExamField('family', 'Tiền sử gia đình', _noYes),
  ExamField('tbContact', 'Tiền sử tiếp xúc với người bệnh lao', _noYes),
];

const examVitals = [
  ExamVitalField('temperatureC', 'temperatureStatus', 'Nhiệt độ', '°C', [
    ExamOption('NORMAL', 'Bình thường'),
    ExamOption('FEVER', 'Sốt', abnormal: true),
    ExamOption('HYPOTHERMIA', 'Hạ thân nhiệt', abnormal: true),
  ]),
  ExamVitalField('pulse', 'pulseStatus', 'Mạch', 'lần/phút', [
    ExamOption('NORMAL', 'Bình thường'),
    ExamOption('FAST', 'Nhanh', abnormal: true),
  ]),
  ExamVitalField(
    'respiratoryRate',
    'respiratoryStatus',
    'Nhịp thở',
    'lần/phút',
    [
      ExamOption('NORMAL', 'Bình thường'),
      ExamOption('FAST', 'Thở nhanh', abnormal: true),
      ExamOption('SLOW', 'Thở chậm', abnormal: true),
    ],
  ),
];

const examHeadStatus = ExamField('headStatus', 'Vòng đầu', [
  ExamOption('NORMAL', 'Bình thường'),
  ExamOption('LARGE', 'Đầu to', abnormal: true),
  ExamOption('SMALL', 'Đầu nhỏ', abnormal: true),
]);

/// Tình trạng dinh dưỡng bác sĩ chọn (chọn nhiều).
const examNutritionStatus = ExamField('statuses', 'Tình trạng dinh dưỡng', [
  ExamOption('NORMAL', 'Bình thường'),
  ExamOption('NUTRITIONAL_EDEMA', 'Phù dinh dưỡng', abnormal: true),
  ExamOption('ANEMIA_SIGNS', 'Dấu hiệu thiếu máu', abnormal: true),
  ExamOption('RICKETS_SIGNS', 'Dấu hiệu còi xương', abnormal: true),
  ExamOption('MALNUTRITION', 'Suy dinh dưỡng', abnormal: true),
  ExamOption('OVERWEIGHT', 'Thừa cân/béo phì', abnormal: true),
]);

const examDevelopment = [
  ExamField(
    'mental',
    'Phát triển tinh thần bình thường của trẻ theo độ tuổi',
    _hasNo,
  ),
  ExamField(
    'motor',
    'Phát triển vận động bình thường của trẻ theo độ tuổi',
    _hasNo,
  ),
  ExamField(
    'autismRisk',
    'Trẻ có nguy cơ tự kỷ (với trẻ từ 16–30 tháng tuổi)',
    _noYes,
  ),
];

const examImmunization = [
  ExamField('bcg', 'Lao (sơ sinh)', _hasNo),
  ExamField('hepB1', 'Viêm gan B mũi 1 (sơ sinh)', _hasNo),
  ExamField(
    'fullSchedule',
    'Tiêm chủng đầy đủ các loại vắc xin theo độ tuổi',
    _hasNo,
  ),
];

const examClinical = [
  ExamClinicalGroup('1. Toàn trạng', [
    ExamField('skinColor', 'Màu sắc da', [
      ExamOption('PINK', 'Hồng hào'),
      ExamOption('PALE', 'Nhợt', abnormal: true),
      ExamOption('CYANOTIC', 'Tím', abnormal: true),
      ExamOption('YELLOW', 'Vàng', abnormal: true),
      ExamOption('DARK', 'Sạm da', abnormal: true),
    ]),
    ExamField('palms', 'Lòng bàn tay', [
      ExamOption('NORMAL', 'Bình thường (không nhợt)'),
      ExamOption('PALE', 'Không bình thường (nhợt)', abnormal: true),
    ]),
  ]),
  ExamClinicalGroup('2.1. Đầu – cổ', [
    ExamField('headShape', 'Kích thước và hình dạng đầu', _normalOr),
    ExamField('neckMotion', 'Vận động cổ', [
      ExamOption('NORMAL', 'Bình thường'),
      ExamOption('LIMITED', 'Giới hạn', abnormal: true),
    ]),
    ExamField('neckMass', 'Khối bất thường', _noYes),
  ]),
  ExamClinicalGroup('2.2. Khám mắt', [
    ExamField('eyePosition', 'Vị trí 2 mắt', [
      ExamOption('NORMAL', 'Bình thường'),
      ExamOption('WIDE', '2 mắt xa nhau', abnormal: true),
    ]),
    ExamField('eyelids', 'Mí mắt và kết mạc', [
      ExamOption('NORMAL', 'Bình thường'),
      ExamOption('SWOLLEN', 'Sưng/đỏ', abnormal: true),
      ExamOption('DISCHARGE', 'Chảy ghèn/mủ', abnormal: true),
    ]),
    ExamField('strabismus', 'Lác mắt', _noYes),
  ]),
  ExamClinicalGroup('2.3. Khám tai', [
    ExamField('hearing', 'Đáp ứng với âm thanh', _normalOr),
    ExamField('earLump', 'Có khối sưng sau tai', _noYes),
    ExamField('earDischarge', 'Dấu hiệu chảy mủ, nước tai', _noYes),
  ]),
  ExamClinicalGroup('2.4. Khám mũi – họng', [
    ExamField('noseShape', 'Hình dạng mũi', [
      ExamOption('NORMAL', 'Bình thường'),
      ExamOption('BROAD', 'Mũi to, dày', abnormal: true),
      ExamOption('APLASIA', 'Bất sản xương mũi', abnormal: true),
    ]),
    ExamField('runnyNose', 'Chảy nước mũi', _noYes),
    ExamField('nasalCongestion', 'Nghẹt mũi', _noYes),
  ]),
  ExamClinicalGroup('2.5. Khám miệng, răng', [
    ExamField('mouthShape', 'Hình dạng miệng', [
      ExamOption('NORMAL', 'Bình thường'),
      ExamOption('CLEFT', 'Sứt môi, chẻ vòm', abnormal: true),
    ]),
    ExamField('tongueShape', 'Hình dạng lưỡi', [
      ExamOption('NORMAL', 'Bình thường'),
      ExamOption('LARGE', 'Lưỡi to bè', abnormal: true),
    ]),
    ExamField('tongueTie', 'Dính thắng lưỡi', _noYes),
    ExamField('smallChin', 'Cằm nhỏ, tụt về sau', _noYes),
    ExamField('dentalIssue', 'Vết sâu, mảng bám, lỗ trên răng', _noYes),
  ]),
  ExamClinicalGroup('3. Cơ xương và thần kinh', [
    ExamField('asymmetricMotion', 'Vận động không đối xứng', _noYes),
    ExamField('spine', 'Kiểm tra lưng, cột sống', _normalOr),
    ExamField('gait', 'Quan sát dáng đi', _normalOr),
    ExamField(
      'prolongedSadness',
      'Có biểu hiện buồn bã, lo âu, mất ngủ kéo dài không',
      _yesFirst,
    ),
    ExamField(
      'selfHarmRisk',
      'Có hành vi bất thường hoặc nguy cơ tự gây hại không',
      _yesFirst,
    ),
  ]),
];

/// Hướng xử lý và loại vấn đề của kết luận (Web `CONCLUSION_ACTION_LABELS`, `ISSUE_KIND_LABELS`).
const examActionLabels = {
  'NONE': 'Không cần tư vấn hay chuyển khám',
  'ADVICE': 'Tư vấn',
  'REFERRAL': 'Chuyển khám chuyên khoa',
};

const examIssueKindLabels = {
  'NEW': 'Vấn đề mới hoặc có thay đổi',
  'KNOWN': 'Vấn đề đã biết, không thay đổi so với trước',
};

/// Nhóm kết luận BE trả (Web `CONCLUSION_CATEGORY_LABELS`).
const examCategoryLabels = {
  'NORMAL': 'Bình thường',
  'ISSUE': 'Có vấn đề, tư vấn',
  'REFERRAL': 'Chuyển khám chuyên khoa',
  'TB_RISK': 'Nguy cơ lao',
  'FOLLOWING_NO_NEW': 'Đang theo dõi, chưa ghi nhận thêm',
  'FOLLOWING_NEW': 'Đang theo dõi, có bất thường mới',
};
