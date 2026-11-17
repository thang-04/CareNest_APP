import 'package:carenest_app/features/parent/health_book/domain/health_book.dart';
import 'package:carenest_app/features/parent/parent_home/data/fake_parent_home_source.dart';

/// Sổ sức khỏe giả (user 17/11: dựng mock, tạm bỏ qua BE). Nhãn phiếu khám theo Phụ lục II của FE
/// (`healthExamForm.js`); tên đợt, bác sĩ, lời dặn theo dữ liệu mẫu của BE. Minh Anh có đủ ba phần;
/// Bảo Ngọc chưa có nhận định xu hướng.
class FakeHealthBookSource implements HealthBookSource {
  const FakeHealthBookSource({
    this.mode = FakeMode.data,
    this.delay = const Duration(milliseconds: 300),
  });

  final FakeMode mode;
  final Duration delay;

  static const _examiner = 'Trạm Y tế xã Thượng Hồng';

  static const _noHistory = [
    ExamItem('Tiền sử bản thân', 'Không'),
    ExamItem('Tiền sử gia đình', 'Không'),
    ExamItem('Tiền sử tiếp xúc với người bệnh lao', 'Không'),
  ];

  static const _development = [
    ExamItem('Phát triển tinh thần bình thường của trẻ theo độ tuổi', 'Có'),
    ExamItem('Phát triển vận động bình thường của trẻ theo độ tuổi', 'Có'),
  ];

  static const _immunization = [
    ExamItem('Lao (sơ sinh)', 'Có'),
    ExamItem('Viêm gan B mũi 1 (sơ sinh)', 'Có'),
    ExamItem('Tiêm chủng đầy đủ các loại vắc xin theo độ tuổi', 'Có'),
  ];

  static List<ExamVital> _vitals(
    String temperature,
    String pulse,
    String rate,
  ) => [
    ExamVital(
      label: 'Nhiệt độ',
      value: '$temperature °C',
      status: 'Bình thường',
    ),
    ExamVital(label: 'Mạch', value: '$pulse lần/phút', status: 'Bình thường'),
    ExamVital(
      label: 'Nhịp thở',
      value: '$rate lần/phút',
      status: 'Bình thường',
    ),
  ];

  /// 24 mục khám lâm sàng của phiếu; [cavities] ⇒ có vết sâu răng.
  static List<ExamSection> _clinical({bool cavities = false}) => [
    const ExamSection('1. Toàn trạng', [
      ExamItem('Màu sắc da', 'Hồng hào'),
      ExamItem('Lòng bàn tay', 'Bình thường (không nhợt)'),
    ]),
    const ExamSection('2.1. Đầu – cổ', [
      ExamItem('Kích thước và hình dạng đầu', 'Bình thường'),
      ExamItem('Vận động cổ', 'Bình thường'),
      ExamItem('Khối bất thường', 'Không'),
    ]),
    const ExamSection('2.2. Khám mắt', [
      ExamItem('Vị trí 2 mắt', 'Bình thường'),
      ExamItem('Mí mắt và kết mạc', 'Bình thường'),
      ExamItem('Lác mắt', 'Không'),
    ]),
    const ExamSection('2.3. Khám tai', [
      ExamItem('Đáp ứng với âm thanh', 'Bình thường'),
      ExamItem('Có khối sưng sau tai', 'Không'),
      ExamItem('Dấu hiệu chảy mủ, nước tai', 'Không'),
    ]),
    const ExamSection('2.4. Khám mũi – họng', [
      ExamItem('Hình dạng mũi', 'Bình thường'),
      ExamItem('Chảy nước mũi', 'Không'),
      ExamItem('Nghẹt mũi', 'Không'),
    ]),
    ExamSection('2.5. Khám miệng, răng', [
      const ExamItem('Hình dạng miệng', 'Bình thường'),
      const ExamItem('Hình dạng lưỡi', 'Bình thường'),
      const ExamItem('Dính thắng lưỡi', 'Không'),
      const ExamItem('Cằm nhỏ, tụt về sau', 'Không'),
      ExamItem(
        'Vết sâu, mảng bám, lỗ trên răng',
        cavities ? 'Có' : 'Không',
        abnormal: cavities,
      ),
    ]),
    const ExamSection('3. Cơ xương và thần kinh', [
      ExamItem('Vận động không đối xứng', 'Không'),
      ExamItem('Kiểm tra lưng, cột sống', 'Bình thường'),
      ExamItem('Quan sát dáng đi', 'Bình thường'),
      ExamItem('Có biểu hiện buồn bã, lo âu, mất ngủ kéo dài không', 'Không'),
      ExamItem('Có hành vi bất thường hoặc nguy cơ tự gây hại không', 'Không'),
    ]),
  ];

