/// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/// 🏭 대량 테스트 생성 엔진 (100 페르소나 × 10,000+ 문장)
/// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
///
/// persona_definitions.dart + sentence_templates.dart를 조합하여
/// 페르소나 속성에 맞는 현실적인 입력 문장을 생성합니다.
///
/// 생성 로직:
///   1. 각 페르소나마다 해당 월령/수유타입에 맞는 카테고리 가중치 적용
///   2. 카테고리별 표현 풀에서 문장 선택
///   3. 슬롯 변수({amt}, {dur}, {temp}, {n}) 치환
///   4. 페르소나 속성 기반 변형 적용 (시간 접두사, 감정, 이모지, 존댓말, 오타)
///   5. other(비기록) 문장도 적절 비율로 혼합

import 'dart:math';
import 'persona_definitions.dart';
import 'sentence_templates.dart';

/// 생성된 테스트 케이스를 담는 클래스
class GeneratedTestCase {
  final String input;
  final String expectedCategory;
  final String personaId;
  final String personaName;

  const GeneratedTestCase({
    required this.input,
    required this.expectedCategory,
    required this.personaId,
    required this.personaName,
  });
}

/// ─── 카테고리별 표현 풀 매핑 ───
const _categoryExpressions = <String, List<String>>{
  'feeding': feedingExpressions,
  'sleep': sleepExpressions,
  'diaper': diaperExpressions,
  'health': healthExpressions,
  'babyfood': babyfoodExpressions,
  'snack': snackExpressions,
  'milestone': milestoneExpressions,
  'other_record': otherRecordExpressions,
};

/// ─── 페르소나 월령별 카테고리 가중치 ───
/// 월령에 따라 자주 쓰는 카테고리가 달라짐
Map<String, double> _getCategoryWeights(Persona p) {
  final m = p.babyMonths;
  final ft = p.feedingType;

  if (m <= 2) {
    // 신생아: 수유/수면/기저귀 위주, 이유식/간식 없음
    return {
      'feeding': 3.0,
      'sleep': 2.5,
      'diaper': 2.5,
      'health': 1.5,
      'babyfood': 0.0,
      'snack': 0.0,
      'milestone': 0.5,
      'other_record': 1.0,
    };
  } else if (m <= 5) {
    // 초기: 수유 위주, 이유식 시작 전후
    return {
      'feeding': 2.5,
      'sleep': 2.0,
      'diaper': 2.0,
      'health': 1.5,
      'babyfood': ft == 'babyfood' ? 1.5 : 0.3,
      'snack': 0.2,
      'milestone': 1.0,
      'other_record': 1.0,
    };
  } else if (m <= 9) {
    // 중기: 이유식 본격, 간식 시작
    return {
      'feeding': ft == 'babyfood' ? 1.5 : 2.0,
      'sleep': 1.5,
      'diaper': 1.5,
      'health': 1.5,
      'babyfood': 2.5,
      'snack': 1.5,
      'milestone': 1.0,
      'other_record': 1.0,
    };
  } else {
    // 후기: 이유식+간식 풍부, 성장 이벤트 많음
    return {
      'feeding': ft == 'babyfood' ? 1.0 : 1.5,
      'sleep': 1.5,
      'diaper': 1.5,
      'health': 1.5,
      'babyfood': 2.5,
      'snack': 2.0,
      'milestone': 1.5,
      'other_record': 1.0,
    };
  }
}

/// ─── 슬롯 치환 ───
String _fillSlots(String template, Random rng) {
  var result = template;

  if (result.contains('{amt}')) {
    // 수유량 또는 이유식량
    final amts = [...feedingAmounts, ...babyfoodAmounts];
    result = result.replaceAll('{amt}', amts[rng.nextInt(amts.length)]);
  }
  if (result.contains('{dur}')) {
    final durs = [...feedingDurations, ...sleepDurations];
    result = result.replaceAll('{dur}', durs[rng.nextInt(durs.length)]);
  }
  if (result.contains('{temp}')) {
    result = result.replaceAll('{temp}', temperatures[rng.nextInt(temperatures.length)]);
  }
  if (result.contains('{n}')) {
    result = result.replaceAll('{n}', counts[rng.nextInt(counts.length)]);
  }

  return result;
}

/// ─── 페르소나 속성에 따른 변형 적용 ───
String _applyPersonaStyle(String sentence, Persona p, Random rng) {
  var result = sentence;

  // 1) 시간 접두사 (verbosity 높을수록 시간 정보 추가 확률 ↑)
  final timeChance = p.verbosity / 4.0; // 0~0.75
  if (rng.nextDouble() < timeChance && !_hasTimePrefix(result)) {
    final prefix = timePrefixes[rng.nextInt(timePrefixes.length)];
    if (prefix.isNotEmpty) {
      result = '$prefix$result';
    }
  }

  // 2) 감정 접두사 (verbosity 2 이상)
  if (p.verbosity >= 2 && rng.nextDouble() < 0.25) {
    final emotion = emotionPrefixes[rng.nextInt(emotionPrefixes.length)];
    if (emotion.isNotEmpty) {
      result = '$emotion$result';
    }
  }

  // 3) 이모지 접미사
  if (rng.nextDouble() < p.emojiRate) {
    final emoji = emojiSuffixes[rng.nextInt(emojiSuffixes.length)];
    if (emoji.isNotEmpty) {
      result = '$result$emoji';
    }
  }

  // 4) 존댓말 변환 (formality 3)
  if (p.formality >= 3 && rng.nextDouble() < 0.7) {
    result = _applyPolite(result, rng);
  }

  // 5) 오타 적용
  if (rng.nextDouble() < p.typoRate) {
    result = _applyTypo(result, rng);
  }

  return result.trim();
}

