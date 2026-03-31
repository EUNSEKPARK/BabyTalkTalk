import 'package:flutter_test/flutter_test.dart';
import 'package:chat_baby_time/services/nlp_parser.dart';
import 'package:chat_baby_time/models/baby_record.dart';

/// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/// 아기톡톡 NLP 파서 종합 자동 테스트 (149+ 문장)
/// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
///
/// 실행: flutter test test/nlp_full_test.dart
///
/// 카테고리 판정 기준:
///   ✅ record?.category == expected  (바로 기록됨)
///   ✅ pendingRecord?.category == expected  (추가 정보 질문 중이지만 카테고리 맞음)
///   ✅ disambiguationOptions 첫 번째가 expected  (객관식이지만 올바른 방향)
///   ❌ 위 모두 불일치
///
void main() {
  // ═══════════════════════════════════════════════
  //  카테고리 매핑
  // ═══════════════════════════════════════════════
  final catMap = <String, RecordCategory>{
    'feeding': RecordCategory.feeding,
    'sleep': RecordCategory.sleep,
    'diaper': RecordCategory.diaper,
    'health': RecordCategory.health,
    'babyfood': RecordCategory.babyfood,
    'snack': RecordCategory.snack,
    'milestone': RecordCategory.milestone,
    'other': RecordCategory.other,
  };

  /// 파싱 결과에서 "향하고 있는 카테고리"를 추출
  /// 1순위: record?.category (확정 기록)
  /// 2순위: pendingRecord?.category (추가 질문 중이지만 카테고리 확정)
  /// 3순위: disambiguationOptions 첫 번째 (객관식 최우선 후보)
  RecordCategory? extractCategory(ParseResult result) {
    // 1. 확정된 record
    if (result.record?.category != null) {
      return result.record!.category;
    }
    // 2. pendingRecord (amount/stoolDetail 질문)
    if (result.pendingRecord?.category != null) {
      return result.pendingRecord!.category;
    }
    // 3. feedingType disambiguation → feeding
    if (result.needsFeedingTypeDisambiguation) {
      return RecordCategory.feeding;
    }
    // 4. medicineType disambiguation → health
    if (result.needsMedicineTypeDisambiguation) {
      return RecordCategory.health;
    }
    // 5. stoolDetail disambiguation → diaper
    if (result.needsStoolDetailInput) {
      return RecordCategory.diaper;
    }
    // 6. category disambiguation → 첫 번째 옵션
    if (result.needsDisambiguation && result.disambiguationOptions!.isNotEmpty) {
      return result.disambiguationOptions!.first.category;
    }
    return null;
  }

  /// 결과 상태 라벨
  String resultLabel(ParseResult result) {
    if (result.record != null) return '확정';
    if (result.pendingRecord != null) {
      if (result.needsAmountInput) return '양/시간 질문';
      if (result.needsStoolDetailInput) return '대변상세 질문';
      return 'pending';
    }
    if (result.needsFeedingTypeDisambiguation) return '수유타입 질문';
    if (result.needsMedicineTypeDisambiguation) return '약종류 질문';
    if (result.needsDisambiguation) return '객관식';
    return 'unknown';
  }

  // ═══════════════════════════════════════════════
  //  전체 테스트 데이터 (input|expectedCategory)
  // ═══════════════════════════════════════════════
  final testCases = <Map<String, String>>[
    // ━━━ 수유 (feeding) ━━━
    {'input': '분유 120ml 먹었어', 'expected': 'feeding'},
    {'input': '분유 80 먹음', 'expected': 'feeding'},
    {'input': '모유 수유했어', 'expected': 'feeding'},
    {'input': '모유 15분 먹었어', 'expected': 'feeding'},
    {'input': '젖병으로 100cc 줬어', 'expected': 'feeding'},
    {'input': '직수 20분 했어', 'expected': 'feeding'},
    {'input': '완분 160ml', 'expected': 'feeding'},
    {'input': '유축 120ml 먹였어', 'expected': 'feeding'},
    {'input': '반병 먹었어', 'expected': 'feeding'},
    {'input': '한병 다 먹었음', 'expected': 'feeding'},
    {'input': '분유 100밀리리터', 'expected': 'feeding'},
    {'input': '아기 젖 물렸어', 'expected': 'feeding'},
    {'input': '새벽에 분유 80ml 줬어', 'expected': 'feeding'},
    {'input': '수유 완료', 'expected': 'feeding'},
    {'input': '혼합수유 했어', 'expected': 'feeding'},
    {'input': '분유 먹다 잠들었어', 'expected': 'feeding'},

    // ━━━ 수면 (sleep) ━━━
    {'input': '아기 잠들었어', 'expected': 'sleep'},
    {'input': '낮잠 잤어', 'expected': 'sleep'},
    {'input': '밤잠 들었어', 'expected': 'sleep'},
    {'input': '깼어', 'expected': 'sleep'},
    {'input': '아기 깨어났어', 'expected': 'sleep'},
    {'input': '일어났어', 'expected': 'sleep'},
    {'input': '1시간 잤어', 'expected': 'sleep'},
    {'input': '30분 낮잠', 'expected': 'sleep'},
    {'input': '꿀잠 자는 중', 'expected': 'sleep'},
    {'input': '잠투정 시작', 'expected': 'sleep'},
    {'input': '재웠어', 'expected': 'sleep'},
    {'input': '눈 떴어', 'expected': 'sleep'},
    {'input': '쪽잠 잤어', 'expected': 'sleep'},
    {'input': '토닥토닥 재웠어', 'expected': 'sleep'},
    {'input': '자다가 깼어', 'expected': 'sleep'},
    {'input': '선잠만 잤어', 'expected': 'sleep'},
    {'input': '기상했어', 'expected': 'sleep'},
    {'input': '잠들었다 금방 깼어', 'expected': 'sleep'},
    // v5 추가: "자서/자고" 활용형
    {'input': '1시에 자서 이제 일어났어', 'expected': 'sleep'},
    {'input': '자고 일어났어', 'expected': 'sleep'},
    {'input': '잤는데 깼어', 'expected': 'sleep'},
    {'input': '2시에 자서 방금 깼어', 'expected': 'sleep'},

    // ━━━ 기저귀 (diaper) ━━━
    {'input': '기저귀 갈았어', 'expected': 'diaper'},
    {'input': '응가했어', 'expected': 'diaper'},
    {'input': '대변 봤어', 'expected': 'diaper'},
    {'input': '소변만 봤어', 'expected': 'diaper'},
    {'input': '똥 쌌어', 'expected': 'diaper'},
    {'input': '기저귀 교체', 'expected': 'diaper'},
    {'input': '묽은 변 봤어', 'expected': 'diaper'},
    {'input': '노란 변이야', 'expected': 'diaper'},
    {'input': '물변 나왔어', 'expected': 'diaper'},
    {'input': '소변이랑 대변 같이', 'expected': 'diaper'},
    {'input': '기저귀 갈아줬어', 'expected': 'diaper'},
    {'input': '오줌 쌌어', 'expected': 'diaper'},
    {'input': '쉬했어', 'expected': 'diaper'},

    // ━━━ 건강 (health) ━━━
    {'input': '체온 37.5도', 'expected': 'health'},
    {'input': '열 38도야', 'expected': 'health'},
    {'input': '해열제 먹였어', 'expected': 'health'},
    {'input': '감기약 줬어', 'expected': 'health'},
    {'input': '타이레놀 먹였어', 'expected': 'health'},
    {'input': '기침약 복용', 'expected': 'health'},
    {'input': '항생제 먹였어', 'expected': 'health'},
    {'input': '유산균 줬어', 'expected': 'health'},
    {'input': '병원 갔다왔어', 'expected': 'health'},
    {'input': '예방접종 했어', 'expected': 'health'},
    {'input': '콧물 나와', 'expected': 'health'},
    {'input': '기침 심해', 'expected': 'health'},
    {'input': '구토했어', 'expected': 'health'},
    {'input': '설사했어', 'expected': 'health'},
    {'input': '발진 생겼어', 'expected': 'health'},
    {'input': '두드러기 났어', 'expected': 'health'},
    {'input': '열이 안 내려가', 'expected': 'health'},
    {'input': '약 먹었어', 'expected': 'health'},
    {'input': '투약 완료', 'expected': 'health'},
    {'input': '비타민 줬어', 'expected': 'health'},

    // ━━━ 이유식 (babyfood) ━━━
    {'input': '이유식 먹었어', 'expected': 'babyfood'},
    {'input': '소고기죽 줬어', 'expected': 'babyfood'},
    {'input': '당근 호박 죽', 'expected': 'babyfood'},
    {'input': '이유식 100ml', 'expected': 'babyfood'},
    {'input': '감자 퓨레 먹였어', 'expected': 'babyfood'},
    {'input': '고구마 으깬 거 줬어', 'expected': 'babyfood'},
    {'input': '닭고기 미음', 'expected': 'babyfood'},
    {'input': '브로콜리 이유식', 'expected': 'babyfood'},
    {'input': '시금치죽 먹음', 'expected': 'babyfood'},
    {'input': '오트밀 죽 줬어', 'expected': 'babyfood'},
    {'input': '이유식 3숟가락', 'expected': 'babyfood'},
    {'input': '계란 노른자 줬어', 'expected': 'babyfood'},

    // ━━━ 간식 (snack) ━━━
    {'input': '딸기 먹었어', 'expected': 'snack'},
    {'input': '바나나 반개 줬어', 'expected': 'snack'},
    {'input': '뻥튀기 줬어', 'expected': 'snack'},
    {'input': '떡뻥 먹음', 'expected': 'snack'},
    {'input': '요거트 먹었어', 'expected': 'snack'},
    {'input': '사과 갈아서 줬어', 'expected': 'snack'},
    {'input': '블루베리 조금 줬어', 'expected': 'snack'},
    {'input': '간식 먹었어', 'expected': 'snack'},
    {'input': '쌀과자 줬어', 'expected': 'snack'},
    {'input': '포도 먹음', 'expected': 'snack'},
    {'input': '과일 줬어', 'expected': 'snack'},
    {'input': '귤 한쪽 먹었어', 'expected': 'snack'},
    {'input': '수박 줬어', 'expected': 'snack'},
    {'input': '키위 먹였어', 'expected': 'snack'},

    // ━━━ 기타 (other) ━━━
    {'input': '외출', 'expected': 'other'},
    {'input': '외출했어', 'expected': 'other'},
    {'input': '산책 갔어', 'expected': 'other'},
    {'input': '목욕했어', 'expected': 'other'},
    {'input': '목욕 시켰어', 'expected': 'other'},
    {'input': '씻겼어', 'expected': 'other'},
    {'input': '산책 다녀왔어', 'expected': 'other'},

    // ━━━ 성장 (milestone) ━━━
    {'input': '뒤집기 했어', 'expected': 'milestone'},
    {'input': '걸음마 시작했어', 'expected': 'milestone'},
    {'input': '옹알이 했어', 'expected': 'milestone'},
    {'input': '혼자 앉았어', 'expected': 'milestone'},
    {'input': '처음 웃었어', 'expected': 'milestone'},
    {'input': '이가 나왔어', 'expected': 'milestone'},
    {'input': '엄마라고 했어', 'expected': 'milestone'},
    {'input': '손뼉 쳤어', 'expected': 'milestone'},

    // ━━━ 시간 표현 포함 ━━━
    {'input': '30분 전에 분유 100ml 먹었어', 'expected': 'feeding'},
    {'input': '아까 모유 수유했어', 'expected': 'feeding'},
    {'input': '3시에 이유식 먹었어', 'expected': 'babyfood'},
    {'input': '2시간 전에 잠들었어', 'expected': 'sleep'},
    {'input': '1시에 깼어', 'expected': 'sleep'},
    {'input': '10분 전 기저귀 갈았어', 'expected': 'diaper'},

    // ━━━ 복합/경계 케이스 ━━━
    {'input': '분유 먹고 잠들었어', 'expected': 'feeding'},
    {'input': '이유식 먹고 응가했어', 'expected': 'babyfood'},
    {'input': '목욕하고 잠들었어', 'expected': 'other'},
    {'input': '분유 먹다 토했어', 'expected': 'health'},

    // ━━━ 기타 (확실한 기타) ━━━
    {'input': '아기 배고파', 'expected': 'other'},
    {'input': '오늘 날씨 좋다', 'expected': 'other'},
    {'input': '남편 퇴근', 'expected': 'other'},
    {'input': '드라마 재밌다', 'expected': 'other'},
    {'input': '소아과 예약해야 하나', 'expected': 'other'},
    {'input': '아기 잘 크고 있나', 'expected': 'other'},
    {'input': '분유 얼마나 먹어야 해', 'expected': 'other'},

    // ━━━ 오타/구어체 ━━━
    {'input': '분유 120ml 먹엇어', 'expected': 'feeding'},
    {'input': '잣어', 'expected': 'sleep'},
    {'input': '기저기 갈았어', 'expected': 'diaper'},
    {'input': '잠들엇어', 'expected': 'sleep'},
    {'input': '깨엇어', 'expected': 'sleep'},
    {'input': '일어낫어', 'expected': 'sleep'},
    {'input': '모곡했어', 'expected': 'other'},
    {'input': '기져귀 교체', 'expected': 'diaper'},
    {'input': '이유식 먹엇어', 'expected': 'babyfood'},

    // ━━━ 모호한 단어 단독 ━━━
    // 이 섹션은 매우 짧은 입력으로, disambiguation(객관식)이 뜨는 것도 정상
    {'input': '아기 자요', 'expected': 'sleep'},
    {'input': '밥 120', 'expected': 'feeding'},     // 객관식(분유vs이유식) → feeding 첫 번째 옵션
    {'input': '밥 먹었어', 'expected': 'babyfood'},
    {'input': '잤어', 'expected': 'sleep'},
    {'input': '갈았어', 'expected': 'diaper'},
    {'input': '약', 'expected': 'health'},          // '약':2.0 → health threshold 도달
    {'input': '아기', 'expected': 'other'},
    {'input': '100ml', 'expected': 'feeding'},
    {'input': '분유', 'expected': 'feeding'},
    {'input': '잠', 'expected': 'sleep'},           // v6: 현재 시각 기준 낮잠/밤잠 자동
    // 아래는 너무 모호해서 other/객관식이 정상인 케이스
    // {'input': '먹었어', 'expected': '?'},  // feeding/babyfood 어느쪽이든 1.0 → threshold 미달

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // v7: 실사용 패턴 대폭 추가 (60+)
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    // ━━━ 초성 약어 / 줄임말 ━━━
    {'input': 'ㅂㄴ 120', 'expected': 'feeding'},        // 분유 120
    {'input': 'ㅁㅇ 15분', 'expected': 'feeding'},       // 모유 15분

    // ━━━ 감정 섞인 장문 ━━━
    {'input': '아 진짜 분유 120ml 겨우 먹였어', 'expected': 'feeding'},
    {'input': '이유식 3숟가락밖에 안 먹음ㅠㅠ', 'expected': 'babyfood'},
    {'input': '드디어 잠들었어 1시간째 재운 끝에', 'expected': 'sleep'},
    {'input': '또 깼어ㅠㅠㅠ 10분만에', 'expected': 'sleep'},
    {'input': '응가 폭발했어ㅋㅋ 기저귀 갈아줬어', 'expected': 'diaper'},
    {'input': '열이 37.8도야 병원 가야하나', 'expected': 'health'},

    // ━━━ 비정형 양 표현 ━━━
    {'input': '분유 반쯤 먹었어', 'expected': 'feeding'},
    {'input': '분유 조금만 먹음', 'expected': 'feeding'},
    {'input': '모유 수유 거의 다 먹었어', 'expected': 'feeding'},

    // ━━━ 숫자만/숫자+동사 ━━━
    {'input': '120 먹었어', 'expected': 'feeding'},
    {'input': '80 줬어', 'expected': 'feeding'},

    // ━━━ 이모지/특수문자 포함 ━━━
    {'input': '분유 100ml 먹었어 👶', 'expected': 'feeding'},
    {'input': '잠들었어 😴', 'expected': 'sleep'},
    {'input': '응가!!! 💩', 'expected': 'diaper'},

    // ━━━ 오탐 방지 (짧은 키워드 false positive) ━━━
    {'input': '무서워했어', 'expected': 'other'},          // "무" → babyfood 오탐 방지
    {'input': '약속 잡았어', 'expected': 'other'},          // "약" → health 오탐 방지
    {'input': '쉬는 날이야', 'expected': 'other'},          // "쉬" → diaper 오탐 방지
    {'input': '예약 취소했어', 'expected': 'other'},         // "예약" → intent/other
    {'input': '열심히 놀았어', 'expected': 'other'},         // "열" → health 오탐 방지
    {'input': '젖었어 옷이', 'expected': 'other'},          // "젖" → feeding 오탐 방지

    // ━━━ 잡담/감정/인사 필터 ━━━
    {'input': '안녕하세요', 'expected': 'other'},
    {'input': '오늘 아기가 너무 귀엽다', 'expected': 'other'},
    {'input': '이유식 만들어야지', 'expected': 'other'},     // 의도 표현
    {'input': '분유 사와야 해', 'expected': 'other'},        // 의도 표현
    {'input': '어떡해 안 먹어', 'expected': 'other'},        // 걱정 표현
    {'input': '왜 이렇게 안 자지', 'expected': 'other'},      // 걱정 질문

    // ━━━ 복합 문장 (핵심 행위 추출) ━━━
    {'input': '놀다가 분유 100ml 먹었어', 'expected': 'feeding'},
    {'input': '울다가 겨우 잠들었어', 'expected': 'sleep'},
    {'input': '이유식 먹다 토했어', 'expected': 'health'},   // 토함 = 건강

    // ━━━ 다양한 시간 표현 ━━━
    {'input': '새벽 3시에 깼어', 'expected': 'sleep'},
    {'input': '점심때 이유식 먹었어', 'expected': 'babyfood'},
    {'input': '방금 기저귀 갈았어', 'expected': 'diaper'},

    // ━━━ 기존 빈틈 보강 ━━━
    {'input': '수유했어', 'expected': 'feeding'},
    {'input': '직수했어', 'expected': 'feeding'},
    {'input': '유축 120ml', 'expected': 'feeding'},
    {'input': '낮잠 시작', 'expected': 'sleep'},
    {'input': '밤잠 10시에 들었어', 'expected': 'sleep'},
    {'input': '대변 봤어 묽은 변', 'expected': 'diaper'},
    {'input': '소변 많이 봤어', 'expected': 'diaper'},
    {'input': '감기 걸린 것 같아', 'expected': 'health'},
    {'input': '뒤집기 성공', 'expected': 'milestone'},
    {'input': '첫 걸음마 했어', 'expected': 'milestone'},
    {'input': '목욕하고 로션 발랐어', 'expected': 'other'},
    {'input': '공원 산책 30분 했어', 'expected': 'other'},

    // ━━━ 혼합수유 표현 ━━━
    {'input': '완분이야', 'expected': 'feeding'},
    {'input': '혼합수유 중', 'expected': 'feeding'},
  ];

  // ═══════════════════════════════════════════════
  //  카테고리별 그룹 테스트
  // ═══════════════════════════════════════════════

  final grouped = <String, List<Map<String, String>>>{};
  for (final tc in testCases) {
    grouped.putIfAbsent(tc['expected']!, () => []).add(tc);
  }

  final catNames = {
    'feeding': '🍼 수유',
    'sleep': '😴 수면',
    'diaper': '🧷 기저귀',
    'health': '🏥 건강',
    'babyfood': '🥣 이유식',
    'snack': '🍎 간식',
    'other': '📝 기타',
    'milestone': '⭐ 성장',
  };

  for (final cat in grouped.keys) {
    group('${catNames[cat] ?? cat} 테스트 (${grouped[cat]!.length}개)', () {
      for (final tc in grouped[cat]!) {
        test('"${tc['input']}" → $cat', () {
          final result = NlpParser.parse(tc['input']!);
          final expected = catMap[tc['expected']!];
          final actual = extractCategory(result);
          final label = resultLabel(result);

          expect(
            actual,
            expected,
            reason: '❌ "${tc['input']}" → 기대: ${tc['expected']}, '
                '실제: ${actual?.name ?? "null"} '
                '[$label] '
                '(${(result.confidence * 100).round()}%)',
          );
        });
      }
    });
  }

  // ═══════════════════════════════════════════════
  //  전체 요약 통계 테스트
  // ═══════════════════════════════════════════════
  test('📊 전체 정확도 요약', () {
    var total = 0;
    var passed = 0;
    final failures = <String>[];
    final allResults = <String>[];
    final catStats = <String, List<int>>{}; // {cat: [passed, total]}

    final catEmoji = {
      'feeding': '🍼', 'sleep': '😴', 'diaper': '🧷',
      'health': '🏥', 'babyfood': '🥣', 'snack': '🍎',
      'other': '📝', 'milestone': '⭐',
    };

    for (final tc in testCases) {
      total++;
      final expected = catMap[tc['expected']!];
      final result = NlpParser.parse(tc['input']!);
      final actual = extractCategory(result);
      final label = resultLabel(result);
      final ok = actual == expected;
      final emoji = catEmoji[actual?.name] ?? '❓';
      final confPct = result.confidence > 0
          ? '${(result.confidence * 100).round()}%'
          : (result.pendingRecord != null ? '확정' : '0%');

      catStats.putIfAbsent(tc['expected']!, () => [0, 0]);
      catStats[tc['expected']!]![1]++;

      if (ok) {
        passed++;
        catStats[tc['expected']!]![0]++;
      } else {
        failures.add(
          '  ❌ "${tc['input']}" → 기대: ${tc['expected']}, '
          '실제: ${actual?.name ?? "null"} '
          '[$label] ($confPct)',
        );
      }

      // 전체 결과 테이블 행
      final mark = ok ? '✅' : '❌';
      final msg = result.message;
      allResults.add(
        '  $mark  ${tc['input'].toString().padRight(28)} │ $emoji $msg [$label] ($confPct)',
      );
    }

    final pct = (passed / total * 100).toStringAsFixed(1);
    print('\n');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('  📊 NLP 파서 테스트 결과 요약');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('  전체: $passed/$total ($pct%)');
    print('');
    for (final cat in catStats.keys) {
      final p = catStats[cat]![0];
      final t = catStats[cat]![1];
      final cpct = (p / t * 100).round();
      final eName = catNames[cat] ?? cat;
      final bar = '█' * (cpct ~/ 5) + '░' * (20 - cpct ~/ 5);
      print('  $eName: $p/$t ($cpct%) $bar');
    }

    // 전체 결과 테이블 (입력창 | 기록 내용)
    print('');
    print('  ── 전체 결과 (입력창 │ 기록 내용) ──');
    print('  ${"─" * 80}');
    for (final row in allResults) {
      print(row);
    }
    print('  ${"─" * 80}');

    if (failures.isNotEmpty) {
      print('');
      print('  ── 실패 목록 (${failures.length}개) ──');
      for (final f in failures) {
        print(f);
      }
      print('');
      print('  💡 위 실패 목록을 Claude에게 붙여넣기 하세요!');
    } else {
      print('');
      print('  🎉 모든 테스트 통과!');
    }
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('');

    if (failures.isNotEmpty) {
      print('⚠️  ${failures.length}개 실패 — 개별 테스트에서 확인하세요');
    }
  });
}
