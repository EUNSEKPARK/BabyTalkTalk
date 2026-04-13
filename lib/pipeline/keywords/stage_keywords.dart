import 'package:chat_baby_time/pipeline/growth_stage.dart';
import 'package:chat_baby_time/models/baby_record.dart';

/// 성장 단계별 키워드 관리
class StageKeywords {
  /// 성장 단계
  final GrowthStage stage;

  StageKeywords({required this.stage});

  /// 카테고리별 키워드 맵 반환
  Map<RecordCategory, Map<String, double>> getCategoryKeywords() {
    switch (stage) {
      case GrowthStage.formula:
        return _getFormulaStageKeywords();
      case GrowthStage.weaning:
        return _getWeaningStageKeywords();
      case GrowthStage.toddler:
        return _getToddlerStageKeywords();
    }
  }

  /// 분유기 (0~5개월) 키워드
  Map<RecordCategory, Map<String, double>> _getFormulaStageKeywords() {
    return {
      RecordCategory.feeding: {
        '분유': 3.0,
        '모유': 3.0,
        '수유': 3.0,
        '젖병': 2.5,
        '직수': 3.0,
        '유축': 3.0,
        '젖': 2.0,
        '먹었': 1.0,
        '먹임': 1.0,
        '먹였': 1.0,
        '먹음': 1.0,
        '먹어': 1.0,
        '마셨': 1.0,
        '마셔': 1.0,
      },
      RecordCategory.sleep: {
        '잠들': 3.0,
        '낮잠': 3.0,
        '밤잠': 3.0,
        '깼어': 2.5,
        '깸': 2.5,
        '재웠': 2.5,
        '잤어': 2.5,
        '잠듦': 2.5,
        '자': 2.0,
        '졸': 2.0,
        '잠': 1.5,
      },
      RecordCategory.diaper: {
        '기저귀': 3.0,
        '응가': 3.0,
        '대변': 3.0,
        '소변': 3.0,
        '똥': 2.5,
        '쌌어': 2.5,
        '쌌': 2.5,
        '갈아': 2.0,
        '교체': 2.0,
        '오줌': 2.0,
      },
      RecordCategory.health: {
        '체온': 3.0,
        '약': 2.0,
        '병원': 2.5,
        '예방접종': 3.0,
        '열': 2.0,
        '감기': 2.0,
        '재채기': 1.5,
        '기침': 1.5,
      },
      RecordCategory.babyfood: {}, // 비활성화
      RecordCategory.snack: {},    // 비활성화
      RecordCategory.milestone: {},
      RecordCategory.other: {},
    };
  }

  /// 이유식기 (5~15개월) 키워드
  Map<RecordCategory, Map<String, double>> _getWeaningStageKeywords() {
    return {
      RecordCategory.feeding: {
        '분유': 3.0,
        '모유': 3.0,
        '수유': 3.0,
        '젖병': 2.5,
        '직수': 3.0,
        '유축': 3.0,
        '젖': 2.0,
        '먹었': 1.0,
        '먹임': 1.0,
        '먹였': 1.0,
        '먹음': 1.0,
        '먹어': 1.0,
        '마셨': 1.0,
      },
      RecordCategory.babyfood: {
        '이유식': 3.0,
        '죽': 2.5,
        '미음': 2.5,
        '퓨레': 2.5,
        '밥': 2.0, // 이유식기에서는 밥=이유식
        '한입': 2.0,
        '스푼': 2.0,
        // 재료 키워드
        '소고기': 2.5,
        '닭고기': 2.5,
        '생선': 2.5,
        '계란': 2.5,
        '달걀': 2.5,
        '감자': 2.0,
        '고구마': 2.0,
        '브로콜리': 2.0,
        '당근': 2.0,
        '옥수수': 2.0,
        '시금치': 2.0,
        '포도': 2.0,
        '딸기': 2.0,
        '바나나': 2.0,
        '사과': 2.0,
      },
      RecordCategory.snack: {
        '간식': 3.0,
        '과일': 2.5,
        '뻥튀기': 2.5,
        '떡뻥': 2.5,
        '요거트': 2.5,
        '치즈': 2.0,
        '요구르트': 2.5,
        '쿠키': 2.0,
        '크래커': 2.0,
      },
      RecordCategory.sleep: {
        '잠들': 3.0,
        '낮잠': 3.0,
        '밤잠': 3.0,
        '깼어': 2.5,
        '깸': 2.5,
        '재웠': 2.5,
        '잤어': 2.5,
        '잠듦': 2.5,
      },
      RecordCategory.diaper: {
        '기저귀': 3.0,
        '응가': 3.0,
        '대변': 3.0,
        '소변': 3.0,
        '똥': 2.5,
        '쌌어': 2.5,
      },
      RecordCategory.health: {
        '체온': 3.0,
        '약': 2.0,
        '병원': 2.5,
        '예방접종': 3.0,
        '열': 2.0,
      },
      RecordCategory.milestone: {},
      RecordCategory.other: {},
    };
  }