  static final _minhAnh = HealthBook(
    rounds: [
      MeasurementRound(
        id: 'r-2026-10',
        name: 'Cân đo định kỳ tháng 10/2026',
        date: DateTime(2026, 10, 12),
        ageMonths: 50,
        heightCm: 104,
        weightKg: 17.2,
        bmi: 15.9,
        bmiLevel: BmiLevel.normal,
        note: 'Cân sau bữa ăn sáng.',
      ),
      MeasurementRound(
        id: 'r-2026-07',
        name: 'Cân đo định kỳ tháng 7/2026',
        date: DateTime(2026, 7, 15),
        ageMonths: 47,
        heightCm: 102.5,
        weightKg: 16.8,
        bmi: 16,
        bmiLevel: BmiLevel.normal,
      ),
      MeasurementRound(
        id: 'r-2026-04',
        name: 'Cân đo định kỳ tháng 4/2026',
        date: DateTime(2026, 4, 16),
        ageMonths: 44,
        heightCm: 101,
        weightKg: 16.4,
        bmi: 16.1,
        bmiLevel: BmiLevel.normal,
        note: 'Bé vừa khỏi ốm, ăn kém mấy hôm trước.',
      ),
      MeasurementRound(
        id: 'r-2026-01',
        name: 'Cân đo định kỳ tháng 1/2026',
        date: DateTime(2026, 1, 14),
        ageMonths: 41,
        heightCm: 99.5,
        weightKg: 15.9,
        bmi: 16.1,
        bmiLevel: BmiLevel.normal,
      ),
    ],
    exams: [
      HealthExam(
        id: 'exam-2026',
        name: 'Khám sức khỏe đầu năm học 2026-2027',
        date: DateTime(2026, 9, 18),
        ageMonths: 49,
        examiner: _examiner,
        doctorName: 'BS. Nguyễn Thị Hằng',
        followUp: FollowUpLevel.watch,
        conclusion: 'Có vấn đề về sức khỏe',
        issueText: 'Sâu răng',
        issueKind: 'Vấn đề mới hoặc có thay đổi',
        action: 'Tư vấn',
        advice:
            'Chải răng cho bé 2 lần mỗi ngày, hạn chế đồ ngọt buổi tối, đưa bé khám răng định kỳ.',
        nutritionStatus: 'Bình thường',
        history: _noHistory,
        vitals: _vitals('36,7', '102', '24'),
        nutrition: const [
          ExamItem('Chiều cao', '103,4 cm'),
          ExamItem('Cân nặng', '17 kg'),
          ExamItem('BMI', '15,9'),
          ExamItem('Chiều cao theo tuổi', '0,1 SD'),
          ExamItem('Cân nặng theo tuổi', '0,3 SD'),
          ExamItem('Vòng đầu', '49,5 cm · Bình thường'),
          ExamItem('Vòng cánh tay', '160 mm'),
        ],
        development: _development,
        immunization: _immunization,
        clinical: _clinical(cavities: true),
      ),
      HealthExam(
        id: 'exam-2025',
        name: 'Khám sức khỏe đầu năm học 2025-2026',
        date: DateTime(2025, 9, 22),
        ageMonths: 37,
        examiner: _examiner,
        doctorName: 'BS. Lương Thị Mai',
        followUp: FollowUpLevel.none,
        conclusion: 'Bình thường',
        action: 'Không cần tư vấn hay chuyển khám',
        nutritionStatus: 'Bình thường',
        history: _noHistory,
        vitals: _vitals('36,6', '106', '26'),
        nutrition: const [
          ExamItem('Chiều cao', '97,8 cm'),
          ExamItem('Cân nặng', '15,2 kg'),
          ExamItem('BMI', '15,9'),
          ExamItem('Chiều cao theo tuổi', '0 SD'),
          ExamItem('Cân nặng theo tuổi', '0,2 SD'),
          ExamItem('Vòng đầu', '48,8 cm · Bình thường'),
          ExamItem('Vòng cánh tay', '155 mm'),
        ],
        development: _development,
        immunization: _immunization,
        clinical: _clinical(),
      ),
    ],
    growth: [
      GrowthPoint(
        date: DateTime(2025, 9, 22),
        heightCm: 97.8,
        weightKg: 15.2,
        fromExam: true,
      ),
      GrowthPoint(date: DateTime(2026, 1, 14), heightCm: 99.5, weightKg: 15.9),
      GrowthPoint(date: DateTime(2026, 4, 16), heightCm: 101, weightKg: 16.4),
      GrowthPoint(date: DateTime(2026, 7, 15), heightCm: 102.5, weightKg: 16.8),
      GrowthPoint(
        date: DateTime(2026, 9, 18),
        heightCm: 103.4,
        weightKg: 17,
        fromExam: true,
      ),
      GrowthPoint(date: DateTime(2026, 10, 12), heightCm: 104, weightKg: 17.2),
    ],
    interpretation: TrendInterpretation(
      periodLabel: 'Phân tích 6 tháng',
      approvedOn: DateTime(2026, 10, 14),
      overview:
          'Trong 6 tháng qua, chiều cao của bé tăng từ 101 cm lên 104 cm và cân nặng tăng từ 16,4 kg lên 17,2 kg qua 4 lần đo. Các chỉ số lần đo gần nhất nằm trong khoảng bình thường theo chuẩn WHO.',
      positives: [
        'Chiều cao tăng đều qua các lần đo.',
        'Cân nặng tăng dần, không có lần giảm.',
      ],
      limitations: 'Nhận định chỉ dựa trên số đo cân đo và khám tại trường.',
    ),
  );

