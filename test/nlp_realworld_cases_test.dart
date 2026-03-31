import 'package:flutter_test/flutter_test.dart';
import 'package:chat_baby_time/services/nlp_parser.dart';
import 'package:chat_baby_time/models/baby_record.dart';

/// 실제 사용자 입력 패턴 기반 NLP 파서 테스트
///
/// 목표: 실사용 시나리오에서 파서가 정확히 동작하는지 검증
/// 실행: flutter test test/nlp_realworld_cases_test.dart
void main() {
  // ── 헬퍼 ──
  /// 카테고리가 정확히 맞는지 확인
  void ok(String input, RecordCategory expected, {String? desc}) {
    final r = NlpParser.parse(input);
    expect(
      r.record?.category, expected,
      reason: '"$input" → 기대: ${expected.name}, '
          '실제: ${r.record?.category?.name ?? "null(isSuccess=${r.isSuccess})"} '
          '(conf: ${r.confidence}, msg: ${r.message})',
    );
  }

  /// 해당 카테고리가 아닌지 확인 (오분류 방지)
  void notCat(String input, RecordCategory wrong, {String? desc}) {
    final r = NlpParser.parse(input);
    expect(
      r.record?.category, isNot(wrong),
      reason: '"$input" → ${wrong.name}으로 오분류됨 (conf: ${r.confidence})',
    );
  }

  /// isSuccess == true 인지 확인
  void isOk(String input) {
    final r = NlpParser.parse(input);
    expect(
      r.isSuccess, true,
      reason: '"$input" → isSuccess=false (msg: ${r.message})',
    );
  }

  // ================================================================
  //  1. 수유 (feeding) — 분유
  // ================================================================
  group('분유 입력 패턴', () {
    test('기본 표현', () {
      ok('분유 먹었어', RecordCategory.feeding);
      ok('분유 먹임', RecordCategory.feeding);
      ok('분유 줬어', RecordCategory.feeding);
      ok('분유 먹였어', RecordCategory.feeding);
    });

    test('양 + 단위 포함', () {
      ok('분유 120ml', RecordCategory.feeding);
      ok('분유 100cc 먹었어', RecordCategory.feeding);
      ok('분유 160밀리', RecordCategory.feeding);
      ok('분유 80씨씨', RecordCategory.feeding);
    });

    test('양만 (단위 없음)', () {
      ok('분유 100', RecordCategory.feeding);
      ok('분유 120 먹었어', RecordCategory.feeding);
      ok('분유 80 줬어', RecordCategory.feeding);
    });

    test('시간 포함', () {
      ok('2시에 분유 120ml', RecordCategory.feeding);
      ok('방금 분유 먹었어', RecordCategory.feeding);
      ok('아까 분유 100 줬어', RecordCategory.feeding);
      ok('30분 전에 분유 먹었어', RecordCategory.feeding);
    });

    test('구어체/줄임말', () {
      ok('분유 먹음', RecordCategory.feeding);
      ok('분유 완료', RecordCategory.feeding);
      ok('분유 줌', RecordCategory.feeding);
    });

    test('반병/한병 표현', () {
      ok('분유 반병 먹었어', RecordCategory.feeding);
      ok('한병 다 먹었어', RecordCategory.feeding);
    });
  });

  // ================================================================
  //  2. 수유 (feeding) — 모유
  // ================================================================
  group('모유 입력 패턴', () {
    test('기본 표현', () {
      ok('모유 수유', RecordCategory.feeding);
      ok('모유 먹었어', RecordCategory.feeding);
      ok('모유 먹였어', RecordCategory.feeding);
    });

    test('직수/유축', () {
      ok('직수했어', RecordCategory.feeding);
      ok('직수 15분', RecordCategory.feeding);
      ok('유축 80ml', RecordCategory.feeding);
      ok('유축했어', RecordCategory.feeding);
    });

    test('시간(분) 포함', () {
      ok('모유 10분', RecordCategory.feeding);
      ok('모유 수유 20분', RecordCategory.feeding);
      ok('젖 15분 먹었어', RecordCategory.feeding);
    });

    test('구어체', () {
      ok('젖 먹었어', RecordCategory.feeding);
      ok('젖 물렸어', RecordCategory.feeding);
      ok('젖 줬어', RecordCategory.feeding);
    });
  });

  // ================================================================
  //  3. 수유 일반
  // ================================================================
  group('수유 일반 표현', () {
    test('수유 키워드', () {
      ok('수유했어', RecordCategory.feeding);
      ok('젖병 먹였어', RecordCategory.feeding);
    });

    test('오분류 방지 — 약/건강과 구분', () {
      notCat('약 먹였어', RecordCategory.feeding);
      notCat('해열제 먹였어', RecordCategory.feeding);
    });
  });

  // ================================================================
  //  4. 이유식 (babyfood)
  // ================================================================
  group('이유식 입력 패턴', () {
    test('기본 표현', () {
      ok('이유식 먹었어', RecordCategory.babyfood);
      ok('이유식 줬어', RecordCategory.babyfood);
      ok('죽 먹였어', RecordCategory.babyfood);
      ok('미음 줬어', RecordCategory.babyfood);
    });

    test('재료 포함', () {
      ok('소고기 이유식 먹었어', RecordCategory.babyfood);
      ok('당근 죽 줬어', RecordCategory.babyfood);
      ok('감자 퓨레 먹였어', RecordCategory.babyfood);
      ok('브로콜리 이유식', RecordCategory.babyfood);
    });

    test('재료만 언급 (이유식 키워드 없음)', () {
      ok('계란 먹었어', RecordCategory.babyfood);
      ok('고구마 먹였어', RecordCategory.babyfood);
      ok('소고기 줬어', RecordCategory.babyfood);
      ok('두부 먹었어', RecordCategory.babyfood);
      ok('연어 먹였어', RecordCategory.babyfood);
    });

    test('양 포함', () {
      // "이유식 100ml"은 feeding(분유ml)과 babyfood가 경합 → 객관식 표시될 수 있음
      isOk('이유식 50g 먹었어');
      ok('죽 반그릇 먹었어', RecordCategory.babyfood);
    });

    test('구어체', () {
      ok('이유식 완료', RecordCategory.babyfood);
      ok('죽 다 먹음', RecordCategory.babyfood);
    });
  });

  // ================================================================
  //  5. 간식 (snack)
  // ================================================================
  group('간식 입력 패턴', () {
    test('기본 표현', () {
      ok('간식 먹었어', RecordCategory.snack);
      ok('간식 줬어', RecordCategory.snack);
    });

    test('구체적 간식', () {
      ok('뻥튀기 먹었어', RecordCategory.snack);
      ok('떡뻥 줬어', RecordCategory.snack);
      ok('과일 먹었어', RecordCategory.snack);
      ok('사과 줬어', RecordCategory.snack);
      ok('바나나 먹었어', RecordCategory.snack);
      ok('딸기 먹였어', RecordCategory.snack);
    });
  });

  // ================================================================
  //  6. 수면 (sleep)
  // ================================================================
  group('수면 입력 패턴', () {
    test('잠들기', () {
      ok('잠들었어', RecordCategory.sleep);
      ok('잠잤어', RecordCategory.sleep);
      ok('낮잠 잤어', RecordCategory.sleep);
      ok('밤잠 잤어', RecordCategory.sleep);
      ok('아기 잤어', RecordCategory.sleep);
    });

    test('깨기', () {
      ok('깼어', RecordCategory.sleep);
      ok('아기 깼어', RecordCategory.sleep);
      ok('일어났어', RecordCategory.sleep);
      ok('눈떴어', RecordCategory.sleep);
      ok('기상', RecordCategory.sleep);
    });

    test('재우기', () {
      ok('재웠어', RecordCategory.sleep);
      ok('재움', RecordCategory.sleep);
      ok('토닥토닥 재웠어', RecordCategory.sleep);
    });

    test('시간 포함', () {
      ok('2시에 잠들었어', RecordCategory.sleep);
      ok('30분 전에 잤어', RecordCategory.sleep);
      ok('낮잠 1시간 잤어', RecordCategory.sleep);
    });

    test('구어체/줄임말', () {
      ok('잠듬', RecordCategory.sleep);
      ok('잤음', RecordCategory.sleep);
      ok('취침', RecordCategory.sleep);
      ok('꿀잠 중', RecordCategory.sleep);
    });

    test('오분류 방지', () {
      notCat('좀 쉬어야겠다', RecordCategory.sleep);
      notCat('나 졸려', RecordCategory.sleep);
    });
  });

  // ================================================================
  //  7. 기저귀 (diaper)
  // ================================================================
  group('기저귀 입력 패턴', () {
    test('소변', () {
      ok('기저귀 갈았어', RecordCategory.diaper);
      ok('기저귀 교체', RecordCategory.diaper);
      ok('오줌 쌌어', RecordCategory.diaper);
      // '쉬했어'는 기저귀 약칭 → 객관식 제공 (isSuccess=false)
      ok('소변 봤어', RecordCategory.diaper);
    });

    test('대변', () {
      ok('응가 했어', RecordCategory.diaper);
      ok('똥 쌌어', RecordCategory.diaper);
      ok('대변 봤어', RecordCategory.diaper);
    });

    test('상태 표현', () {
      ok('묽은 변 봤어', RecordCategory.diaper);  // TODO: 키워드 보강 필요
      ok('노란 변이야', RecordCategory.diaper);
      ok('녹색 변 봤어', RecordCategory.diaper);
    });

    test('시간 포함', () {
      ok('방금 기저귀 갈았어', RecordCategory.diaper);
      ok('10분 전에 응가 했어', RecordCategory.diaper);
    });

    test('구어체', () {
      ok('기저귀 갈음', RecordCategory.diaper);
      ok('응가함', RecordCategory.diaper);
    });
  });

  // ================================================================
  //  8. 건강 (health)
  // ================================================================
  group('건강 입력 패턴', () {
    test('체온', () {
      ok('체온 37.5도', RecordCategory.health);
      ok('열 38도', RecordCategory.health);
      ok('체온 36.8', RecordCategory.health);
    });

    test('약 투여', () {
      ok('약 먹였어', RecordCategory.health);
      ok('해열제 먹였어', RecordCategory.health);
      ok('타이레놀 줬어', RecordCategory.health);
      ok('시럽 먹였어', RecordCategory.health);
    });

    test('예방접종', () {
      ok('예방접종 맞았어', RecordCategory.health);
      ok('접종 완료', RecordCategory.health);
    });

    test('증상', () {
      ok('콧물 나와', RecordCategory.health);
      ok('기침해', RecordCategory.health);
      ok('구토했어', RecordCategory.health);
      // '설사했어'는 건강/기저귀 경합 → 객관식 표시될 수 있음
      ok('열 나', RecordCategory.health);
    });
  });

  // ================================================================
  //  9. 기타/잡담 (other) — 기록 아닌 것
  // ================================================================
  group('기타/잡담 필터링', () {
    test('의도/계획', () {
      ok('분유 사와야 해', RecordCategory.other);
      ok('이유식 만들어야지', RecordCategory.other);
    });

    test('본인 언급', () {
      ok('나 밥 먹었어', RecordCategory.other);
      ok('남편 약 먹었어', RecordCategory.other);
    });

    test('감정/일상', () {
      ok('아기가 너무 예쁘다', RecordCategory.other);
      ok('감사합니다', RecordCategory.other);
    });

    test('질문', () {
      ok('오늘 몇 번 먹었어?', RecordCategory.other);
      ok('수면 패턴 보여줘', RecordCategory.other);
    });
  });

  // ================================================================
  // 10. 음성 입력 스타일 (자연스러운 구어체)
  // ================================================================
  group('음성 입력 스타일', () {
    test('자연스러운 문장', () {
      isOk('아기가 방금 분유 백이십 먹었어');
      isOk('지금 잠들었어');
      isOk('기저귀 갈았는데 응가였어');
      isOk('이유식 소고기 죽 먹였어');
    });

    test('짧은 단답', () {
      isOk('분유');
      isOk('잤어');
      isOk('응가');
      isOk('깼어');
      isOk('분유 100');
    });
  });

  // ================================================================
  // 11. isSuccess 확인 — 주요 입력이 실패하지 않는지
  // ================================================================
  group('주요 입력 isSuccess 확인', () {
    test('수유 관련 — 모두 isSuccess=true', () {
      isOk('분유 100ml');
      isOk('분유 먹었어');
      isOk('분유 100');
      isOk('모유 수유');
      isOk('모유 10분');
      isOk('직수했어');
      isOk('유축 80ml');
    });

    test('이유식 관련', () {
      isOk('이유식 먹었어');
      isOk('계란 먹었어');
      isOk('소고기 죽');
      isOk('고구마 먹였어');
      isOk('당근 퓨레');
    });

    test('수면 관련', () {
      isOk('잠들었어');
      isOk('깼어');
      isOk('낮잠 잤어');
      isOk('재웠어');
    });

    test('기저귀 관련', () {
      isOk('기저귀 갈았어');
      isOk('응가 했어');
      isOk('오줌 쌌어');
    });

    test('건강 관련', () {
      isOk('체온 37.5도');
      isOk('약 먹였어');
      isOk('콧물 나와');
    });
  });

  // ================================================================
  // 12. 종합 인식률 벤치마크
  // ================================================================
  group('종합 인식률', () {
    test('전체 케이스 통과율 85% 이상', () {
      final cases = <MapEntry<String, RecordCategory>>[
        // 수유
        MapEntry('분유 100ml', RecordCategory.feeding),
        MapEntry('분유 먹었어', RecordCategory.feeding),
        MapEntry('분유 100', RecordCategory.feeding),
        MapEntry('분유 줬어', RecordCategory.feeding),
        MapEntry('모유 수유', RecordCategory.feeding),
        MapEntry('모유 10분', RecordCategory.feeding),
        MapEntry('직수했어', RecordCategory.feeding),
        MapEntry('유축 80ml', RecordCategory.feeding),
        MapEntry('젖 먹었어', RecordCategory.feeding),
        MapEntry('젖병 먹였어', RecordCategory.feeding),
        MapEntry('수유했어', RecordCategory.feeding),
        MapEntry('분유 반병', RecordCategory.feeding),
        // 이유식
        MapEntry('이유식 먹었어', RecordCategory.babyfood),
        MapEntry('죽 먹였어', RecordCategory.babyfood),
        MapEntry('소고기 이유식', RecordCategory.babyfood),
        MapEntry('계란 먹었어', RecordCategory.babyfood),
        MapEntry('고구마 먹였어', RecordCategory.babyfood),
        MapEntry('당근 죽', RecordCategory.babyfood),
        MapEntry('두부 먹었어', RecordCategory.babyfood),
        // 간식
        MapEntry('간식 먹었어', RecordCategory.snack),
        MapEntry('뻥튀기 먹었어', RecordCategory.snack),
        MapEntry('바나나 먹었어', RecordCategory.snack),
        // 수면
        MapEntry('잠들었어', RecordCategory.sleep),
        MapEntry('깼어', RecordCategory.sleep),
        MapEntry('낮잠 잤어', RecordCategory.sleep),
        MapEntry('재웠어', RecordCategory.sleep),
        MapEntry('기상', RecordCategory.sleep),
        MapEntry('잤어', RecordCategory.sleep),
        // 기저귀
        MapEntry('기저귀 갈았어', RecordCategory.diaper),
        MapEntry('응가 했어', RecordCategory.diaper),
        MapEntry('오줌 쌌어', RecordCategory.diaper),
        MapEntry('똥 쌌어', RecordCategory.diaper),
        // 건강
        MapEntry('체온 37.5도', RecordCategory.health),
        MapEntry('약 먹였어', RecordCategory.health),
        MapEntry('해열제 먹였어', RecordCategory.health),
        MapEntry('콧물 나와', RecordCategory.health),
        MapEntry('기침해', RecordCategory.health),
        // 기타
        MapEntry('아기가 너무 예쁘다', RecordCategory.other),
        MapEntry('나 밥 먹었어', RecordCategory.other),
        MapEntry('감사합니다', RecordCategory.other),
      ];

      int pass = 0;
      final failures = <String>[];

      for (final c in cases) {
        final r = NlpParser.parse(c.key);
        if (r.record?.category == c.value) {
          pass++;
        } else {
          failures.add(
            '  ✗ "${c.key}" → 기대: ${c.value.name}, '
            '실제: ${r.record?.category?.name ?? "null(isSuccess=${r.isSuccess})"} '
            '(conf: ${r.confidence})',
          );
        }
      }

      final rate = pass / cases.length;
      print('\n╔══════════════════════════════════════════╗');
      print('║  종합 인식률: ${(rate * 100).toStringAsFixed(1)}% ($pass/${cases.length})');
      print('╚══════════════════════════════════════════╝');
      if (failures.isNotEmpty) {
        print('\n실패 케이스:');
        for (final f in failures) {
          print(f);
        }
      }

      expect(rate, greaterThanOrEqualTo(0.85),
          reason: '인식률이 85% 미만입니다. (${(rate * 100).toStringAsFixed(1)}%)');
    });
  });
}
