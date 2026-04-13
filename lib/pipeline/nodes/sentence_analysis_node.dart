import 'package:chat_baby_time/pipeline/models/node_result.dart';
import 'package:chat_baby_time/pipeline/models/sentence_analysis_result.dart';

/// 문장 분석 노드
/// - 단일/다중 문장 판단
/// - 완성도 분석 (완전/부분/단편/노이즈)
/// - 주체 감지
/// - 동사/객체/수량 추출
class SentenceAnalysisNode {
  static const String nodeId = 'sentence_analysis';
  static const String nodeName = '문장 분석';

  /// 다중 문장 구분자
  static const List<String> multiSentenceSplitters = [
    '하고',
    '그리고',
    '먹고',
    '먹었고',
    '자고',
    '잤고',
    '갈아',
    '갈았고',
    '가지고',
    '갔고',
    '있고',
    '있었고',
  ];

  /// 시간 마커 (다중 문장 구분 시 사용)
  static final RegExp timeMarkerRegex = RegExp(
    r'(오전|오후|아침|낮|저녁|밤|방금|아까|지금|이따|내일|어제|어제|다음|전)',
  );

  /// 자기참조 키워드
  static const List<String> selfReferences = [
    '나',
    '나는',
    '내가',
    '저는',
    '저희가',
  ];

  /// 타인참조 키워드
  static final Map<String, String> otherReferences = {
    '남편': 'husband',
    '아빠': 'father',
    '엄마': 'mother',
    '할머니': 'grandmother',
    '할아버지': 'grandfather',
  };

  /// 동사 목록 (완성도 판단용)
  static const List<String> verbs = [
    '먹었',
    '먹어',
    '먹임',
    '마셨',
    '마셔',
    '잤',
    '잠들',
    '깼',
    '깨',
    '갈았',
    '갈아',
    '쌌',
    '싸',
    '했',
    '해',
    '있었',
    '있어',
  ];

  /// 의도 표현 키워드 (의도 vs 사실 판분)
  static const List<String> intentExpressions = [
    '해야',
    '먹을래',
    '먹여야',
    '먹여야지',
    '자야',
    '자야지',
    '갈아야',
    '갈아야지',
    '줘야',
    '줄래',
    '할거',
    '할거야',
    '할거에요',
  ];

  /// 문장 분석 실행
  static NodeResult<SentenceAnalysisResult> run(String normalizedText) {
    try {
      // 1. 다중 문장 분석
      final segments = _splitMultipleSentences(normalizedText);
      final count = segments.length > 1
          ? SentenceCount.multi
          : SentenceCount.single;

      // 2. 완성도 분석 (첫 번째 세그먼트 기준)
      final primarySegment = segments.first;
      final completeness = _analyzeCompleteness(primarySegment);

      // 3. 주체 감지
      final subject = _detectSubject(primarySegment);

      // 4. 동사 감지
      final detectedVerbs = _detectVerbs(primarySegment);

      // 5. 객체 감지
      final detectedObjects = _detectObjects(primarySegment);

      // 6. 수량/시간 감지
      final detectedQuantities = _detectQuantities(primarySegment);

      // 7. 의도 표현 확인
      final isIntent = _isIntentExpression(primarySegment);

      // 8. 시간 마커 확인
      final hasTimeMarker = timeMarkerRegex.hasMatch(primarySegment);

      // 9. 누락된 필드 판단
      final missingFields = _detectMissingFields(
        completeness,
        detectedVerbs,
        detectedObjects,
        detectedQuantities,
      );

      final result = SentenceAnalysisResult(
        count: count,
        completeness: completeness,
        segments: segments,
        missingFields: missingFields,
        detectedSubject: subject,
        detectedVerbs: detectedVerbs,
        detectedObjects: detectedObjects,
        detectedQuantities: detectedQuantities,
        isIntentExpression: isIntent,
        hasTimeMarker: hasTimeMarker,
      );

      return NodeResult.success(
        data: result,
        debugInfo: {
          'segmentCount': segments.length,
          'completeness': completeness.toString(),
          'subject': subject,
          'verbs': detectedVerbs.length,
          'objects': detectedObjects.length,
          'quantities': detectedQuantities.length,
          'isIntent': isIntent,
        },
      );
    } catch (e) {
      return NodeResult.failure(
        error: '문장 분석 실패: ${e.toString()}',
        debugInfo: {'error': e.toString()},
      );
    }
  }

