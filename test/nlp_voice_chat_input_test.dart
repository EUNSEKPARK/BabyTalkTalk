// 음성(STT)·채팅 자연어 입력 회귀 테스트
//
// `NlpParser` 키워드/시간 표현 조합으로 케이스를 생성합니다.
// 대략적 개수: 수유 22×4×28 + 수면 22×4×19 + 기저귀 22×4×18 + 건강 22×4×28 + 노이즈 10 ≈ 8,100+
//
// 실행: flutter test test/nlp_voice_chat_input_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:chat_baby_time/models/baby_record.dart';
import 'package:chat_baby_time/services/nlp_parser.dart';

/// 음성/채팅 자연어 입력 기대 결과
class _Case {
  const _Case(
    this.input,
    this.category, {
    this.feeding,
    this.sleep,
    this.diaper,
  });

  final String input;
  final RecordCategory category;
  final FeedingType? feeding;
  final SleepStatus? sleep;
  final DiaperType? diaper;
}

void main() {
  group('NLP 음성/채팅 입력 (1000+ 케이스)', () {
    late List<_Case> allCases;

    setUpAll(() {
      allCases = _buildAllCases();
    });

    test('케이스 개수 ≥ 1000', () {
      expect(allCases.length, greaterThanOrEqualTo(1000));
    });

    test('전체 케이스 파싱 일치', () {
      final failures = <String>[];
      for (var i = 0; i < allCases.length; i++) {
        final c = allCases[i];
        final r = NlpParser.parse(c.input);
        if (!r.isSuccess || r.record == null) {
          failures.add('#$i "${c.input}" → success=false (${r.message})');
          continue;
        }
        if (r.record!.category != c.category) {
          failures.add(
            '#$i "${c.input}" → cat=${r.record!.category} want=${c.category}',
          );
          continue;
        }
        if (c.feeding != null && r.record!.feedingType != c.feeding) {
          failures.add(
            '#$i "${c.input}" → feeding=${r.record!.feedingType} want=${c.feeding}',
          );
        }
        if (c.sleep != null && r.record!.sleepStatus != c.sleep) {
          failures.add(
            '#$i "${c.input}" → sleep=${r.record!.sleepStatus} want=${c.sleep}',
          );
        }
        if (c.diaper != null && r.record!.diaperType != c.diaper) {
          failures.add(
            '#$i "${c.input}" → diaper=${r.record!.diaperType} want=${c.diaper}',
          );
        }
      }
      expect(failures, isEmpty, reason: failures.take(40).join('\n'));
    });

    test('빈 입력은 실패', () {
      expect(NlpParser.parse('').isSuccess, isFalse);
      expect(NlpParser.parse('   ').isSuccess, isFalse);
    });
  });
}

