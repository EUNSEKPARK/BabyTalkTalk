import 'package:flutter_test/flutter_test.dart';
import 'package:chat_baby_time/services/nlp_parser.dart';
import 'package:chat_baby_time/models/baby_record.dart';

void main() {
  // ============================================================
  // 테스트 유틸리티
  // ============================================================

  void expectCategory(String input, RecordCategory expected, {String? desc}) {
    final result = NlpParser.parse(input);
    final label = desc ?? input;
    expect(
      result.record?.category,
      expected,
      reason: '[$label] → 기대: ${expected.name}, 실제: ${result.record?.category?.name ?? "null"} (conf: ${result.confidence})',
    );
  }

  void expectCategoryNot(String input, RecordCategory notExpected, {String? desc}) {
    final result = NlpParser.parse(input);
    final label = desc ?? input;
    expect(
      result.record?.category,
      isNot(notExpected),
      reason: '[$label] → ${notExpected.name}으로 오분류됨 (conf: ${result.confidence})',
    );
  }

  // ============================================================
  // 1. 수유 카테고리 테스트
  // ============================================================
  group('수유(Feeding) 인식 테스트', () {
    test('분유 기본 인식', () {
      expectCategory('분유 먹었어', RecordCategory.feeding);
      expectCategory('분유 120ml', RecordCategory.feeding);
      expectCategory('분유 먹음', RecordCategory.feeding);
    });

    test('모유 인식', () {
      expectCategory('모유 수유 15분', RecordCategory.feeding);
      expectCategory('모유 먹었어', RecordCategory.feeding);
    });

    test('이유식 인식', () {
      expectCategory('이유식 먹었어', RecordCategory.feeding);
      expectCategory('죽 먹였어', RecordCategory.feeding);
    });

    test('간식 인식', () {
      expectCategory('간식 먹었어', RecordCategory.feeding);
    });

    test('밥+숫자 → 분유/이유식 객관식, 선택 후 ml·타입 반영', () {
      final ambiguous = NlpParser.parse('밥 120 먹었어');
      expect(ambiguous.needsFeedingTypeDisambiguation, true);
      expect(ambiguous.pendingRawInput, '밥 120 먹었어');

      final asFormula = NlpParser.parseWithFeedingType(
        '밥 120 먹었어',
        FeedingType.formula,
      );
      expect(asFormula.isSuccess, true);
      expect(asFormula.record?.feedingType, FeedingType.formula);
      expect(asFormula.record?.amountMl, 120);

      final asBabyfood = NlpParser.parseWithFeedingType(
        '밥 120 먹었어',
        FeedingType.babyfood,
      );
      expect(asBabyfood.isSuccess, true);
      expect(asBabyfood.record?.feedingType, FeedingType.babyfood);
      expect(asBabyfood.record?.amountMl, 120);

      final clear = NlpParser.parse('분유 120ml 먹었어');
      expect(clear.needsFeedingTypeDisambiguation, false);
      expect(clear.isSuccess, true);
    });

    test('ml 단위 인식', () {
      final result = NlpParser.parse('분유 120ml 먹었어');
      expect(result.record?.amountMl, 120);
    });

    test('cc 단위 인식', () {
      final result = NlpParser.parse('분유 100cc');
      expect(result.record?.amountMl, 100);
    });

    test('수유 시간(분) 인식', () {
      final result = NlpParser.parse('모유 수유 15분');
      expect(result.record?.durationMinutes, 15);
    });

    test('FeedingType 올바른 분류', () {
      expect(NlpParser.parse('모유 먹었어').record?.feedingType, FeedingType.breast);
      expect(NlpParser.parse('분유 120ml').record?.feedingType, FeedingType.formula);
      expect(NlpParser.parse('이유식 먹였어').record?.feedingType, FeedingType.babyfood);
      expect(NlpParser.parse('간식 먹었어').record?.feedingType, FeedingType.snack);
    });
  });

  // ============================================================
  // 2. 수면 카테고리 테스트
  // ============================================================
  group('수면(Sleep) 인식 테스트', () {
    test('잠듦 인식', () {
      expectCategory('아기 잠들었어', RecordCategory.sleep);
      expectCategory('낮잠 잤어', RecordCategory.sleep);
      expectCategory('재웠어', RecordCategory.sleep);
      expectCategory('취침', RecordCategory.sleep);
    });

    test('깨어남 인식', () {
      final result1 = NlpParser.parse('아기 깼어');
      expect(result1.record?.sleepStatus, SleepStatus.end);

      final result2 = NlpParser.parse('기상했어');
      expect(result2.record?.sleepStatus, SleepStatus.end);

      final result3 = NlpParser.parse('눈떴어');
      expect(result3.record?.sleepStatus, SleepStatus.end);
    });

    test('잠듦 상태 기본값', () {
      final result = NlpParser.parse('아기 잠들었어');
      expect(result.record?.sleepStatus, SleepStatus.start);
    });
  });

  // ============================================================
  // 3. 기저귀 카테고리 테스트
  // ============================================================
  group('기저귀(Diaper) 인식 테스트', () {
    test('기저귀 기본 인식', () {
      expectCategory('기저귀 갈았어', RecordCategory.diaper);
      expectCategory('기저귀 교체', RecordCategory.diaper);
    });

    test('응가 인식', () {
      expectCategory('응가 했어', RecordCategory.diaper);
      final result = NlpParser.parse('응가 했어');
      expect(result.record?.diaperType, DiaperType.poop);
    });

    test('대변/소변 복합', () {
      final result = NlpParser.parse('기저귀 갈았어 대변 소변');
      expect(result.record?.diaperType, DiaperType.both);
    });

    test('소변만', () {
      final result = NlpParser.parse('소변 봤어 기저귀 갈았어');
      expect(result.record?.diaperType, DiaperType.pee);
    });
  });

  // ============================================================
  // 4. 건강 카테고리 테스트
  // ============================================================
  group('건강(Health) 인식 테스트', () {
    test('체온 인식', () {
      expectCategory('체온 37.5도', RecordCategory.health);
      final result = NlpParser.parse('체온 37.5도');
      expect(result.record?.temperature, 37.5);
    });

    test('열 인식', () {
      expectCategory('열이 나요', RecordCategory.health);
      expectCategory('열 높아요', RecordCategory.health);
    });

    test('약 인식', () {
      expectCategory('약 먹였어', RecordCategory.health);
      expectCategory('해열제 먹였어', RecordCategory.health);
    });

    test('병원/예방접종 인식', () {
      expectCategory('병원 다녀왔어', RecordCategory.health);
      expectCategory('예방접종 맞았어', RecordCategory.health);
    });

    test('감기 증상 인식', () {
      expectCategory('콧물 나요', RecordCategory.health);
      expectCategory('기침 해요', RecordCategory.health);
    });
  });

  // ============================================================
  // 5. ★ 기존 오탐 문제 해결 테스트 (핵심!)
  // ============================================================
  group('★ 오탐 방지 테스트 (v2 핵심 개선)', () {
    test('[P0] "도" 조사 → 건강으로 오분류 방지', () {
      // 기존: "도"가 건강 키워드여서 "분유도 먹었어"가 건강으로 잡힘
      expectCategory('분유도 먹었어', RecordCategory.feeding);
      expectCategory('잠도 잤어', RecordCategory.sleep);
      expectCategoryNot('오늘도 힘내자', RecordCategory.health, desc: '"도" 조사 오탐');
    });

    test('[P0] "변" 단독 → 기저귀 오분류 방지', () {
      // 기존: "변"이 기저귀 키워드여서 "변경", "변화" 등이 기저귀로 잡힘
      expectCategoryNot('일정 변경했어', RecordCategory.diaper, desc: '"변경"의 "변" 오탐');
      expectCategoryNot('변화가 생겼어', RecordCategory.diaper, desc: '"변화"의 "변" 오탐');
    });

    test('[P0] "쉬" 단독 → 기저귀 오분류 방지', () {
      // 기존: "쉬"가 기저귀 키워드여서 "쉬다", "쉬운" 등이 기저귀로 잡힘
      expectCategoryNot('좀 쉬어야겠다', RecordCategory.diaper, desc: '"쉬다"의 "쉬" 오탐');
    });

    test('[P0] "싸" 단독 → 기저귀 오분류 방지', () {
      // 기존: "싸"가 기저귀 키워드여서 "싸다" 등이 기저귀로 잡힘
      expectCategoryNot('물건이 싸다', RecordCategory.diaper, desc: '"싸다"의 "싸" 오탐');
    });

    test('[P0] "자" 단독 → 수면 오분류 방지', () {
      // 기존: "자"가 수면 키워드여서 "자두", "자리" 등이 수면으로 잡힘
      expectCategoryNot('자두 먹었어', RecordCategory.sleep, desc: '"자두"의 "자" 오탐');
    });

    test('[P0] "물" 단독 → 수유 오분류 방지', () {
      // 기존: "물"이 수유 키워드여서 "물건", "물론" 등이 수유로 잡힘
      expectCategoryNot('물건을 샀어', RecordCategory.feeding, desc: '"물건"의 "물" 오탐');
      expectCategoryNot('물론이지', RecordCategory.feeding, desc: '"물론"의 "물" 오탐');
    });

    test('[P0] "약 먹었어" → 건강(약)으로 정확히 분류 (기존: 수유 오분류)', () {
      // 기존: "먹"이 수유 키워드여서 "약 먹었어"가 수유로 잡힘
      expectCategory('약 먹였어', RecordCategory.health);
      expectCategory('약 먹었어', RecordCategory.health);
    });

    test('[P0] "밥" 단독은 맥락 없이 수유로 안 잡힘', () {
      // "밥 먹었어"에서 "먹었"이 수유 키워드로 잡혀야 함
      expectCategoryNot('밥상 차리자', RecordCategory.feeding, desc: '"밥상"의 "밥" 오탐');
    });
  });

  // ============================================================
  // 6. 시간 파싱 테스트
  // ============================================================
  group('시간 파싱 테스트', () {
    test('오전/오후 시간 인식', () {
      final result = NlpParser.parse('오후 2시에 분유 120ml 먹음');
      expect(result.record?.timestamp.hour, 14);
    });

    test('시간+분 인식', () {
      final result = NlpParser.parse('오전 10시 30분에 모유 수유');
      expect(result.record?.timestamp.hour, 10);
      expect(result.record?.timestamp.minute, 30);
    });

    test('"분유"의 "분"이 시간으로 잘못 파싱되지 않음', () {
      final result = NlpParser.parse('분유 먹었어');
      // 분유의 "분"이 시간으로 잡히면 안 됨 → 현재 시간이어야 함
      final now = DateTime.now();
      expect(result.record?.timestamp.hour, now.hour);
    });
  });

  // ============================================================
  // 7. confidence 동적 계산 테스트
  // ============================================================
  group('Confidence 동적 계산 테스트', () {
    test('명확한 입력 → 높은 confidence', () {
      final result = NlpParser.parse('분유 120ml 먹었어');
      expect(result.confidence, greaterThan(0.7));
    });

    test('애매한 입력 → 낮은 confidence', () {
      final result = NlpParser.parse('오늘 하루 기록');
      expect(result.confidence, lessThanOrEqualTo(0.5));
    });

    test('기타로 분류된 경우 → 낮은 confidence', () {
      final result = NlpParser.parse('안녕하세요');
      expect(result.record?.category, RecordCategory.other);
      expect(result.confidence, 0.3);
    });
  });

  // ============================================================
  // 8. 엣지 케이스 테스트
  // ============================================================
  group('엣지 케이스 테스트', () {
    test('빈 입력', () {
      final result = NlpParser.parse('');
      expect(result.isSuccess, false);
    });

    test('공백만 입력', () {
      final result = NlpParser.parse('   ');
      expect(result.isSuccess, false);
    });

    test('무관한 텍스트 → 기타', () {
      final result = NlpParser.parse('오늘 날씨가 좋다');
      expect(result.record?.category, RecordCategory.other);
    });

    test('복합 문장: 수유+건강 키워드', () {
      // "분유 먹고 체온 쟀어" → 둘 다 높은 점수, 더 높은 쪽으로
      final result = NlpParser.parse('분유 먹고 체온 쟀어');
      expect(result.isSuccess, true);
      // 둘 다 가능하므로 어느 쪽이든 올바른 카테고리면 OK
      expect(
        result.record?.category == RecordCategory.feeding ||
        result.record?.category == RecordCategory.health,
        true,
      );
    });
  });

  // ============================================================
  // 9. 실제 사용자 입력 시나리오 테스트
  // ============================================================
  group('실제 사용자 입력 시나리오', () {
    final testCases = <String, RecordCategory>{
      '방금 분유 120ml 먹었어': RecordCategory.feeding,
      '오후 2시에 분유 먹음': RecordCategory.feeding,
      '모유 수유 15분': RecordCategory.feeding,
      '이유식 먹였어': RecordCategory.feeding,
      '아기 잠들었어': RecordCategory.sleep,
      '낮잠 잤어': RecordCategory.sleep,
      '아기 깼어': RecordCategory.sleep,
      '기저귀 갈았어 응가': RecordCategory.diaper,
      '기저귀 갈았어': RecordCategory.diaper,
      '응가했어': RecordCategory.diaper,
      '체온 37.5도': RecordCategory.health,
      '열이 나요': RecordCategory.health,
      '약 먹였어': RecordCategory.health,
      '병원 다녀왔어': RecordCategory.health,
      '예방접종 맞았어': RecordCategory.health,
    };

    for (final entry in testCases.entries) {
      test('"${entry.key}" → ${entry.value.name}', () {
        expectCategory(entry.key, entry.value);
      });
    }
  });

  // ============================================================
  // 10. 종합 인식율 벤치마크
  // ============================================================
  group('★ 종합 인식율 벤치마크', () {
    test('전체 테스트 케이스 인식율 측정', () {
      final benchmarkCases = <String, RecordCategory>{
        // 수유 (15개)
        '분유 먹었어': RecordCategory.feeding,
        '분유 120ml': RecordCategory.feeding,
        '분유 100cc 먹음': RecordCategory.feeding,
        '모유 수유 15분': RecordCategory.feeding,
        '모유 먹었어': RecordCategory.feeding,
        '이유식 먹였어': RecordCategory.feeding,
        '간식 먹었어': RecordCategory.feeding,
        '젖병으로 먹였어': RecordCategory.feeding,
        '우유 먹었어': RecordCategory.feeding,
        '오후 2시에 분유 120ml 먹음': RecordCategory.feeding,
        '방금 분유 먹었어': RecordCategory.feeding,
        '수유했어': RecordCategory.feeding,
        '분유 먹임': RecordCategory.feeding,
        '모유 수유': RecordCategory.feeding,
        '분유도 먹었어': RecordCategory.feeding,

        // 수면 (10개)
        '아기 잠들었어': RecordCategory.sleep,
        '낮잠 잤어': RecordCategory.sleep,
        '재웠어': RecordCategory.sleep,
        '취침했어': RecordCategory.sleep,
        '아기 깼어': RecordCategory.sleep,
        '기상했어': RecordCategory.sleep,
        '눈떴어': RecordCategory.sleep,
        '잠자요': RecordCategory.sleep,
        '수면 시작': RecordCategory.sleep,
        '아기 재움': RecordCategory.sleep,

        // 기저귀 (10개)
        '기저귀 갈았어': RecordCategory.diaper,
        '기저귀 갈았어 응가': RecordCategory.diaper,
        '응가했어': RecordCategory.diaper,
        '대변 봤어': RecordCategory.diaper,
        '소변 봤어': RecordCategory.diaper,
        '오줌 쌌어': RecordCategory.diaper,
        '기저귀 교체': RecordCategory.diaper,
        '배변했어': RecordCategory.diaper,
        '응가 대변': RecordCategory.diaper,
        '기저귀 갈아줬어': RecordCategory.diaper,

        // 건강 (10개)
        '체온 37.5도': RecordCategory.health,
        '열이 나요': RecordCategory.health,
        '약 먹였어': RecordCategory.health,
        '병원 다녀왔어': RecordCategory.health,
        '예방접종 맞았어': RecordCategory.health,
        '콧물 나요': RecordCategory.health,
        '기침 해요': RecordCategory.health,
        '감기 걸렸어': RecordCategory.health,
        '해열제 먹였어': RecordCategory.health,
        '체온 38도': RecordCategory.health,

        // 기타 / 오탐 방지 (10개) → other
        '안녕하세요': RecordCategory.other,
        '오늘 날씨가 좋다': RecordCategory.other,
        '물건을 샀어': RecordCategory.other,
        '일정 변경했어': RecordCategory.other,
        '좀 쉬어야겠다': RecordCategory.other,
        '물론이지': RecordCategory.other,
        '밥상 차리자': RecordCategory.other,
        '변화가 생겼어': RecordCategory.other,
        '오늘도 힘내자': RecordCategory.other,
        '물건이 싸다': RecordCategory.other,
      };

      int total = benchmarkCases.length;
      int correct = 0;
      final failures = <String>[];

      for (final entry in benchmarkCases.entries) {
        final result = NlpParser.parse(entry.key);
        final actual = result.record?.category;
        if (actual == entry.value) {
          correct++;
        } else {
          failures.add(
            '  ✗ "${entry.key}" → 기대: ${entry.value.name}, 실제: ${actual?.name ?? "null"} (conf: ${result.confidence})',
          );
        }
      }

      final rate = (correct / total * 100).toStringAsFixed(1);

      // 결과 출력
      print('\n');
      print('╔══════════════════════════════════════════╗');
      print('║     NLP 파서 종합 인식율 벤치마크        ║');
      print('╠══════════════════════════════════════════╣');
      print('║  총 테스트: $total개');
      print('║  정확 인식: $correct개');
      print('║  인식율:    $rate%');
      print('╚══════════════════════════════════════════╝');

      if (failures.isNotEmpty) {
        print('\n실패 케이스:');
        for (final f in failures) {
          print(f);
        }
      }

      print('\n');

      // 인식율 90% 이상 기대
      expect(correct / total, greaterThanOrEqualTo(0.9),
          reason: '인식율이 90% 미만입니다. ($rate%)');
    });
  });
}