  /// 다중 문장 분할
  ///
  /// 분할 조건: 시간 마커가 2개 이상 존재하거나, 연결 동사 + 시간 마커가
  /// 동반될 때만 분할. "분유 먹고 잤어"처럼 시간 마커 없이 연결 동사만
  /// 있는 경우는 단일 문장으로 처리.
  static List<String> _splitMultipleSentences(String text) {
    // 시간 마커가 2개 이상 있는지 확인 (다중 이벤트의 강한 신호)
    final timeMatches = timeMarkerRegex.allMatches(text).toList();
    final hasMultipleTimeMarkers = timeMatches.length >= 2;

    // 시간 마커가 2개 미만이면 분할하지 않음
    // "분유 먹고 잤어" → 분할 안 함 (단일 연속 이벤트)
    if (!hasMultipleTimeMarkers) {
      return [text];
    }

    // 시간 마커 기반 분할 (2개 이상의 시간 마커가 있을 때)
    // 예: "5시에 분유 먹고 6시에 잤어" → ["5시에 분유 먹고", "6시에 잤어"]
    final segments = <String>[];
    final timePositions = <int>[];

    for (final match in timeMatches) {
      timePositions.add(match.start);
    }

    for (int i = 0; i < timePositions.length; i++) {
      final start = timePositions[i];
      final end = i + 1 < timePositions.length
          ? timePositions[i + 1]
          : text.length;
      final segment = text.substring(start, end).trim();

      // 연결 동사로 끝나는 경우 제거 (먹고, 하고, 그리고 등)
      final cleaned = segment.replaceAll(
        RegExp(r'\s*(하고|그리고|먹고|먹었고|자고|잤고|갈아|갈았고)\s*$'),
        '',
      ).trim();

      if (cleaned.isNotEmpty) {
        segments.add(cleaned);
      }
    }

    return segments.isEmpty ? [text] : segments;
  }

  /// 문장 완성도 분석
  static SentenceCompleteness _analyzeCompleteness(String text) {
    if (text.isEmpty) return SentenceCompleteness.noise;

    // 노이즈 확인 (한 글자, 의미 없는 표현)
    if (text.length < 2) return SentenceCompleteness.noise;
    if (['아', '음', '어', '흠', '아하', '응', '뭐'].contains(text)) {
      return SentenceCompleteness.noise;
    }

    // 동사 확인
    final hasVerb = verbs.any((v) => text.contains(v));
    if (!hasVerb) return SentenceCompleteness.fragment;

    // 객체 확인
    final objectKeywords = ['먹', '분유', '모유', '젖', '잠', '기저귀', '열', '약'];
    final hasObject = objectKeywords.any((obj) => text.contains(obj));
    if (!hasObject) return SentenceCompleteness.partial;

    // 수량/시간 정보 확인
    final hasQuantity =
        RegExp(r'\d+').hasMatch(text) || text.contains('분') || text.contains('시간');
    if (!hasQuantity && text.contains('먹')) {
      return SentenceCompleteness.partial;
    }

    return SentenceCompleteness.complete;
  }

  /// 주체 감지
  static String? _detectSubject(String text) {
    // 자기참조
    for (final ref in selfReferences) {
      if (text.contains(ref)) return '자신(self)';
    }

    // 타인참조
    for (final entry in otherReferences.entries) {
      if (text.contains(entry.key)) return entry.value;
    }

    // 기본값: 아기(baby)
    return 'baby';
  }

  /// 동사 감지
  static List<String> _detectVerbs(String text) {
    return verbs.where((v) => text.contains(v)).toList();
  }

  /// 객체 감지
  static List<String> _detectObjects(String text) {
    final objects = <String>[];
    const objectKeywords = [
      '분유',
      '모유',
      '젖',
      '이유식',
      '간식',
      '밥',
      '죽',
      '잠',
      '기저귀',
      '소변',
      '대변',
      '열',
      '약',
      '예방접종',
    ];

    for (final obj in objectKeywords) {
      if (text.contains(obj)) objects.add(obj);
    }

    return objects;
  }

  /// 수량/시간 감지
  static List<String> _detectQuantities(String text) {
    final quantities = <String>[];

    // 숫자 + 단위
    final patterns = [
      RegExp(r'\d+\s*(ml|cc)'),
      RegExp(r'\d+\s*(분|시간)'),
      RegExp(r'\d+\s*개'),
      RegExp(r'\d+\s*도'),
      RegExp(r'\d+\s*숟가락'),
      RegExp(r'\d+\s*스푼'),
    ];

    for (final pattern in patterns) {
      final matches = pattern.allMatches(text);
      quantities.addAll(matches.map((m) => m.group(0) ?? ''));
    }

    return quantities;
  }

  /// 의도 표현 확인
  static bool _isIntentExpression(String text) {
    return intentExpressions.any((expr) => text.contains(expr));
  }

  /// 누락된 필드 감지
  static List<String> _detectMissingFields(
    SentenceCompleteness completeness,
    List<String> verbs,
    List<String> objects,
    List<String> quantities,
  ) {
    final missing = <String>[];

    if (verbs.isEmpty) missing.add('verb');
    if (objects.isEmpty) missing.add('object');
    if (quantities.isEmpty && objects.any((o) => o.contains('먹'))) {
      missing.add('quantity');
    }

    return missing;
  }
}