/// 시간 접두사가 이미 있는지 확인
bool _hasTimePrefix(String s) {
  return RegExp(r'^(아침|점심|저녁|새벽|방금|아까|오전|오후|\d{1,2}시|\d+분 전)').hasMatch(s);
}

/// 존댓말 적용
String _applyPolite(String sentence, Random rng) {
  // 이미 존댓말이면 건너뜀
  if (sentence.endsWith('요') || sentence.endsWith('니다')) return sentence;

  // 끝말 패턴 치환
  final politeEndings = {
    '먹었어': '먹었어요',
    '줬어': '줬어요',
    '했어': '했어요',
    '갈았어': '갈았어요',
    '잤어': '잤어요',
    '깼어': '깼어요',
    '먹음': '먹었어요',
    '잠듬': '잠들었어요',
    '갈음': '갈았어요',
    '줌': '줬어요',
    '함': '했어요',
    '봤어': '봤어요',
    '먹였어': '먹였어요',
    '재웠어': '재웠어요',
    '시켰어': '시켰어요',
    '나왔어': '나왔어요',
    '나옴': '나왔어요',
    '완료': '완료했어요',
  };

  for (final entry in politeEndings.entries) {
    if (sentence.endsWith(entry.key)) {
      return sentence.substring(0, sentence.length - entry.key.length) + entry.value;
    }
  }

  // 매칭되지 않으면 "요" 추가
  if (!sentence.endsWith('요') && !sentence.endsWith('니다') && !sentence.endsWith('음')) {
    return '$sentence요';
  }
  return sentence;
}

/// 오타 적용
String _applyTypo(String sentence, Random rng) {
  var result = sentence;
  for (final entry in typoMap.entries) {
    if (result.contains(entry.key) && rng.nextDouble() < 0.5) {
      result = result.replaceFirst(entry.key, entry.value);
      break; // 오타는 한 번만
    }
  }
  return result;
}

/// ─── 가중치 기반 카테고리 선택 ───
String _pickCategory(Map<String, double> weights, Random rng) {
  final total = weights.values.fold(0.0, (a, b) => a + b);
  var r = rng.nextDouble() * total;
  for (final entry in weights.entries) {
    r -= entry.value;
    if (r <= 0) return entry.key;
  }
  return weights.keys.last;
}

/// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
///  메인 생성 함수
/// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/// [sentencesPerPersona] 페르소나당 생성할 문장 수 (기본 100)
/// [otherNonRecordRatio] other(비기록) 문장 비율 (기본 0.15)
/// [seed] 재현성을 위한 난수 시드
List<GeneratedTestCase> generateMassTestCases({
  int sentencesPerPersona = 100,
  double otherNonRecordRatio = 0.15,
  int seed = 42,
}) {
  final rng = Random(seed);
  final results = <GeneratedTestCase>[];

  for (final persona in allPersonas) {
    final weights = _getCategoryWeights(persona);
    final nonRecordCount = (sentencesPerPersona * otherNonRecordRatio).round();
    final recordCount = sentencesPerPersona - nonRecordCount;

    // ── 기록 문장 생성 ──
    for (var i = 0; i < recordCount; i++) {
      final category = _pickCategory(weights, rng);
      final expressions = _categoryExpressions[category];

      if (expressions == null || expressions.isEmpty) continue;

      // 표현 선택 + 슬롯 치환
      var sentence = expressions[rng.nextInt(expressions.length)];
      sentence = _fillSlots(sentence, rng);

      // 페르소나 스타일 적용
      sentence = _applyPersonaStyle(sentence, persona, rng);

      // other_record → expected는 'other'
      final expected = category == 'other_record' ? 'other' : category;

      results.add(GeneratedTestCase(
        input: sentence,
        expectedCategory: expected,
        personaId: persona.id,
        personaName: persona.name,
      ));
    }

    // ── 비기록(잡담/질문/의도) 문장 생성 ──
    for (var i = 0; i < nonRecordCount; i++) {
      var sentence = otherNonRecordExpressions[
          rng.nextInt(otherNonRecordExpressions.length)];

      // 이모지/존댓말 일부 적용
      if (rng.nextDouble() < persona.emojiRate * 0.3) {
        final emoji = emojiSuffixes[rng.nextInt(emojiSuffixes.length)];
        if (emoji.isNotEmpty) sentence = '$sentence$emoji';
      }

      results.add(GeneratedTestCase(
        input: sentence,
        expectedCategory: 'other',
        personaId: persona.id,
        personaName: persona.name,
      ));
    }
  }

  return results;
}

/// 통계 요약 생성
Map<String, dynamic> summarizeTestCases(List<GeneratedTestCase> cases) {
  final byPersona = <String, int>{};
  final byCategory = <String, int>{};

  for (final tc in cases) {
    byPersona[tc.personaId] = (byPersona[tc.personaId] ?? 0) + 1;
    byCategory[tc.expectedCategory] =
        (byCategory[tc.expectedCategory] ?? 0) + 1;
  }

  return {
    'totalCases': cases.length,
    'totalPersonas': byPersona.length,
    'byPersona': byPersona,
    'byCategory': byCategory,
  };
}