  static final _baoNgoc = HealthBook(
    rounds: [
      MeasurementRound(
        id: 'r2-2026-10',
        name: 'Cân đo định kỳ tháng 10/2026',
        date: DateTime(2026, 10, 12),
        ageMonths: 62,
        heightCm: 110.2,
        weightKg: 18.6,
        bmi: 15.3,
        bmiLevel: BmiLevel.normal,
      ),
      MeasurementRound(
        id: 'r2-2026-07',
        name: 'Cân đo định kỳ tháng 7/2026',
        date: DateTime(2026, 7, 15),
        ageMonths: 59,
        heightCm: 109,
        weightKg: 18.1,
        bmi: 15.2,
        bmiLevel: BmiLevel.normal,
      ),
    ],
    exams: [
      HealthExam(
        id: 'exam2-2026',
        name: 'Khám sức khỏe đầu năm học 2026-2027',
        date: DateTime(2026, 9, 18),
        ageMonths: 61,
        examiner: _examiner,
        doctorName: 'BS. Phạm Văn Đức',
        followUp: FollowUpLevel.none,
        conclusion: 'Bình thường',
        action: 'Không cần tư vấn hay chuyển khám',
        nutritionStatus: 'Bình thường',
        history: _noHistory,
        vitals: _vitals('36,8', '98', '22'),
        // Trên 60 tháng: phiếu không đo vòng đầu
        nutrition: const [
          ExamItem('Chiều cao', '109,8 cm'),
          ExamItem('Cân nặng', '18,4 kg'),
          ExamItem('BMI', '15,3'),
          ExamItem('Chiều cao theo tuổi', '0,2 SD'),
          ExamItem('Cân nặng theo tuổi', '0,1 SD'),
          ExamItem('Vòng cánh tay', '165 mm'),
        ],
        development: _development,
        immunization: _immunization,
        clinical: _clinical(),
      ),
    ],
    growth: [
      GrowthPoint(date: DateTime(2026, 7, 15), heightCm: 109, weightKg: 18.1),
      GrowthPoint(
        date: DateTime(2026, 9, 18),
        heightCm: 109.8,
        weightKg: 18.4,
        fromExam: true,
      ),
      GrowthPoint(
        date: DateTime(2026, 10, 12),
        heightCm: 110.2,
        weightKg: 18.6,
      ),
    ],
  );

  @override
  Future<HealthBook> load(String childId) async {
    await Future<void>.delayed(delay);
    if (mode == FakeMode.error) throw StateError('Không tải được dữ liệu giả');
    if (mode == FakeMode.empty) {
      return const HealthBook(rounds: [], exams: [], growth: []);
    }
    return childId == 'child-2' ? _baoNgoc : _minhAnh;
  }
}