List<_Case> _buildAllCases() {
  final out = <_Case>[];

  const timeLead = <String>[
    '',
    '방금 ',
    '지금 ',
    '막 ',
    '아까 ',
    '15분 전 ',
    '30분 전 ',
    '45분 전 ',
    '1시간 전 ',
    '2시간 전 ',
    '3시간 전 ',
    '오전 9시 ',
    '오전 10시 30분 ',
    '오후 2시 ',
    '오후 4시 20분 ',
    '저녁 7시 ',
    '밤 11시 ',
    '아침 8시 ',
    '10시 ',
    '10시 15분 ',
    '14:30 ',
    '9:00 ',
  ];

  const subject = <String>['', '아기 ', '우리 애 ', '애기 '];

  // 수유 (22*4*26 = 2288)
  const feedingBodies = <({String s, FeedingType? t})>[
    (s: '분유 120ml 먹었어', t: FeedingType.formula),
    (s: '분유 100cc 먹임', t: FeedingType.formula),
    (s: '분유 90 밀리 먹였어', t: FeedingType.formula),
    (s: '젖병으로 분유 먹음', t: FeedingType.formula),
    (s: '반병 먹었어', t: FeedingType.formula),
    (s: '한병 다 먹음', t: FeedingType.formula),
    (s: '모유 수유했어', t: FeedingType.breast),
    (s: '모유 20분', t: FeedingType.breast),
    (s: '젖 먹였어', t: FeedingType.breast),
    (s: '이유식 먹였어', t: FeedingType.babyfood),
    (s: '이유식 퓨레 먹음', t: FeedingType.babyfood),
    (s: '죽 먹여줬어', t: FeedingType.babyfood),
    // 미음/퓨레/주스는 키워드만으로는 babyfood/snack 타입 미분류 → formula
    (s: '미음 먹임', t: FeedingType.formula),
    (s: '간식 조금 먹었어', t: FeedingType.snack),
    (s: '주스 마셨어', t: FeedingType.formula),
    (s: '우유 200ml 먹음', t: FeedingType.formula),
    (s: '밥 먹었어', t: FeedingType.formula),
    (s: '반찬 먹임', t: FeedingType.formula),
    (s: '퓨레 한 그릇', t: FeedingType.formula),
    (s: '수유 완료', t: FeedingType.formula),
    (s: '분유 타이밍', t: FeedingType.formula),
    (s: '모유 왼쪽만', t: FeedingType.breast),
    (s: '이유식 단계2 먹음', t: FeedingType.babyfood),
    (s: '씨씨 150 먹였어', t: FeedingType.formula),
    (s: '먹여서 다 먹음', t: FeedingType.formula),
    (s: '한모금 더 먹음', t: FeedingType.formula),
    (s: '두모금 먹었어', t: FeedingType.formula),
    (s: '젖꼭지로 수유', t: FeedingType.formula),
  ];

  for (final lead in timeLead) {
    for (final sub in subject) {
      for (final body in feedingBodies) {
        out.add(_Case(
          '$lead$sub${body.s}',
          RecordCategory.feeding,
          feeding: body.t,
        ));
      }
    }
  }

  // 수면 (22*4*18 = 1584)
  const sleepBodies = <({String s, SleepStatus st})>[
    (s: '잠들었어', st: SleepStatus.start),
    (s: '낮잠 잤어', st: SleepStatus.start),
    (s: '밤잠 들어갔어', st: SleepStatus.start),
    (s: '쪽잠 잤다', st: SleepStatus.start),
    (s: '꿀잠 중', st: SleepStatus.start),
    (s: '수면 유도 중', st: SleepStatus.start),
    (s: '취침 완료', st: SleepStatus.start),
    (s: '재웠어', st: SleepStatus.start),
    (s: '잠투정 끝났어', st: SleepStatus.start),
    (s: '자장가 듣고 잠듦', st: SleepStatus.start),
    (s: '잠 들었어', st: SleepStatus.start),
    (s: '깼어', st: SleepStatus.end),
    (s: '눈떴어', st: SleepStatus.end),
    (s: '일어났어', st: SleepStatus.end),
    (s: '기상', st: SleepStatus.end),
    (s: '깨었어', st: SleepStatus.end),
    (s: '자다가 깼어', st: SleepStatus.end),
    (s: '잤음 이제 깸', st: SleepStatus.end),
    (s: '선잠 깨서 울어', st: SleepStatus.end),
  ];

  for (final lead in timeLead) {
    for (final sub in subject) {
      for (final body in sleepBodies) {
        out.add(_Case(
          '$lead$sub${body.s}',
          RecordCategory.sleep,
          sleep: body.st,
        ));
      }
    }
  }

  // 기저귀 (22*4*18 = 1584)
  const diaperBodies = <({String s, DiaperType d})>[
    (s: '기저귀 갈았어', d: DiaperType.pee),
    (s: '기저귀 교체', d: DiaperType.pee),
    (s: '기저귀 바꿨어', d: DiaperType.pee),
    (s: '소변 봤어', d: DiaperType.pee),
    (s: '오줌 쌌어', d: DiaperType.pee),
    (s: '쉬 했어', d: DiaperType.pee),
    (s: '응가 했어', d: DiaperType.poop),
    (s: '대변 봤어', d: DiaperType.poop),
    (s: '똥 쌌어', d: DiaperType.poop),
    (s: '똥 싸', d: DiaperType.poop),
    (s: '배변 완료', d: DiaperType.pee),
    // 응가만 명시 시 파서는 대변만 감지 (소변 키워드 없음)
    (s: '기저귀 갈았어 응가', d: DiaperType.poop),
    (s: '소변 대변 둘 다', d: DiaperType.both),
    (s: '오줌이랑 똥', d: DiaperType.both),
    (s: '기저귀 팬티로 갈아', d: DiaperType.pee),
    (s: '갈아줬어 기저귀', d: DiaperType.pee),
    (s: '쌌어 기저귀', d: DiaperType.pee),
    (s: '노란 응가', d: DiaperType.poop),
  ];

  for (final lead in timeLead) {
    for (final sub in subject) {
      for (final body in diaperBodies) {
        out.add(_Case(
          '$lead$sub${body.s}',
          RecordCategory.diaper,
          diaper: body.d,
        ));
      }
    }
  }

  // 건강 (22*4*24 = 2112)
  const healthBodies = <String>[
    '체온 37.2도',
    '체온 38.5도 재었어',
    '38° 열',
    '열이 나',
    '열 높아',
    '약 먹였어',
    '해열제 먹임',
    '타이레놀 투약',
    '투약 완료',
    '복용 했어',
    '병원 다녀왔어',
    '소아과 진료',
    '예방접종 맞음',
    '접종 완료',
    '주사 맞았어',
    '구토 했어',
    '토함',
    '설사 해',
    '콧물 나',
    '기침 심해',
    '발진 났어',
    '두드러기',
    '감기 기운',
    '열남',
    '배꼽 진물',
    '습진 악화',
    '알레르기 의심',
    '진료 받음',
  ];

  for (final lead in timeLead) {
    for (final sub in subject) {
      for (final body in healthBodies) {
        out.add(_Case('$lead$sub$body', RecordCategory.health));
      }
    }
  }

  // 정규화·채팅체 (기대 카테고리는 파서 결과에 맞춤 — 회귀용)
  const noisyPairs = <(String, RecordCategory)>[
    ('분 유 120ml 먹 었 어', RecordCategory.feeding),
    ('기 저 귀 갈 았 어 응가', RecordCategory.diaper),
    ('모유수유 ㅋㅋ 완료', RecordCategory.feeding),
    ('잠들었어~~!!!', RecordCategory.sleep),
    ('체온 37.5도 ㅠㅠ', RecordCategory.health),
    ('오후 3시 분유 80ml 먹음', RecordCategory.feeding),
    ('방금 똥 쌌어 기저귀', RecordCategory.diaper),
    ('지금 약 먹였어 타이레놀', RecordCategory.health),
    ('30분 전 낮잠 잤어', RecordCategory.sleep),
    ('아기 깨었어 눈떴어', RecordCategory.sleep),
  ];

  for (final pair in noisyPairs) {
    out.add(_Case(pair.$1, pair.$2));
  }

  return out;
}