  /// 유아식기 (15개월~) 키워드
  Map<RecordCategory, Map<String, double>> _getToddlerStageKeywords() {
    return {
      RecordCategory.feeding: {
        // 분유/모유 (가중치 감소하되 유지)
        '분유': 1.5,
        '모유': 1.5,
        '수유': 1.5,
        '젖병': 1.5,
        // 유아식 메뉴 키워드 (통합)
        '밥': 3.0,
        '메뉴': 2.5,
        '반찬': 2.5,
        '국': 2.0,
        '카레': 2.5,
        '국수': 2.5,
        '우동': 2.5,
        '파스타': 2.5,
        '볶음밥': 2.5,
        '김밥': 2.5,
        '스파게티': 2.5,
        '먹었': 1.0,
        '먹임': 1.0,
        '먹였': 1.0,
        '먹음': 1.0,
        '먹어': 1.0,
        '마셨': 1.0,
      },
      RecordCategory.snack: {
        '간식': 3.0,
        '과일': 2.5,
        '과자': 2.0,
        '빵': 2.0,
        '우유': 2.5,
        '요거트': 2.5,
        '치즈': 2.0,
        '요구르트': 2.5,
        '초콜릿': 1.5,
        '사탕': 1.5,
      },
      RecordCategory.babyfood: {
        // 유아식기에서는 MEAL로 분류되므로 babyfood는 최소화
        '이유식': 1.0,
        '죽': 1.0,
      },
      RecordCategory.sleep: {
        '잠들': 3.0,
        '낮잠': 3.0,
        '밤잠': 3.0,
        '깼어': 2.5,
        '깸': 2.5,
        '재웠': 2.5,
        '잤어': 2.5,
      },
      RecordCategory.diaper: {
        '기저귀': 3.0,
        '응가': 3.0,
        '대변': 3.0,
        '소변': 3.0,
        '똥': 2.5,
      },
      RecordCategory.health: {
        '체온': 3.0,
        '약': 2.0,
        '병원': 2.5,
        '예방접종': 3.0,
        '열': 2.0,
      },
      RecordCategory.milestone: {},
      RecordCategory.other: {},
    };
  }

  /// 공통 정규표현식 패턴 (모든 단계)
  ///
  /// 주의: 동일 패턴이 여러 카테고리에 존재하면 양쪽에 점수가 가산되어
  /// 불필요한 disambiguation을 유발하므로, 카테고리별로 차별화된 패턴 사용
  static final Map<RecordCategory, List<RegexPattern>> commonRegexPatterns = {
    RecordCategory.feeding: [
      RegexPattern(pattern: r'\d+\s*(ml|cc)', weight: 3.0),
      RegexPattern(pattern: r'젖\s*(먹|물)', weight: 2.5),
      // "N분 수유", "N분 먹" 등 수유 컨텍스트의 시간만 매치
      RegexPattern(pattern: r'\d+분\s*(수유|먹|동안\s*먹)', weight: 2.0),
    ],
    RecordCategory.sleep: [
      RegexPattern(pattern: r'깨\s*(어|었|서|고|남)', weight: 2.5),
      RegexPattern(pattern: r'잠\s*(들|잤|잘)', weight: 3.0),
      RegexPattern(pattern: r'\d+시간\s*(잤|잠|자)', weight: 2.5),
      // "N분 잤", "N분 잠" 등 수면 컨텍스트의 시간만 매치
      RegexPattern(pattern: r'\d+분\s*(잤|잠|자|깼)', weight: 2.0),
    ],
    RecordCategory.diaper: [
      RegexPattern(pattern: r'똥\s*(쌌|싸|나)', weight: 3.0),
      RegexPattern(pattern: r'기저귀\s*(갈|교)', weight: 2.0),
    ],
    RecordCategory.health: [
      RegexPattern(pattern: r'\d{2}\.?\d?\s*(도|°|℃)', weight: 3.0),
      RegexPattern(pattern: r'열\s*(이|나|있)', weight: 3.0),
    ],
    RecordCategory.babyfood: [
      RegexPattern(pattern: r'\d+\s*(ml|cc|스푼|숟가락)', weight: 2.5),
    ],
    RecordCategory.snack: [
      RegexPattern(pattern: r'\d+\s*개', weight: 2.0),
    ],
  };

  /// 단계별 활성화된 카테고리 조회
  List<RecordCategory> getEnabledCategories() {
    switch (stage) {
      case GrowthStage.formula:
        return [
          RecordCategory.feeding,
          RecordCategory.sleep,
          RecordCategory.diaper,
          RecordCategory.health,
          RecordCategory.milestone,
          RecordCategory.other,
        ];
      case GrowthStage.weaning:
        return [
          RecordCategory.feeding,
          RecordCategory.babyfood,
          RecordCategory.snack,
          RecordCategory.sleep,
          RecordCategory.diaper,
          RecordCategory.health,
          RecordCategory.milestone,
          RecordCategory.other,
        ];
      case GrowthStage.toddler:
        return [
          RecordCategory.feeding,
          RecordCategory.babyfood, // MEAL로 사용
          RecordCategory.snack,
          RecordCategory.sleep,
          RecordCategory.diaper,
          RecordCategory.health,
          RecordCategory.milestone,
          RecordCategory.other,
        ];
    }
  }
}

/// 정규표현식 패턴 정보
class RegexPattern {
  final String pattern;
  final double weight;

  RegexPattern({
    required this.pattern,
    required this.weight,
  });

  /// 패턴이 주어진 텍스트와 매치되는지 확인
  bool matches(String text) {
    try {
      return RegExp(pattern).hasMatch(text);
    } catch (e) {
      return false;
    }
  }

  /// 패턴으로 일치 항목 추출
  List<String> extract(String text) {
    try {
      final regex = RegExp(pattern);
      return regex.allMatches(text).map((m) => m.group(0) ?? '').toList();
    } catch (e) {
      return [];
    }
  }
}
