import 'package:flutter_test/flutter_test.dart';
import 'package:chat_baby_time/services/nlp_parser.dart';
import 'package:chat_baby_time/models/baby_record.dart';

/// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/// 🔬 엣지 케이스 전용 테스트 v2 (Day 7 최종 안정화)
/// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/// 복합문장, 부정문+기록 혼합, STT 극단 오타, 초장문, 동음이의어 등
void main() {
  RecordCategory? extractCategory(ParseResult result) {
    if (result.record?.category != null) return result.record!.category;
    if (result.pendingRecord?.category != null) return result.pendingRecord!.category;
    if (result.needsFeedingTypeDisambiguation) return RecordCategory.feeding;
    if (result.needsMedicineTypeDisambiguation) return RecordCategory.health;
    if (result.needsStoolDetailInput) return RecordCategory.diaper;
    if (result.needsDisambiguation && result.disambiguationOptions!.isNotEmpty) {
      return result.disambiguationOptions!.first.category;
    }
    return null;
  }

  void expectCat(String input, RecordCategory expected, {String? desc}) {
    final result = NlpParser.parse(input);
    final actual = extractCategory(result);
    expect(actual, expected,
        reason: '${desc ?? input} → 기대: ${expected.name}, 실제: ${actual?.name ?? "null"}');
  }

  // ═══════════════════════════════════════════════
  //  1. 오타 내성 테스트
  // ═══════════════════════════════════════════════
  group('오타 내성', () {
    test('수유 오타', () {
      expectCat('분루 120ml 먹엇어', RecordCategory.feeding);
      expectCat('무유 쉬유 15분', RecordCategory.feeding);
      expectCat('짃수 했어', RecordCategory.feeding);
      expectCat('유촉 100ml', RecordCategory.feeding);
      expectCat('ㅂㄴ 120', RecordCategory.feeding);
    });

    test('이유식 오타', () {
      expectCat('이윳식 줬어', RecordCategory.babyfood);
      expectCat('이유싟 먹었어', RecordCategory.babyfood);
      expectCat('이육식 줬어', RecordCategory.babyfood);
    });

    test('기저귀 오타', () {
      expectCat('기져귀 갈앗어', RecordCategory.diaper);
      expectCat('기저기 갈았어', RecordCategory.diaper);
      expectCat('기갈', RecordCategory.diaper);
      expectCat('기갈요', RecordCategory.diaper);
    });

    test('수면 오타', () {
      expectCat('잣어', RecordCategory.sleep);
      expectCat('잠들엇어', RecordCategory.sleep);
      expectCat('재웟어', RecordCategory.sleep);
      expectCat('깻어', RecordCategory.sleep);
      expectCat('일어낫어', RecordCategory.sleep);
    });

    test('건강 오타', () {
      expectCat('체운 37.5도', RecordCategory.health);
      expectCat('해열재 먹였어', RecordCategory.health);
      expectCat('예방접정 했어', RecordCategory.health);
      expectCat('유산귤 줬어', RecordCategory.health);
    });
  });

  // ═══════════════════════════════════════════════
  //  2. 동음이의어 / 문맥 충돌
  // ═══════════════════════════════════════════════
  group('동음이의어/문맥 충돌', () {
    test('두부 = 頭部 vs 豆腐', () {
      expectCat('두부 지탱 발달 확인', RecordCategory.milestone);
      // "두부" 단독은 babyfood
    });

    test('오이 스틱 = snack (not babyfood)', () {
      expectCat('오이 스틱 줬어', RecordCategory.snack);
      expectCat('당근 스틱 먹었어', RecordCategory.snack);
      expectCat('고구마 스틱 줌', RecordCategory.snack);
    });

    test('약 = 약속 vs 투약', () {
      expectCat('약속 잡았어', RecordCategory.other);
      expectCat('약 먹였어', RecordCategory.health);
    });

    test('열 = 열심히 vs 발열', () {
      expectCat('열심히 놀았어', RecordCategory.other);
      expectCat('열 38.0도', RecordCategory.health);
      expectCat('열 떨어졌어', RecordCategory.health);
    });

    test('젖 = 젖었어(옷) vs 수유', () {
      expectCat('젖었어 옷이', RecordCategory.other);
      expectCat('젖 물렸어', RecordCategory.feeding);
    });
  });

  // ═══════════════════════════════════════════════
  //  3. 부정문 + 기록 혼합
  // ═══════════════════════════════════════════════
  group('부정문 + 기록', () {
    test('순수 부정문 → other', () {
      expectCat('분유 안 먹어', RecordCategory.other);
      expectCat('잠을 안 자', RecordCategory.other);
      expectCat('잠을 못 자', RecordCategory.other);
    });

    test('부정 후 전환 → 기록', () {
      expectCat('안 자다가 겨우 잤어', RecordCategory.sleep);
      expectCat('안 자다가 깼어', RecordCategory.sleep);
    });

    test('부정 + 실제 데이터 → 기록', () {
      expectCat('안 먹어서 분유 120ml 겨우 먹였어', RecordCategory.feeding);
    });
  });

  // ═══════════════════════════════════════════════
  //  4. 비기록 문장 (의도/질문/잡담)
  // ═══════════════════════════════════════════════
  group('비기록 문장', () {
    test('질문/고민', () {
      expectCat('분유 어떤 브랜드가 좋을까요', RecordCategory.other);
      expectCat('이유식 레시피 추천좀', RecordCategory.other);
      expectCat('모유 잘 나오는지 모르겠어', RecordCategory.other);
      expectCat('이유식 양 이 정도 맞나', RecordCategory.other);
    });

    test('의도/계획', () {
      expectCat('분유 사와야 해', RecordCategory.other);
      expectCat('이유식 만들어야지', RecordCategory.other);
      expectCat('내일 소아과 검진 예약 확인해야함', RecordCategory.other);
    });

    test('인사/잡담', () {
      expectCat('안녕하세요', RecordCategory.other);
      expectCat('육아 힘들다', RecordCategory.other);
      expectCat('아기 너무 귀엽다', RecordCategory.other);
    });

    test('오탐 방지', () {
      expectCat('무서워했어', RecordCategory.other);
      expectCat('쉬는 날이야', RecordCategory.other);
      expectCat('예약 취소했어', RecordCategory.other);
    });
  });

  // ═══════════════════════════════════════════════
  //  5. 이모지/특수문자 내성
  // ═══════════════════════════════════════════════
  group('이모지/특수문자', () {
    test('이모지 포함 정상 파싱', () {
      expectCat('분유 120ml 먹었어 😊', RecordCategory.feeding);
      expectCat('잠들었어 😴', RecordCategory.sleep);
      expectCat('응가했어 💩', RecordCategory.diaper);
    });

    test('감정 표현 + 기록', () {
      expectCat('아 진짜 겨우 재웠다 ㅠㅠ', RecordCategory.sleep);
      expectCat('세상에 분유 200ml 뚝딱 ㅋㅋ', RecordCategory.feeding);
    });
  });

  // ═══════════════════════════════════════════════
  //  6. 수유 후 구토 → health
  // ═══════════════════════════════════════════════
  group('수유 후 구토', () {
    test('구토 = health', () {
      expectCat('수유 후 게워냈어', RecordCategory.health);
      expectCat('먹다 토했어', RecordCategory.health);
      expectCat('구토했어', RecordCategory.health);
    });
  });

  // ═══════════════════════════════════════════════
  //  7. 성장 마일스톤 다양한 표현
  // ═══════════════════════════════════════════════
  group('성장 마일스톤', () {
    test('대운동 발달', () {
      expectCat('뒤집기 했어', RecordCategory.milestone);
      expectCat('배밀이 시작했어', RecordCategory.milestone);
      expectCat('혼자 걸었어', RecordCategory.milestone);
      expectCat('잡고 서기 성공', RecordCategory.milestone);
    });

    test('사회/인지 발달', () {
      expectCat('분리불안 시작', RecordCategory.milestone);
      expectCat('눈 맞춤 했어', RecordCategory.milestone);
      expectCat('사회적 미소 관찰됨', RecordCategory.milestone);
      expectCat('낯가림 시작됐어', RecordCategory.milestone);
    });

    test('시간접두사 + 성장', () {
      expectCat('오후 2시 눈 맞춤 했어', RecordCategory.milestone);
      expectCat('아침에 뒤집기 했어', RecordCategory.milestone);
    });
  });

  // ═══════════════════════════════════════════════
  //  📊 전체 결과 요약
  // ═══════════════════════════════════════════════
  test('📊 엣지 케이스 전체 결과', () {
    final edgeCases = <Map<String, dynamic>>[
      // 오타
      {'input': '분루 120ml 먹엇어', 'expected': 'feeding'},
      {'input': '이윳식 줬어', 'expected': 'babyfood'},
      {'input': '기져귀 갈앗어', 'expected': 'diaper'},
      {'input': '잣어', 'expected': 'sleep'},
      {'input': '체운 37.5도', 'expected': 'health'},
      // 동음이의어
      {'input': '두부 지탱 발달 확인', 'expected': 'milestone'},
      {'input': '오이 스틱 줬어', 'expected': 'snack'},
      {'input': '약속 잡았어', 'expected': 'other'},
      {'input': '열심히 놀았어', 'expected': 'other'},
      {'input': '젖었어 옷이', 'expected': 'other'},
      // 부정문
      {'input': '분유 안 먹어', 'expected': 'other'},
      {'input': '안 자다가 겨우 잤어', 'expected': 'sleep'},
      // 비기록
      {'input': '안녕하세요', 'expected': 'other'},
      {'input': '분유 사와야 해', 'expected': 'other'},
      {'input': '이유식 레시피 추천좀', 'expected': 'other'},
      // 구토
      {'input': '수유 후 게워냈어', 'expected': 'health'},
      // 마일스톤
      {'input': '분리불안 시작', 'expected': 'milestone'},
      {'input': '오후 2시 눈 맞춤 했어', 'expected': 'milestone'},
      // 이모지
      {'input': '분유 120ml 먹었어 😊', 'expected': 'feeding'},
      {'input': '아 진짜 겨우 재웠다 ㅠㅠ', 'expected': 'sleep'},
    ];

    final catMap = <String, RecordCategory>{
      'feeding': RecordCategory.feeding, 'sleep': RecordCategory.sleep,
      'diaper': RecordCategory.diaper, 'health': RecordCategory.health,
      'babyfood': RecordCategory.babyfood, 'snack': RecordCategory.snack,
      'milestone': RecordCategory.milestone, 'other': RecordCategory.other,
    };

    var pass = 0;
    var fail = 0;
    for (final tc in edgeCases) {
      final result = NlpParser.parse(tc['input'] as String);
      final expected = catMap[tc['expected'] as String];
      final actual = extractCategory(result);
      if (actual == expected) {
        pass++;
      } else {
        fail++;
        print('❌ "${tc['input']}" → 기대: ${tc['expected']}, 실제: ${actual?.name ?? "null"}');
      }
    }
    final pct = (pass / (pass + fail) * 100).toStringAsFixed(1);
    print('\n📊 엣지 케이스 결과: $pass/${pass + fail} ($pct%)');
    expect(pass / (pass + fail), greaterThanOrEqualTo(0.95),
        reason: '엣지 케이스 정확도 95% 이상 필요');
  });
}
