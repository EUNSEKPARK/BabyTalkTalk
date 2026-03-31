import 'package:chat_baby_time/models/baby_record.dart';
import 'package:chat_baby_time/pipeline/growth_stage.dart';
import 'package:chat_baby_time/pipeline/keywords/stage_keywords.dart';
import 'package:chat_baby_time/pipeline/models/node_result.dart';
import 'package:chat_baby_time/pipeline/models/sentence_analysis_result.dart';

/// 입력 타입 분류 노드
/// - 키워드 기반 카테고리 점수 계산
/// - 신뢰도 판단
/// - 명확화 필요 여부 판단
class TypeClassificationNode {
  static const String nodeId = 'type_classification';
  static const String nodeName = '타입 분류';

  /// 자기참조 페널티 (0.3x 곱하기)
  static const double selfReferencePenalty = 0.3;

  /// 의도 표현 필터 키워드
  static const List<String> intentFilterKeywords = [
    '해야',
    '먹을래',
    '먹여야',
    '자야',
    '갈아야',
  ];

  /// 분류 결과
  static NodeResult<ClassificationResult> run({
    required String normalizedText,
    required SentenceAnalysisResult sentenceAnalysis,
    required GrowthStage growthStage,
  }) {
    try {
      // 1. 의도 표현 필터링
      if (sentenceAnalysis.isIntentExpression) {
        final result = ClassificationResult(
          category: RecordCategory.other,
          confidence: 0.1,
          scores: {},
          reason: '의도 표현으로 감지됨 (실제 기록 아님)',
        );
        return NodeResult.success(
          data: result,
          debugInfo: {
            'filtered': true,
            'reason': 'intent_expression',
          },
        );
      }

      // 2. 키워드 매칭 점수 계산
      final stageKeywords = StageKeywords(stage: growthStage);
      final categoryKeywords = stageKeywords.getCategoryKeywords();

      final scores = <RecordCategory, double>{};

      for (final category in stageKeywords.getEnabledCategories()) {
        var score = _calculateCategoryScore(
          normalizedText,
          category,
          categoryKeywords[category] ?? {},
          sentenceAnalysis.detectedSubject,
        );

        // 정규표현식 패턴 매칭 추가
        if (StageKeywords.commonRegexPatterns.containsKey(category)) {
          for (final pattern in StageKeywords.commonRegexPatterns[category]!) {
            if (pattern.matches(normalizedText)) {
              score += pattern.weight;
            }
          }
        }

        scores[category] = score;
      }

      // 3. 최고 점수 카테고리 선택
      if (scores.isEmpty) {
        return NodeResult.failure(
          error: '분류 가능한 카테고리 없음',
          suggestion: '다시 입력해주세요.',
        );
      }

      final sortedScores = scores.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

      final topCategory = sortedScores[0].key;
      final topScore = sortedScores[0].value;

      // 4. 신뢰도 계산
      final confidence = _calculateConfidence(topScore, scores);

      // 5. 명확화 필요 여부 판단
      bool needsDisambiguation = false;
      RecordCategory? secondaryCategory;

      if (sortedScores.length > 1) {
        final secondScore = sortedScores[1].value;
        if ((topScore - secondScore) / topScore < 0.3) {
          // 상위 2개 점수가 유사하면 명확화 필요
          needsDisambiguation = true;
          secondaryCategory = sortedScores[1].key;
        }
      }

      final result = ClassificationResult(
        category: topCategory,
        confidence: confidence,
        scores: scores,
        reason: '키워드 매칭',
        secondaryCategory: secondaryCategory,
        needsDisambiguation: needsDisambiguation,
      );

      return NodeResult.success(
        data: result,
        debugInfo: {
          'topScore': topScore.toStringAsFixed(2),
          'confidence': confidence.toStringAsFixed(2),
          'topCategories': [
            topCategory.toString(),
            if (secondaryCategory != null) secondaryCategory.toString(),
          ],
          'needsDisambiguation': needsDisambiguation,
        },
      );
    } catch (e) {
      return NodeResult.failure(
        error: '분류 실패: ${e.toString()}',
        debugInfo: {'error': e.toString()},
      );
    }
  }

  /// 카테고리 점수 계산
  static double _calculateCategoryScore(
    String text,
    RecordCategory category,
    Map<String, double> keywords,
    String? detectedSubject,
  ) {
    double score = 0.0;

    for (final entry in keywords.entries) {
      final keyword = entry.key;
      final weight = entry.value;

      if (text.contains(keyword)) {
        score += weight;
      }
    }

    // 자기참조 페널티 적용 (타인이 먹인 경우 신뢰도 감소)
    if (detectedSubject != null && detectedSubject != 'baby' && detectedSubject != 'self') {
      score *= selfReferencePenalty;
    }

    return score;
  }

  /// 신뢰도 계산 (0.0 ~ 1.0)
  static double _calculateConfidence(
    double topScore,
    Map<RecordCategory, double> allScores,
  ) {
    // 점수가 높을수록 신뢰도 증가
    // 점수 범위: 0 ~ 15 (대략)
    // 신뢰도 범위: 0.0 ~ 1.0

    if (topScore == 0.0) return 0.0;

    // 0-3: 0.3-0.4, 3-6: 0.4-0.6, 6-9: 0.6-0.8, 9+: 0.8-1.0
    final confidence = (topScore / 12.0).clamp(0.0, 1.0);
    return confidence;
  }
}

/// 분류 결과
class ClassificationResult {
  /// 분류된 카테고리
  final RecordCategory category;

  /// 신뢰도 (0.0 ~ 1.0)
  final double confidence;

  /// 모든 카테고리 점수
  final Map<RecordCategory, double> scores;

  /// 분류 이유
  final String reason;

  /// 보조 카테고리 (명확화 필요 시)
  final RecordCategory? secondaryCategory;

  /// 명확화 필요 여부
  final bool needsDisambiguation;

  ClassificationResult({
    required this.category,
    required this.confidence,
    required this.scores,
    required this.reason,
    this.secondaryCategory,
    this.needsDisambiguation = false,
  });

  /// 카테고리별 점수 조회
  double getScore(RecordCategory category) {
    return scores[category] ?? 0.0;
  }

  /// 상위 N개 카테고리 조회
  List<RecordCategory> getTopCategories(int n) {
    final sorted = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(n).map((e) => e.key).toList();
  }

  @override
  String toString() {
    return 'ClassificationResult('
        'category: $category, '
        'confidence: ${confidence.toStringAsFixed(2)}, '
        'secondary: $secondaryCategory'
        ')';
  }
}
