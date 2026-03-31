/// 문장 완성도
enum SentenceCompleteness {
  complete,  // 완전한 문장 (동사+목적어+수량)
  partial,   // 부분적 문장 (동사+목적어 또는 일부 정보 누락)
  fragment,  // 단편적 (동사 없음, 명사만 있거나 불완전)
  noise,     // 노이즈 (의미 없는 입력)
}

/// 문장 개수
enum SentenceCount {
  single, // 단일 문장
  multi,  // 다중 문장
}

/// 문장 분석 결과
class SentenceAnalysisResult {
  /// 문장 개수 (단일/다중)
  final SentenceCount count;

  /// 문장 완성도 (완전/부분/단편/노이즈)
  final SentenceCompleteness completeness;

  /// 분할된 세그먼트 (다중 문장 시 각 문장)
  final List<String> segments;

  /// 누락된 필드 목록 (예: ['amount', 'duration'])
  final List<String> missingFields;

  /// 감지된 주체 (예: '나', '엄마', '아빠', null=불명확)
  final String? detectedSubject;

  /// 감지된 동사 목록
  final List<String> detectedVerbs;

  /// 감지된 객체 목록
  final List<String> detectedObjects;

  /// 감지된 수량/시간 정보 목록
  final List<String> detectedQuantities;

  /// 의도 표현 여부 (해야, 먹을래 등)
  final bool isIntentExpression;

  /// 시간 관련 키워드 감지 여부
  final bool hasTimeMarker;

  SentenceAnalysisResult({
    required this.count,
    required this.completeness,
    required this.segments,
    List<String>? missingFields,
    this.detectedSubject,
    List<String>? detectedVerbs,
    List<String>? detectedObjects,
    List<String>? detectedQuantities,
    this.isIntentExpression = false,
    this.hasTimeMarker = false,
  })  : missingFields = missingFields ?? [],
        detectedVerbs = detectedVerbs ?? [],
        detectedObjects = detectedObjects ?? [],
        detectedQuantities = detectedQuantities ?? [];

  /// 문장이 완전한지 확인
  bool get isComplete => completeness == SentenceCompleteness.complete;

  /// 다중 문장인지 확인
  bool get isMultiSentence => count == SentenceCount.multi;

  /// 신뢰도 계산 (0.0 ~ 1.0)
  double get confidence {
    if (completeness == SentenceCompleteness.noise) return 0.0;
    if (completeness == SentenceCompleteness.complete) return 1.0;
    if (completeness == SentenceCompleteness.partial) return 0.7;
    return 0.4; // fragment
  }

  /// 결과 요약
  @override
  String toString() {
    return 'SentenceAnalysisResult('
        'count: $count, '
        'completeness: $completeness, '
        'segments: ${segments.length}, '
        'missingFields: $missingFields, '
        'subject: $detectedSubject'
        ')';
  }
}
